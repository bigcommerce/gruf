# gruf - gRPC Ruby Framework

[![Build Status](https://travis-ci.org/bigcommerce/gruf.svg?branch=master)](https://travis-ci.org/bigcommerce/gruf) [![Gem Version](https://badge.fury.io/rb/gruf.svg)](https://badge.fury.io/rb/gruf) [![Documentation](https://inch-ci.org/github/bigcommerce/gruf.svg?branch=master)](https://inch-ci.org/github/bigcommerce/gruf?branch=master)

gruf is a Ruby framework that wraps the [gRPC Ruby library](https://github.com/grpc/grpc/tree/master/src/ruby) to
provide a more streamlined integration into Ruby and Ruby on Rails applications.

It provides an abstracted server and client for gRPC services, along with other tools to help get gRPC services in Ruby
up fast and efficiently at scale. Some of its features include:

* Abstracted server endpoints with before, around, outer around, and after hooks during an endpoint call
* Robust client error handling and metadata transport abilities
* Server authentication strategy support, with basic auth with multiple key support built in
* TLS support for client-server auth, though we recommend using [linkerd](https://linkerd.io/) instead
* Error data serialization in output metadata to allow fine-grained error handling in the transport while still 
preserving gRPC BadStatus codes
* Server and client execution timings in responses

gruf currently has active support for gRPC 1.4.x. gruf is compatible and tested with with Ruby 2.2, 2.3, and 2.4. gruf 
is also not [Rails](https://github.com/rails/rails)-specific, and can be used in any Ruby framework (such as 
[Grape](https://github.com/ruby-grape/grape), for instance).

## Installation

```ruby
gem 'gruf'
```

Then in an initializer or before use:

```ruby
require 'gruf'
```

Make sure to review [UPGRADING.md](https://github.com/bigcommerce/gruf/blob/master/UPGRADING.md) 
if you are upgrading gruf between minor or major versions.

### Client

From there, you can instantiate a client given a stub service (say on an SslCertificates proto with a GetSslCertificate call):

```ruby
require 'gruf'

id = args[:id].to_i.presence || 1

begin
  client = ::Gruf::Client.new(service: ::Demo::ThingService)
  response = client.call(:GetMyThing, id: id)
  puts response.message.inspect
rescue Gruf::Client::Error => e
  puts e.error.inspect
end
```

Note this returns a response object. The response object can provide `trailing_metadata` as well as a `execution_time`.

### Server

Add an initializer:

```ruby
require 'gruf'

Gruf.configure do |c|
  c.server_binding_url = 'grpc.service.com:9003'
end
```

Next, setup some handlers based on your proto configurations in `/app/rpc/`. For example, for the Thing service, with a 
GetThingReq/GetThingResp call based on this proto:

```
syntax = "proto3";

package demo;

service Jobs {
    rpc GetJob(GetJobReq) returns (GetJobResp) { }
}

message GetJobReq {
    uint64 id = 1;
}

message GetJobResp {
    uint64 id = 1;
    string name = 2;
}
```

You'd have this handler in `/app/rpc/demo/job_server.rb`

```ruby
module Demo
  class JobServer < ::Demo::Jobs::Service
    include Gruf::Service
  
    ##
    # @param [Demo::GetJobReq] req The incoming gRPC request object
    # @param [GRPC::ActiveCall] call The gRPC active call instance
    # @return [Demo::GetJobResp] The job response
    #
    def get_job(req, call)
      thing = Job.find(req.id)
      
      Demo::GetJobResp.new(
        id: thing.id
      )
    rescue
      fail!(req, call, :not_found, :job_not_found, "Failed to find Job with ID: #{req.id}")
    end
  end
end
```

Finally, you can start the server by running:

    bundle exec gruf

### Authentication

Authentication is done via a strategy pattern and are injectable via middleware. If any of the strategies return `true`,
it will proceed the request as successful. For example, to add basic auth, you can do:

```ruby
Gruf::Authentication::Strategies.add(:basic, Gruf::Authentication::Basic)
```

Options to the middleware libraries can be passed through the `authentication_options` configuration option.

To add a custom authentication pattern, your class must extend the `Gruf::Authentication::Base` class, and implement
the `valid?(call)` method. For example, this class allows everyone in:

```
class NoAuth < Gruf::Authentication::Base
  def valid?(_call)
    true
  end
end
```

#### Basic Auth

gruf supports simple basic authentication with an array of accepted credentials:

```ruby
Gruf.configure do |c|  
  c.authentication_options = {
    credentials: [{
      username: 'my-username-here',
      password: 'my-password-here',    
    },{
      username: 'another-username',
      password: 'another-password',    
    },{
      password: 'a-password-only'
    }]
  }
end
```

Supporting an array of credentials allow for unique credentials per service, or for easy credential rotation with
zero downtime.

### SSL Configuration

We don't recommend using TLS for gRPC, but instead using something like [linkerd](https://linkerd.io) for TLS
encryption between services. If you need it, however, this library supports TLS.

For the client, you'll need to point to the public certificate:

```ruby
::Gruf::Client.new(
  service: Demo::ThingService,
  ssl_certificate: 'x509 public certificate here',
  # OR
  ssl_certificate_file: '/path/to/my.crt' 
)
```

If you want to run a server you'll need both the CRT and the key file if you want to do credentialed auth:

```ruby
Gruf.configure do |c|
  c.use_ssl = true
  c.ssl_crt_file = "#{Rails.root}/config/ssl/#{Rails.env}.crt"
  c.ssl_key_file = "#{Rails.root}/config/ssl/#{Rails.env}.key"
end
```

## Hooks

gruf supports hooks that act as interceptors around the grpc server calls, allowing you to perform actions before, 
after, and even around your server endpoints. This can be used to add tracing data, connection resets in the grpc thread 
pool, further instrumentation, and other things.

Adding a hook is as simple as creating a class that extends `Gruf::Hooks::Base`, and implementing it via the registry.

### Before

A before hook passes in the method call signature, request object, and `GRPC::ActiveCall` object:
```ruby
class MyBeforeHook < Gruf::Hooks::Base
  def before(call_signature, request, active_call)
    # do my thing before the call. Calling `fail!` here will prevent the call from happening.
  end
end
Gruf::Hooks::Registry.add(:my_before_hook, MyBeforeHook)
```

### After

An after hook passes in the response object, method call signature, request object, and `GRPC::ActiveCall` object:
```ruby
class MyAfterHook < Gruf::Hooks::Base
  def after(success, response, call_signature, request, active_call)
    # You can modify the response object
  end
end
Gruf::Hooks::Registry.add(:my_after_hook, MyAfterHook)
```

### Around

An around hook passes in the method call signature, request object, `GRPC::ActiveCall` object, and the block 
being executed:
```ruby
class MyAroundHook < Gruf::Hooks::Base
  def around(call_signature, request, active_call, &block)
    # do my thing here 
    resp = yield
    # do my thing there
    resp
  end
end
Gruf::Hooks::Registry.add(:my_around_hook, MyAroundHook)
```

Around hooks are a special case - because each needs to wrap the call, they are run recursively within each other.
This means that if you have three hooks - `Hook1`, `Hook2`, and `Hook3` - they will run in LIFO (last in, first out) 
order. `Hook3` will run, calling `Hook2`, which will then call `Hook1`, ending the chain.  

### Outer Around

And finally, an "outer" around hook passes in the method call signature, request object, `GRPC::ActiveCall` 
object, and the block being executed, and executes around the _entire_ call chain (before, around, request, after):

```ruby
class MyOuterAroundHook < Gruf::Hooks::Base
  def outer_around(call_signature, request, active_call, &block)
    # do my thing here 
    resp = yield
    # do my thing there
    resp
  end
end
Gruf::Hooks::Registry.add(:my_outer_around_hook, MyOuterAroundHook)
```

Outer around hooks behave similarly in execution order to around hooks.

Note: It's important to note that the authentication step happens immediately before the first _before_ hook is called,
so don't perform any actions that you want behind authentication in outer around hooks, as they are not called with
authentication.

## Instrumentation

gruf comes out of the box with a couple of instrumentors packed in: output metadata timings, and StatsD
support. 

### Output Metadata Timing

Enabled by default, this will push timings for _successful responses_ through the response output metadata back to the 
client.

### StatsD

The StatsD support is not enabled by default. To enable it, you'll want to do:

```ruby
Gruf.configure do |c|
  c.instrumentation_options[:statsd] = {
    client: ::Statsd.new('my.statsd.host', 8125),
    prefix: 'my_application_prefix.rpc'
  }
end
Gruf::Instrumentation::Registry.add(:statsd, Gruf::Instrumentation::Statsd)
```

This will measure counts and timings for each endpoint. Note: instrumentation hooks happen in LIFO order; they also
run similarly to an outer_around hook, executing _before_ authorization happens. Note: It's important that in your 
instrumentors, you pass-through exceptions (such as `GRPC::BadStatus`); catching them in instrumentors will cause errors 
upstream.

### Request Logging

Gruf 1.2+ comes built with request logging out of the box; you'll get Rails-style logs with your gRPC calls:

```
# plain
I, [2017-07-14T09:50:54.200506 #70571]  INFO -- : [GRPC::Ok] (thing_service.get_thing) [0.348ms]
# logstash
I, [2017-07-14T09:51:03.299050 #70595]  INFO -- : {"message":"[GRPC::Ok] (thing_service.get_thing) [0.372ms]","service":"thing_service","method":"thing_service.get_thing","grpc_status":"GRPC::Ok"}
 ```

It supports formatters (including custom ones) that you can use to specify the formatting of the logging:
 
```ruby
Gruf.configure do |c|
  c.instrumentation_options[:request_logging] = {
    formatter: :logstash
  }
end
```

It comes with a few more options as well:

| Option | Description | Default |
| ------ | ----------- | ------- |
| formatter | The formatter to use. By default `:plain` and `:logstash` are supported. | `:plain` |
| log_parameters | If set to true, will log parameters in the response | `false` |
| blacklist | An array of parameter key names to redact from logging, in path.to.key format | `[]` |
| redacted_string | The string to use for redacted parameters. | `REDACTED` |

It's important to maintain a safe blacklist should you decide to log parameters; gruf does no 
parameter sanitization on its own. We also recommend blacklisting parameters that may contain 
very large values (such as binary or json data).

### Custom Instrumentors

Similar to hooks, simply extend the `Gruf::Instrumentation::Base` class, and implement the `call` method. See the StatsD 
instrumentor for an example.

## Plugins

You can build your own hooks and middleware for gruf; here's a list of known open source gems for
gruf that you can use today:
 
* [gruf-zipkin](https://github.com/bigcommerce/gruf-zipkin) - Provides a [Zipkin](https://zipkin.io)
integration for gruf
* [gruf-circuit-breaker](https://github.com/bigcommerce/gruf-circuit-breaker) - Provides circuit breaker
support for gruf services
* [gruf-profiler](https://github.com/bigcommerce/gruf-profiler) - Profiles and provides memory usage 
reports for gruf services

## Demo Rails App

There is a [demonstration Rails application here](https://github.com/bigcommerce/gruf-demo) you can view and clone
that shows how to integrate Gruf into an existing Rails application. 

## Roadmap

### Gruf 2.0

* Utilize the new core Ruby interceptors in gRPC 1.7
* Change configuration to an injectable object to ensure thread safety on chained server/client interactions
* Move all references to `Gruf.` configuration into injectable parameters
* Redo server configuration to be fully injectable
* Redo error handling to not share error as an instance variable
* Redo fail! to take in an error object instead of individual parameters

## License

Copyright (c) 2017-present, BigCommerce Pty. Ltd. All rights reserved 

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated 
documentation files (the "Software"), to deal in the Software without restriction, including without limitation the 
rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit 
persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the 
Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE 
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR 
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR 
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

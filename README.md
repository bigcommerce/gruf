# gruf - gRPC Ruby Framework

[![Build Status](https://travis-ci.org/bigcommerce/gruf.svg?branch=master)](https://travis-ci.org/bigcommerce/gruf) [![Gem Version](https://badge.fury.io/rb/gruf.svg)](https://badge.fury.io/rb/gruf) [![Documentation](https://inch-ci.org/github/bigcommerce/gruf.svg?branch=master)](https://inch-ci.org/github/bigcommerce/gruf?branch=master)

gruf is a Ruby framework that wraps the [gRPC Ruby library](https://github.com/grpc/grpc/tree/master/src/ruby) to
provide a more streamlined integration into Ruby and Ruby on Rails applications.

It provides an abstracted server and client for gRPC services, along with other tools to help get gRPC services in Ruby
up fast and efficiently at scale. Some of its features include:

* Abstracted controllers with request context support 
* Full interceptors with timing and unified request context support 
* Robust client error handling and metadata transport abilities
* Server authentication via interceptors, with basic auth with multiple key support built in
* TLS support for client-server auth, though we recommend using [linkerd](https://linkerd.io/) instead
* Error data serialization in output metadata to allow fine-grained error handling in the transport while 
  still preserving gRPC BadStatus codes
* Server and client execution timings in responses

gruf currently has active support for gRPC 1.4.x-1.8.x. gruf is compatible and tested with Ruby 2.2,
2.3, and 2.4. gruf is also not [Rails](https://github.com/rails/rails)-specific, and can be used in any 
Ruby framework (such as [Grape](https://github.com/ruby-grape/grape), for instance).

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

You'd have this handler in `/app/rpc/demo/job_controller.rb`

```ruby
module Demo
  class JobController < ::Gruf::Controllers::Base
    bind ::Demo::Jobs::Service
  
    ##
    # @return [Demo::GetJobResp] The job response
    #
    def get_job
      thing = Job.find(request.message.id)
      
      Demo::GetJobResp.new(id: thing.id)
    rescue
      fail!(:not_found, :job_not_found, "Failed to find Job with ID: #{request.message.id}")
    end
  end
end
```

Finally, you can start the server by running:

    bundle exec gruf

### Basic Authentication

Gruf comes packaged in with a Basic Authentication interceptor. It takes in an array of supported 
username and password pairs (or password-only credentials).

```ruby
Gruf.configure do |c|
  c.interceptors.use(
    Gruf::Interceptors::Authentication::Basic,
    credentials: [{
      username: 'my-username-here',
      password: 'my-password-here',    
    },{
      username: 'another-username',
      password: 'another-password',    
    },{
      password: 'a-password-only'
    }]
  )
end
```

Supporting an array of credentials allow for unique credentials per service, or for easy credential 
rotation with zero downtime.

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

## Server Interceptors

gruf supports interceptors around the grpc server calls, allowing you to perform actions around your service
method calls. This can be used to add tracing data, connection resets in the grpc thread pool, further 
instrumentation, and other things.

Adding a hook is as simple as creating a class that extends `Gruf::Interceptor::ServerInterceptor`, 
and a `call` method that yields control to get the method result:

```ruby
class MyInterceptor < ::Gruf::Interceptors::ServerInterceptor
  def call
    yield
  end
end
```

Interceptors have access to the `request` object, which is the `Gruf::Controller::Request` object
described above.

### Failing in an Interceptor

Interceptors can fail requests with the same method calls as a controller:

```ruby
class MyFailingInterceptor < ::Gruf::Interceptors::ServerInterceptor
  def call
    result = yield # this returns the protobuf message
    unless result.dont_hijack
      # we'll assume this "dont_hijack" attribute exists on the message for this example
      fail!(:internal, :hijacked, 'Hijack all the things!')
    end 
    result
  end
end
```

Similarly, you can raise `GRPC::BadStatus` calls to trigger similar errors without accompanying metadata.

### Configuring Interceptors

From there, the interceptor can be added to the server manually (if not executing via `bundle exec gruf`):

```ruby
server = Gruf::Server.new
server.add_interceptor(MyInterceptor, option_foo: 'value 123')
```

Or, alternatively, the more common method of passing them into the `interceptors` configuration hash:

```ruby
Gruf.configure do |c|
  c.interceptors.use(MyInterceptor, option_foo: 'value 123')
end
```

Interceptors each wrap the call and are run recursively within each other. This means that if you have 
three interceptors - `Interceptor1`, `Interceptor2`, and `Interceptor3` - they will run in FIFO 
(first in, first out) order. `Interceptor1` will run, yielding to `Interceptor2`, 
which will then yield to `Interceptor3`, which will then yield to your service method call, 
ending the chain.

You can utilize the `insert_before` and `insert_after` methods to maintain order:

```ruby
Gruf.configure do |c|
  c.interceptors.use(Interceptor1)
  c.interceptors.use(Interceptor2)
  c.interceptors.insert_before(Interceptor2, Interceptor3) # 3 will now happen before 2
  c.interceptors.insert_after(Interceptor1, Interceptor4) # 4 will now happen after 1
end
```

By default, the ActiveRecord Connection Reset interceptor and Output Metadata Timing interceptor
are loaded into gruf unless explicitly told not to via the `use_default_interceptors` configuration
parameter.

## Instrumentation

gruf comes out of the box with a couple of instrumentation interceptors packed in: 
output metadata timings and StatsD support. 

### Output Metadata Timing

Enabled by default, this will push timings for _successful responses_ through the response output 
metadata back to the client.

### StatsD

The StatsD support is not enabled by default. To enable it, you'll want to do:

```ruby
Gruf.configure do |c|
  c.interceptors.use(
    Gruf::Interceptors::Instrumentation::Statsd,
    client: ::Statsd.new('my.statsd.host', 8125),
    prefix: 'my_application_prefix.rpc'
  )
end
```

This will measure counts and timings for each endpoint.

### Request Logging

Gruf 1.2+ comes built with request logging out of the box; you'll get Rails-style logs with your 
gRPC calls:

```
# plain
I, [2017-07-14T09:50:54.200506 #70571]  INFO -- : [GRPC::Ok] (thing_service.get_thing) [0.348ms]
# logstash
I, [2017-07-14T09:51:03.299050 #70595]  INFO -- : {"message":"[GRPC::Ok] (thing_service.get_thing) [0.372ms]","service":"thing_service","method":"thing_service.get_thing","grpc_status":"GRPC::Ok"}
 ```

It supports formatters (including custom ones) that you can use to specify the formatting of the logging:
 
```ruby
Gruf.configure do |c|
  c.interceptors.use(
    Gruf::Interceptors::Instrumentation::RequestLogging::Interceptor,
    formatter: :logstash
  )
end
```

It comes with a few more options as well:

| Option | Description | Default |
| ------ | ----------- | ------- |
| formatter | The formatter to use. By default `:plain` and `:logstash` are supported. | `:logstash` |
| log_parameters | If set to true, will log parameters in the response | `false` |
| blacklist | An array of parameter key names to redact from logging, in path.to.key format | `[]` |
| redacted_string | The string to use for redacted parameters. | `REDACTED` |

It's important to maintain a safe blacklist should you decide to log parameters; gruf does no 
parameter sanitization on its own. We also recommend blacklisting parameters that may contain 
very large values (such as binary or json data).

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

There is a [demonstration Rails application here](https://github.com/bigcommerce/gruf-demo) you can 
view and clone that shows how to integrate Gruf into an existing Rails application. 

## Roadmap

### Gruf 3.0

* Utilize the new core Ruby interceptors in gRPC 1.7
* Support client interceptors
* Change configuration to an injectable object to ensure thread safety on chained server/client interactions
* Move all references to `Gruf.` configuration into injectable parameters
* Redo server configuration to be fully injectable
* Move client calls to their native method implementation

## Companies Using Gruf

Using gruf and want to show your support? Let us know and we'll add your name here.

* [BigCommerce](https://www.bigcommerce.com/)

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

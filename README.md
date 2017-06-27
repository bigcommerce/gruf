# gruf - gRPC Ruby Framework

[![Build Status](https://travis-ci.com/bigcommerce/gruf.svg?token=D3Cc4LCF9BgpUx4dpPpv&branch=master)](https://travis-ci.com/bigcommerce/gruf) [![Gem Version](https://badge.fury.io/rb/gruf.svg)](https://badge.fury.io/rb/gruf)

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

### Client

From there, you can instantiate a client given a stub service (say on an SslCertificates proto with a GetSslCertificate call):

```ruby
require 'gruf'

id = args[:id].to_i.presence || 1

begin
  client = ::Gruf::Client.new(service: MyPackage::MyService)
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

service Thing {
    rpc GetThing(GetThingReq) returns (GetSslCertificateResp) { }
}

message ThingReq {
    uint64 id = 1;
}

message ThingResp {
    uint64 id = 1;
    string name = 2;
}
```

You'd have this handler in `/app/rpc/demo/thing_server.rb`

```ruby
module Demo
  class ThingServer < ::Demo::ThingService::Service
    include Gruf::Service
  
    ##
    # @param [Demo::GetThingReq] req
    # @param [GRPC::ActiveCall] call
    # @return [Demo::GetThingResp]
    #
    def get_thing(req, call)
      ssl = Thing.find(req.id)
      
      Demo::Things::GetThingResp.new(
        id: ssl.id
      )
    rescue
      fail!(req, call, :not_found, :thing_not_found, "Failed to find Thing with ID: #{req.id}")
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
  c.instrumentation_options = {
    statsd: {
      client: ::Statsd.new('my.statsd.host', 8125),
      prefix: 'my_application_prefix.rpc'
    }
  }
end
Gruf::Instrumentation::Registry.add(:statsd, Gruf::Instrumentation::Statsd)
```

This will measure counts and timings for each endpoint.

### Custom Instrumentors

Similar to hooks, simply extend the `Gruf::Instrumentation::Base` class, and implement the `call` method. See the StatsD 
instrumentor for an example.

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

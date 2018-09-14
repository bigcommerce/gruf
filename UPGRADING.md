This document guides on how to upgrade between significant versions of Gruf.

## Upgrading to 2.5.0

Gruf 2.5 introduces the concept of Client Error subclasses, such as:

- `Gruf::Client::Errors::InvalidArgument`
- `Gruf::Client::Errors::NotFound`
- etc

These closely map with their `GRPC::BadStatus` counterparts, and each subclass `Gruf::Client::Error`. This should be
fully backwards compatible with your existing client error handling code, as the original exception through is still
available via `.error` on the raised exception.

However, one change is that Gruf will now catch `StandardError` and `GRPC::Core::CallError` exceptions at the client 
boundary, and translate them into `Gruf::Client::Errors::Internal` exceptions in the client. If you have code that
does not expect this case, you will need to adjust accordingly.

## Upgrading to 2.0.0

Gruf 2.0 is a major shift from Gruf 1.0. The following summarizes the changes:

### Services Are Now Controllers

Controllers now bind to services:

```ruby
class ThingController < ::Gruf::Controllers::Base
  bind ::Rpc::ThingService::Service

  ##
  # Get the thing
  #
  def get_thing
    thing =  Rpc::Thing.new(id: request.message.id, name: 'Foo')
    Rpc::GetThingResponse.new(thing: thing)
  end
end
```

Note the following changes:

* Methods no longer have request/call arguments. These are now accessible via the new
  `Gruf::Controllers::Request` object (more on that later).
* Controllers "bind" to a Service. This allows thread safety for controllers, and provides a clear
  separation layer between Gruf functionality and the generated service stubs by gRPC.
* You now extend your services with `Gruf::Controllers::Base`
* Furthermore, the `fail!` method no longer requires `req` and `call` to be passed in

### New Gruf::Controllers::Request Object

New in methods is the `request` instance variable, which provides thread-safe access to the request
and its context. The request object has the following methods:

* `request.message` - Similar to the first `req` argument in gRPC service stubs.
* `request.messages` - If using a client streamer call, this will allow you to pass a block in that
  will execute for each streamed client message. (It's similar to `call.each_remote_read` in gRPC).
  For non-client streaming messages, this will return an array of messages past. Requests with only
  one message will have an array of one item.
* `request.active_call` - The currently exposed view for the `GRPC::ActiveCall` object
* `request.method_key` - The Symbol name of the currently executing method
* `request.service_key` - A stats-friendly name of the namespaced service being executed against
* `request.method_name` - A stats-friendly name of the service and method being executed against

### Hooks Deprecated in Favor of Interceptors

Before, after, around, and outer around hooks have been removed in favor of the new
`Gruf::Interceptors::ServerInterceptor`. This paves the way for Gruf to support Client interceptors
and also support the native gRPC interceptors added in [gRPC 1.7](https://github.com/grpc/grpc/pull/12100).

Furthermore, Gruf 1.x had three different types of hooks with slightly different signatures: Authentication,
Instrumentation, and generic hooks. Those have all been consolidated into interceptors.

Interceptors behave very similarly to outer around hooks, with the following changes:

* They are now provided an instance of `Gruf::Controllers::Request`, which contains request information
  such as the request message(s), active call, metadata, service name, method key, and more.
* Their `call` method has no arguments, and _must_ yield control that will return the result of the method
  call.
* They execute in a FIFO execution order. Combined with the collapsing of the different hook types, this
  allows you to completely control the execution order of all interceptors in your service. For example,
  you can now have auth before _or_ after instrumentation, move metadata injection earlier, etc.

An base interceptor looks like this:

```ruby
class MyInterceptor < ::Gruf::Interceptors::ServerInterceptor
  def call
    yield
  end
end
```

From there, the interceptor can be added to the server manually (if not executing via `bundle exec gruf`):

```ruby
server = Gruf::Server.new
server.add_interceptor(MyInterceptor, option_foo: 'value 123')
```

Or, alternatively, by passing them into the `interceptors` configuration hash:

```ruby
Gruf.configure do |c|
  c.interceptors.use(MyInterceptor, option_foo: 'value 123')
end
```

### New Interceptor Timer Class

Important for instrumentation-related tasks, interceptors can now use a new `Gruf::Interceptors::Timer`
class, that exposes a `time` method that takes a block and will return a
`Gruf::Interceptors::Timer::Result` object.

This object will have the following attributes:

* `message` - The result of the block called; either the protobuf message returned, or the GRPC error
* `elapsed` - The time elapsed for the block call, in ms
* `successful?` - Whether or not the request was successful

This allows interceptors to fine-tune their time measurements, accounting properly for timing variance
dependent on where it lies in the interceptor chain.

### Other Changes

* The request logging interceptor now defaults to the `logstash` formatter
* `Gruf::Server` no longer supports specifying services in the constructor; they are done through
  the `add_service` method
* `Gruf.servers_path` has been removed in favor of `Gruf.controllers_path`

## Upgrading to 1.2.0

### Instrumentation Strategy Changes

Instrumentation hooks no longer have instance variables set on them during each call - this
is to move to dependency injection via a new `RequestContext` object that is now passed in
as the first argument to the `call` method on the instrumentation strategy.

You'll need to adjust your strategies to accommodate for this, by using the new `RequestContext`
argument instead of relying on the accessors on the strategy class itself.

### New Logging Hook

If you're doing any custom request logging in hooks, you'll want to disable that in favor
of the new `Gruf::Instrumentation::RequestLogging::Hook` that does that for you.

If you're desiring JSON or Logstash-formatted logs, make sure to set the following for config:

```ruby
Gruf.configure do |c|
  c.instrumentation_options[:request_logging] = {
    formatter: :logstash,
    log_parameters: false
  }
end
```

If you want to log parameters, we recommend setting a blacklist to ensure you don't accidentally
log sensitive data.

We also recommend blacklisting parameters that may contain very large values (such as binary
or json data).

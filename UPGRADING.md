This document guides on how to upgrade between significant versions of Gruf.
 
h2. Upgrading to 1.2.0

h3. Instrumentation Strategy Changes

Instrumentation hooks no longer have instance variables set on them during each call - this
is to move to dependency injection via a new `RequestContext` object that is now passed in
as the first argument to the `call` method on the instrumentation strategy.

You'll need to adjust your strategies to accommodate for this, by using the new `RequestContext`
argument instead of relying on the accessors on the strategy class itself.

h3. New Logging Hook

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

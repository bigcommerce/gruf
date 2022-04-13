Changelog for the gruf gem. This includes internal history before the gem was made.

### Pending release

- Fix issue where the server object hits thread contention in certain race conditions

### 2.14.0

- Set default client host to 0.0.0.0:9001 (same as default server host)
- Add support for Ruby 3.1

### 2.13.1

- Fix issue with race condition in server starts where servers may fail to bind connections and never reach  
  serving state (fixes #147)
 
### 2.13.0

- Remove server mutex handling in deference to core grpc signal handling
- Relax grpc pin as upstream regression is fixed

### 2.12.0

- Fixed interceptor order to be FIFO as documented, instead of FILO (fixes #139)

### 2.11.0

- Restrict grpc gem to <= 1.41.0 due to regressions in grpc 1.42.x 
- Fallback to stdout logger at INFO if no logger is setup
- Better handling of namespace collisions with Rails
- Add `GRPC_SERVER_HOST` and `GRPC_SERVER_PORT` for ENV configuration of the server host+port
- Add `GRPC_BACKTRACE_ON_ERROR` as available ENV configuration
- Add default ENV-based configuration of the GRPC server pool
  - `GRPC_SERVER_POOL_SIZE` - sets the size of the GRPC server pool
  - `GRPC_SERVER_POOL_KEEP_ALIVE` - keep alive time for threads spawned by the server pool
  - `GRPC_SERVER_POLL_PERIOD` - period in seconds to poll for workers in the gRPC server pool
- Improve Yardoc support across the library
- Added attribute-based documentation for Gruf configuration options
- Add mfa required for gemspec metadata

### 2.10.0

- Drop support for Ruby 2.4/2.5 to align with Ruby EOL schedule, supporting 2.6+ only
- Allow for float/TimeSpec timeout values on clients

### 2.9.1

- Allow for float/TimeSpec timeout values on clients (backport from 2.10.0)

### 2.9.0

- Change to racially neutral terminology across library
  - blacklist->blocklist
  - master->main branch
- Explicitly declare development dependencies in gemspec
- Add script/e2e test for full e2e test in regression suite
- Explicitly declare [json gem](https://rubygems.org/gems/json) dependency
- Update to Rubocop 1.4, add in rubocop-rspec for spec tests
- Add Ruby 2.7, 3.0 support

### 2.8.1

- Fix issue with --suppress-default-interceptors not working [#95]
- Loosen rake development dependency to >= 10.0 [#97]

### 2.8.0

- Pass the controller request object into the request logging formatters [#92]  

### 2.7.1

- Add `channel_credentials` option to `Gruf::Client` and `default_channel_credentials` option to `Gruf::Configuration` [#85] [#87]

### 2.7.0

- Add hook support for executing code paths before a server is started, and after a server stops

### 2.6.1

- Add frozen_string_literal: true to files, update rubocop to 0.68
  
### 2.6.0

- Drop Ruby 2.2 support
- Abstract gruf controller's send to make it usable in filters 
- Adjusts configuration reset into a Railtie for Rails systems to ensure proper OOE 
- Bump rubocop to 0.64, address violations, update activesupport/concurrent-ruby dependencies to have a min version

### 2.5.2

- Log ok/validation responses at DEBUG levels to prevent log stampeding in high-volume environments

### 2.5.1

- Ensure `timeout` is an int when passed as a client option to a gRPC client
- Add `bound_service` reader to `Gruf::Controllers::Base` for finding the service bound to the given controller

### 2.5.0

- Client exceptions raised now contain mapped subclasses, such as `Gruf::Client::Errors::InvalidArgument`
- Client exceptions will also now catch StandardError and GRPC::Core errors, and handle them as Internal errors
- Added SynchronizedClient which prevents multiple calls to the same endpoint with the same params at
  a given time. This is useful for mitigating thundering herds. To skip this behavior for certain endpoints,
  pass the `options[:unsynchronized_methods]` param with a list of method names (as symbols).

### 2.4.2

- Added error handling for GRPC::Core::CallError, a low-level error in the grpc library that does not inherit
  from StandardError. [#59]
- Removed `Thread.abort\_on\_exception = true`. Exceptions should be handled by gruf or the application,
  and should not cause the server process to crash. [#59]
- Added guard for size of trailing metadata attached to grpc call. The default max for http2 trailing metadata
  in the gRPC C library is 8kb. If we go over that limit (either through custom metadata attached to the
  error by the application, or via the error payload encoded by the error serializer), the gRPC library
  will throw RESOURCE\_EXHAUSTED. Gruf now detects this case, and attempts to prevent it by logging the
  original error and substituting it with an internal error indicating that the metadata was too large. [#60]
- Truncate stack trace in error payload to help avoid overflowing the trailing metadata. Added backtrace\_limit
  configuration parameter, which defaults to 10.[#60]

### 2.4.1

- Safer configuration of GRPC::RpcServer. From now on, use `Gruf.rpc_server_options` for the params
  to be sent to GPRC::RpcServer. Also provide sane defaults for params for GRPC::RpcServer. [#55]
- Added ability to monitor `RESOURCE_EXHAUSTED` and `UNIMPLEMENTED`. By setting `event_listener_proc` in
  the Gruf configuration, you will receive a callback when these events occur. The parameter to your
  callback will be a symbol (`:thread_pool_exhausted` or `:unimplemented`). Others may be added in the future.

### 2.4.0

- Added a hash of error log levels to RequestLogging interceptor, mapping error code to level of logging to use. To
override the level of logging per error response, provide a map of codes to log level in options, key :log_levels.
The default is :error log level.

### 2.3.0

- Add Gruf::Interceptors::ClientInterceptor for intercepting outbound client calls
- Add command-line arguments to the gruf binstub
- Add ability to specify server hostname via CLI argument

### 2.2.2

- Add ignore_methods option for RequestLogging interceptor [#45]

### 2.2.1

- Now changes proc title once server is ready to process incoming requests [#44]
- Gruf now requires gRPC 1.10.x+ due to various fixes and improvements in the gRPC core libraries

### 2.2.0

- Run server in a monitored thread to allow for trapped exits on sigints [#43]

### 2.1.1

- Add ability to pass in client stub options into Gruf::Client

### 2.1.0

- Add ability to list, clear, insert before, insert after, and remove to a server's interceptor
registry
- Ensure interceptors and services cannot be adjusted on the server after it starts to
prevent threading issues
- [#36], [#37] Adds `response_class`, `request_class`, and `service` accessors to controller request

### 2.0.3

- Fix regression [#35] where gruf was not able to be loaded outside of a Rails application

### 2.0.2

- Update Rubocop to 0.51
- Fix issue [#32] where server was not handling signals (\ht @Parad0X)

### 2.0.1

- Handle ActiveRecord connection management more gracefully (Fixes #30)

### 2.0.0

Gruf 2.0 is a major shift from Gruf 1.0. See [UPGRADING.md](UPGRADING.md) for details.

- New thread-safe controller-based model
- New controller request object
- Hooks deprecated in favor of interceptors
- New interceptor timer utility class
- Default logging to logstash formatter
- Various Gruf::Server improvements

### 1.2.7

- Fix issues where field errors were persisted in between separate calls

### 1.2.6

- Fix issues with arity and bidirectional streaming

### 1.2.5

- Fix reference issue for client and bidirectional streaming calls

### 1.2.4

- Loosen explicit Protobuf dependency now that 3.4.0.2 is released
- Guard against nil params in logger blocklist

### 1.2.3

- Support nested blocklist parameters in path.to.key format

### 1.2.2

- Pin Google Protobuf to 3.3.x due to failures in protobuf in Ruby at 3.4.x

### 1.2.1

- Added ability to pass in server options via new `server_options` configuration
  attribute. (\ht @kruczjak)

### 1.2.0

- Instrumentation hooks now execute similarly to outer_around hooks; they can
  now instrument failures
- Instrumentation hooks now pass a `RequestContext` object that contains information
  about the incoming request, instead of relying on instance variables
- StatsD hook now sends success/failure metrics for endpoints
- Add ability to turn off sending exception message on uncaught exception.
- Add configuration to set the error message when an uncaught exception is
  handled by gruf.
- Add a request logging hook for Rails-style request logging, with optional
  parameter logging, blocklists, and formatter support
- Optimizations around Symbol casting within service calls

### 1.1.0

- Add the ability for call options to the client, which enables deadline setting

### 1.0.0

- Bump gRPC to 1.4

### 0.14.2

- Added rubocop style-guide checks

### 0.14.1

- Updated license to MIT

### 0.14.0

- Send gRPC status 16 (Unauthenticated) instead of 7 (PermissionDenied) when authentication fails

### 0.13.0

- Move to gRPC 1.3.4

### 0.12.2

- Add outer_around hook for wrapping the entire call chain

### 0.12.1

- Add ability to specify a separate gRPC logger from the Gruf logger

### 0.12.0

- Add ability to run multiple around hooks
- Fix bug with error handling that caused error messages to repeat across streams

### 0.11.5

- Fix issue with around hook

### 0.11.4

- Add catchall rescue handler to capture uncaught exceptions and
  raise a GRPC::Internal error.
- Add Gruf.backtrace_on_error configuration value. If set, Gruf
  will call Service.set_debug_info with the exception backtrace
  if an uncaught exception occurs.

### 0.11.3

- Pass the service instance into hooks for reference

### 0.11.2

- Ensure timer is measuring in milliseconds

### 0.11.1

- Fix issue with interceptor and call signature

### 0.11.0

- Add instrumentation layer and ability to register new instrumentors
- Add out-of-the-box statsd instrumentation support

### 0.10.0

- Rename Gruf::Endpoint to Gruf::Service
- Make services auto-mount to server upon declaration

### 0.9.2

- Support mount command on services to allow automatic setup on the server
- Cleanup and consolidate binstub to prevent need for custom binstub per-app

### 0.9.1

- Relax licensing to a clean BSD license

### 0.9.0

- Initial public release

Changelog for the gruf gem. This includes internal history before the gem was made.

### Pending release

### 1.2.2

- Pin Google Protobuf to 3.3.x due to failures in protobuf in Ruby at 3.4.x

### 1.2.1

- Added ability to pass in server options via new `server_options` configuration
  attribute.

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
  parameter logging, blacklists, and formatter support 
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

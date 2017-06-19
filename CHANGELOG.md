Changelog for the gruf gem. This includes internal history before the gem was made.

h3. 0.14.2

- Added rubocop style-guide checks

h3. 0.14.1

- Updated license to MIT

h3. 0.14.0

- Send gRPC status 16 (Unauthenticated) instead of 7 (PermissionDenied) when authentication fails

h3. 0.13.0

- Move to gRPC 1.3.4

h4. 0.12.2

- Add outer_around hook for wrapping the entire call chain

h4. 0.12.1

- Add ability to specify a separate gRPC logger from the Gruf logger

h3. 0.12.0

- Add ability to run multiple around hooks
- Fix bug with error handling that caused error messages to repeat across streams 

h3. 0.11.5

- Fix issue with around hook

h3. 0.11.4

- Add catchall rescue handler to capture uncaught exceptions and
  raise a GRPC::Internal error.
- Add Gruf.backtrace_on_error configuration value. If set, Gruf
  will call Service.set_debug_info with the exception backtrace
  if an uncaught exception occurs.

h3. 0.11.3

- Pass the service instance into hooks for reference

h3. 0.11.2

- Ensure timer is measuring in milliseconds

h3. 0.11.1

- Fix issue with interceptor and call signature

h3. 0.11.0

- Add instrumentation layer and ability to register new instrumentors
- Add out-of-the-box statsd instrumentation support

h3. 0.10.0

- Rename Gruf::Endpoint to Gruf::Service
- Make services auto-mount to server upon declaration

h3. 0.9.2

- Support mount command on services to allow automatic setup on the server
- Cleanup and consolidate binstub to prevent need for custom binstub per-app

h3. 0.9.1

- Relax licensing to a clean BSD license

h3. 0.9.0

- Initial public release

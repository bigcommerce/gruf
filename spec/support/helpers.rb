# frozen_string_literal: true

# Copyright (c) 2017-present, BigCommerce Pty. Ltd. All rights reserved
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
# documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit
# persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
# Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
module Gruf
  module Helpers
    HOST = ENV.fetch('GRPC_HOSTNAME', '127.0.0.1:0').to_s
    USERNAME = ENV.fetch('GRPC_USERNAME', 'gruf').to_s
    PASSWORD = ENV.fetch('GRPC_PASSWORD', 'furg').to_s

    ##
    # Build a gRPC operation stub for testing
    #
    def build_operation(options = {})
      double(:operation, {
        execute: true,
        metadata: {},
        trailing_metadata: {},
        deadline: Time.now.to_i + 600,
        cancelled?: false,
        execution_time: rand(1_000..10_000)
       }.merge(options))
    end

    ##
    # @return [Gruf::Server]
    #
    def build_server
      is = respond_to?(:interceptors) ? interceptors : {}

      Gruf.interceptors.clear
      Gruf.configure do |c|
        c.server_binding_url = HOST
        c.default_client_host = HOST
        c.use_default_interceptors = false
        c.logger = ::Logger.new(File::NULL) unless ENV.fetch('GRUF_DEBUG', false)
        c.grpc_logger = ::Logger.new(File::NULL) unless ENV.fetch('GRPC_DEBUG', false)
      end
      s = Gruf::Server.new(poll_period: 1)
      is.each do |k, opts|
        s.add_interceptor(k, opts)
      end
      s.add_service(::Rpc::ThingService::Service)
      s
    end

    ##
    # Runs a server
    #
    # @param [Gruf::Server] server
    #
    def run_server(server)
      grpc_server = nil
      grpc_server = server.server

      t = Thread.new { grpc_server.run_till_terminated_or_interrupted(%w[INT TERM QUIT]) }
      grpc_server.wait_till_running

      timeout = ::ENV.fetch('GRUF_RSPEC_SERVER_TIMEOUT_SEC', 2)
      poll_period = ::ENV.fetch('GRPC_RSPEC_SERVER_POLL_PERIOD_SEC', 0.01).to_f
      begin
        yield
      ensure
        grpc_server.stop
        current_execution = 0.0
        until grpc_server.stopped?
          break if timeout.to_f > current_execution

          sleep(poll_period)
          current_execution += poll_period
        end
        t.join
        t.kill
      end
    rescue StandardError, RuntimeError, Exception
      grpc_server&.stop
      t&.join
      t&.kill
      nil
    ensure
      grpc_server&.stop
      t&.join
      t&.kill
    end

    ##
    # Builds a client
    #
    def build_client(options = {})
      Gruf::Client.new(
        service: ::Rpc::ThingService,
        options: {
          hostname: "127.0.0.1:#{@server.port}",
          username: USERNAME,
          password: PASSWORD
        }.merge(options)
      )
    end

    ##
    # Builds a client
    #
    def build_sync_client(options = {})
      Gruf::SynchronizedClient.new(
        service: ::Rpc::ThingService,
        options: {
          hostname: "127.0.0.1:#{@server.port}",
          username: USERNAME,
          password: PASSWORD
        }.merge(options)
      )
    end
  end
end

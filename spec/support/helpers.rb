# coding: utf-8
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
    HOST = ENV.fetch('GRPC_HOSTNAME', 'localhost:9002').freeze
    USERNAME = ENV.fetch('GRPC_USERNAME', 'gruf').freeze
    PASSWORD = ENV.fetch('GRPC_PASSWORD', 'furg').freeze

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
    # Runs a server
    #
    def run_server
      Gruf.configure do |c|
        c.server_binding_url = Gruf::Helpers::HOST
        c.default_client_host = Gruf::Helpers::HOST
        c.server_options = { poll_period: 1 }
        c.grpc_logger = ::Logger.new('/dev/null') unless ENV['GRPC_DEBUG']
        c.authentication_options[:credentials] = {
          username: Gruf::Helpers::USERNAME,
          password: Gruf::Helpers::PASSWORD
        }
        c.services = [ThingService]
      end
      Gruf::Authentication::Strategies.add(:basic, Gruf::Authentication::Basic)

      server = Gruf::Server.new
      grpc_server = server.server

      t = Thread.new do
        grpc_server.run
      end
      grpc_server.wait_till_running

      yield

      grpc_server.stop
      t.join
    end

    ##
    # Builds a client
    #
    def build_client
      Gruf::Client.new(service: ::Rpc::ThingService, options: {
        hostname: HOST,
        username: USERNAME,
        password: PASSWORD
      })
    end
  end
end

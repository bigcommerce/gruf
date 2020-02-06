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
  module Interceptors
    module Instrumentation
      module RequestLogging
        module Formatters
          ##
          # Formats the request into plaintext logging
          #
          class Plain < Base
            ##
            # Format the request by only outputting the message body and params (if set to log params)
            #
            # @param [Hash] payload The incoming request payload
            # @param [Gruf::Controllers::Request] request The current controller request
            # @param [Gruf::Interceptors::Timer::Result] result The timed result of the response
            # @return [String] The formatted string
            #
            def format(payload, request:, result:)
              time = payload.fetch(:duration, 0)
              grpc_status = payload.fetch(:grpc_status, 'GRPC::Ok')
              route_key = payload.fetch(:method, 'unknown')
              body = payload.fetch(:message, '')

              msg = "[#{grpc_status}] (#{route_key}) [#{time}ms] #{body}".strip
              msg += " Parameters: #{payload[:params].to_h}" if payload.key?(:params)
              msg.strip
            end
          end
        end
      end
    end
  end
end

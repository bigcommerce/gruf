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
require 'json'

module Gruf
  module Interceptors
    module Instrumentation
      module RequestLogging
        module Formatters
          ##
          # Formats logging for gruf services into a Logstash-friendly JSON format
          #
          class Logstash < Base
            ##
            # Format the request into a JSON-friendly payload
            #
            # @param [Hash] payload The incoming request payload
            # @param [Gruf::Controllers::Request] request The current controller request
            # @param [Gruf::Interceptors::Timer::Result] result The timed result of the response
            # @return [String] The JSON representation of the payload
            #
            def format(payload, request:, result:)
              payload.merge(format: 'json').to_json
            end
          end
        end
      end
    end
  end
end

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
  module Interceptors
    ##
    # Base class for interception requests
    #
    class Base
      # @var [Gruf::Controllers::Request] request
      attr_reader :request
      # @var [Gruf::Error] error
      attr_reader :error
      # @var [Hash] options
      attr_reader :options

      ##
      # @param [Gruf::Controllers::Request] request
      # @param [Gruf::Error] error
      # @param [Hash] options
      #
      def initialize(request, error, options = {})
        @request = request
        @error = error
        @options = options || {}
      end
    end
  end
end

require_relative 'server_interceptor'
require_relative 'context'
require_relative 'timer'
require_relative 'active_record/connection_reset'
require_relative 'authentication/basic'
require_relative 'instrumentation/statsd'
require_relative 'instrumentation/output_metadata_timer'
require_relative 'instrumentation/request_logging/interceptor'

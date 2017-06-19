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
  module Instrumentation
    ##
    # Base class for a hook. Define before, around, or after methods to utilize functionality.
    #
    class Base
      include Gruf::Loggable

      attr_reader :options, :service, :response, :request, :execution_time, :call_signature, :active_call

      def initialize(service, request, response, execution_time, call_signature, active_call, options = {})
        @service = service
        @request = request
        @response = response
        @execution_time = execution_time
        @call_signature = call_signature.to_s.gsub('_without_intercept', '').to_sym
        @active_call = active_call
        @options = options
        setup
      end

      ##
      # Useful for setting up an instrumentation module post instantiation
      #
      def setup
        # noop
      end

      ##
      # @return [Boolean]
      #
      def success?
        !response.is_a?(GRPC::BadStatus)
      end

      ##
      #
      def call
        raise NotImplementedError
      end
    end
  end
end

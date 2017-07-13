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
    # Base class for an instrumentation strategy. Define a call method to utilize functionality.
    #
    class Base
      include Gruf::Loggable

      # @return [Gruf::Service] service The service to instrument
      attr_reader :service
      # @return [Object] request The protobuf request object
      attr_reader :request
      # @return [Object] response The protobuf response object
      attr_reader :response
      # @return [Time] execution_time The execution time, in ms, of the request
      attr_reader :execution_time
      # @return [Symbol] call_signature The gRPC method on the service that was called
      attr_reader :call_signature
      # @return [GRPC::ActiveCall] active_call The gRPC core active call object, which represents marshalled data for
      # the call itself
      attr_reader :active_call
      # @return [Hash] options Options to use when instrumenting the call
      attr_reader :options

      ##
      # @param [Gruf::Service] service The service to instrument
      # @param [Object] request The protobuf request object
      # @param [Object] response The protobuf response object
      # @param [Time] execution_time The execution time, in ms, of the request
      # @param [Symbol] call_signature The gRPC method on the service that was called
      # @param [GRPC::ActiveCall] active_call the gRPC core active call object, which represents marshalled data for
      # the call itself
      # @param [Hash] options (Optional) Options to use when instrumenting the call
      #
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
      # Was this call a success? If a response is a GRPC::BadStatus object, we assume that it was unsuccessful
      #
      # @return [Boolean] True if was a successful call
      #
      def success?
        !response.is_a?(GRPC::BadStatus)
      end

      ##
      # Abstract method that is required for implementing an instrumentation strategy.
      #
      # @abstract
      #
      def call
        raise NotImplementedError
      end
    end
  end
end

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
    # Represents a request context for a given incoming gRPC request. This represents an injection layer that is used
    # to pass to instrumentation strategies safely across thread boundaries.
    #
    class RequestContext
      # @return [Gruf::Service] service The service to instrument
      attr_reader :service
      # @return [Object] request The protobuf request object
      attr_reader :request
      # @return [Object] response The protobuf response object
      attr_reader :response
      # @return [Symbol] call_signature The gRPC method on the service that was called
      attr_reader :call_signature
      # @return [GRPC::ActiveCall] active_call The gRPC core active call object, which represents marshalled data for
      # the call itself
      attr_reader :active_call
      # @return [Time] execution_time The execution time, in ms, of the request
      attr_reader :execution_time

      ##
      # Initialize the request context given the request and response
      #
      def initialize(
        service:,
        request:,
        response:,
        call_signature:,
        active_call:,
        execution_time: 0.00
      )
        @service = service
        @request = request
        @response = response
        @call_signature = call_signature
        @active_call = active_call
        @execution_time = execution_time
      end

      ##
      # @return [Boolean] True if the response is successful
      #
      def success?
        !response.is_a?(GRPC::BadStatus)
      end

      ##
      # @return [String] Return the response class name
      #
      def response_class_name
        response.class.name
      end

      ##
      # Return the execution time rounded to a specified precision
      #
      # @param [Integer] precision The amount of decimal places to round to
      # @return [Float] The execution time rounded to the appropriate decimal point
      #
      def execution_time_rounded(precision: 2)
        execution_time.to_f.round(precision)
      end
    end
  end
end

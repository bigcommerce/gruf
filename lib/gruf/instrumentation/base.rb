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
require_relative 'request_context'

module Gruf
  module Instrumentation
    ##
    # Base class for an instrumentation strategy. Define a call method to utilize functionality.
    #
    class Base
      include Gruf::Loggable

      # @return [Gruf::Service] service The service to instrument
      attr_reader :service
      # @return [Hash] options Options to use when instrumenting the call
      attr_reader :options

      ##
      # @param [Gruf::Service] service The service to instrument
      # @param [Hash] options (Optional) Options to use when instrumenting the call
      #
      def initialize(service, options = {})
        @service = service
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
      # @param [Object] response The gRPC response object
      # @return [Boolean] True if was a successful call
      #
      def success?(response)
        !response.is_a?(GRPC::BadStatus)
      end

      ##
      # Abstract method that is required for implementing an instrumentation strategy.
      #
      # @abstract
      # @param [Gruf::Instrumentation::RequestContext] _rc The current request context for the call
      #
      def call(_rc)
        raise NotImplementedError
      end

      ##
      # Hook into the outer_around call to time the request, and pass that to the call method
      #
      # @param [Symbol] call_signature The method being called
      # @param [Object] request The request object
      # @param [GRPC::ActiveCall] active_call The gRPC active call object
      # @param [Proc] &_block The execution block for the call
      # @return [Object] result The result of the block that was called
      #
      def outer_around(call_signature, request, active_call, &_block)
        timed = Timer.time do
          yield
        end
        rc = RequestContext.new(
          service: service,
          request: request,
          response: timed.result,
          execution_time: timed.time,
          call_signature: call_signature,
          active_call: active_call
        )
        call(rc)
        raise rc.response unless rc.success?
        rc.response
      end

      ##
      # @return [String] Returns the service name as a translated name separated by periods
      #
      def service_key
        service.class.name.underscore.tr('/', '.')
      end

      ##
      # Parse the method signature into a service.method name format
      #
      # @param [Symbol] call_signature The method call signature
      # @param [String] delimiter The delimiter to separate service and method keys
      # @return [String] The parsed service method name
      #
      def method_key(call_signature, delimiter: '.')
        "#{service_key}#{delimiter}#{call_signature}"
      end
    end
  end
end

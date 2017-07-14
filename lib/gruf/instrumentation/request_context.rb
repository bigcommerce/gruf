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

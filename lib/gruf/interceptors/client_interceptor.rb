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
    ##
    # Intercepts outbound client requests to provide a unified interface and request context
    #
    class ClientInterceptor < GRPC::ClientInterceptor
      include Gruf::Loggable

      ##
      # Handles interception of outbound calls. Implement this in your derivative interceptor implementation.
      #
      # @param [Gruf::Outbound::RequestContext] request_context The context of the outbound request
      # @return [Object] This method must return the response from the yielded block
      #
      def call(request_context:)
        logger.debug "Logging client interceptor for request: #{request_context.method}"
        yield
      end

      ##
      # Call the interceptor from the request_response call
      #
      # @param [Object] request The request being sent
      # @param [GRPC::ActiveCall] call The GRPC ActiveCall object
      # @param [Method] method The method being called
      # @param [Hash] metadata A hash of outgoing metadata
      # @return [Object] The response message
      #
      def request_response(request: nil, call: nil, method: nil, metadata: nil, &block)
        rc = Gruf::Outbound::RequestContext.new(
          type: :request_response,
          requests: [request],
          call: call,
          method: method,
          metadata: metadata
        )
        call(request_context: rc, &block)
      end

      ##
      # Call the interceptor from the client_streamer call
      #
      # @param [Enumerable] requests An enumerable of requests being sent
      # @param [GRPC::ActiveCall] call The GRPC ActiveCall object
      # @param [Method] method The method being called
      # @param [Hash] metadata A hash of outgoing metadata
      # @return [Object] The response message
      #
      def client_streamer(requests: nil, call: nil, method: nil, metadata: nil, &block)
        rc = Gruf::Outbound::RequestContext.new(
          type: :client_streamer,
          requests: requests,
          call: call,
          method: method,
          metadata: metadata
        )
        call(request_context: rc, &block)
      end

      ##
      # Call the interceptor from the server_streamer call
      #
      # @param [Object] request The request being sent
      # @param [GRPC::ActiveCall] call The GRPC ActiveCall object
      # @param [Method] method The method being called
      # @param [Hash] metadata A hash of outgoing metadata
      # @return [Object] The response message
      #
      def server_streamer(request: nil, call: nil, method: nil, metadata: nil, &block)
        rc = Gruf::Outbound::RequestContext.new(
          type: :server_streamer,
          requests: [request],
          call: call,
          method: method,
          metadata: metadata
        )
        call(request_context: rc, &block)
      end

      ##
      # Call the interceptor from the bidi_streamer call
      #
      # @param [Enumerable] requests An enumerable of requests being sent
      # @param [GRPC::ActiveCall] call The GRPC ActiveCall object
      # @param [Method] method The method being called
      # @param [Hash] metadata A hash of outgoing metadata
      #
      def bidi_streamer(requests: nil, call: nil, method: nil, metadata: nil, &block)
        rc = Gruf::Outbound::RequestContext.new(
          type: :bidi_streamer,
          requests: requests,
          call: call,
          method: method,
          metadata: metadata
        )
        call(request_context: rc, &block)
      end
    end
  end
end

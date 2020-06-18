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
  module Controllers
    ##
    # Encapsulates a request for a controller
    #
    class Request
      # @var [Object] message
      attr_reader :message
      # @var [GRPC::ActiveCall] active_call
      attr_reader :active_call
      # @var [Symbol] method_key
      attr_reader :method_key
      # @var [Gruf::Controllers::Request::Type] type
      attr_reader :type
      # @var [Class] service
      attr_reader :service

      delegate :metadata, to: :active_call
      delegate :messages, :client_streamer?, :server_streamer?, :bidi_streamer?, :request_response?, to: :type

      ##
      # Abstract representation of a gRPC request type
      #
      class Type
        delegate :client_streamer?, :server_streamer?, :bidi_streamer?, :request_response?, to: :@rpc_desc

        ##
        # Initialize a new request type object
        #
        # @param [GRPC::RpcDesc] rpc_desc The RPC descriptor for the request type
        #
        def initialize(rpc_desc)
          @rpc_desc = rpc_desc
        end
      end

      ##
      # Initialize an inbound controller request object
      #
      # @param [Symbol] method_key The method symbol of the RPC method being executed
      # @param [Class] service The class of the service being executed against
      # @param [GRPC::RpcDesc] rpc_desc The RPC descriptor of the call
      # @param [GRPC::ActiveCall] active_call The restricted view of the call
      # @param [Object|Google::Protobuf::MessageExts] message The protobuf message (or messages) of the request
      #
      def initialize(method_key:, service:, rpc_desc:, active_call:, message:)
        @method_key = method_key
        @service = service
        @active_call = active_call
        @message = message
        @rpc_desc = rpc_desc
        @type = Type.new(rpc_desc)
      end

      ##
      # Returns the service name as a translated name separated by periods. Strips
      # the superfluous "Service" suffix from the name
      #
      # @return [String] The mapped service key
      #
      def service_key
        @service.name.underscore.tr('/', '.').gsub('.service', '')
      end

      ##
      # @return [Class] The class of the response message
      #
      def response_class
        @rpc_desc.output
      end

      ##
      # @return [Class] The class of the request message
      #
      def request_class
        @rpc_desc.input
      end

      ##
      # Parse the method signature into a service.method name format
      #
      # @return [String] The parsed service method name
      #
      def method_name
        "#{service_key}.#{method_key}"
      end

      ##
      # Return all messages for this request, properly handling different request types
      #
      # @return Enumerable<Object> All messages for this request
      #
      def messages
        if client_streamer?
          message.call { |msg| yield msg }
        elsif bidi_streamer?
          message
        else
          [message]
        end
      end
    end
  end
end

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
  module Outbound
    ##
    # Encapsulates the context of an outbound client request
    #
    class RequestContext
      # @!attribute [r] type
      #   @return [Symbol]
      attr_reader :type
      # @!attribute [r] requests
      #   @return [Enumerable] requests
      attr_reader :requests
      # @!attribute [r] call
      #   @return [GRPC::ActiveCall]
      attr_reader :call
      # @!attribute [r] method
      #   @return [Method] method
      attr_reader :method
      # @!attribute [r] metadata
      #   @return [Hash] metadata
      attr_reader :metadata

      ##
      # Initialize the new request context
      #
      # @param [Symbol] type The type of request
      # @param [Enumerable] requests An enumerable of requests being sent
      # @param [GRPC::ActiveCall] call The GRPC ActiveCall object
      # @param [Method] method The method being called
      # @param [Hash] metadata A hash of outgoing metadata
      #
      def initialize(type:, requests:, call:, method:, metadata:)
        @type = type
        @requests = requests
        @call = call
        @method = method
        @metadata = metadata
      end

      ##
      # Return the name of the method being called, e.g. GetThing
      #
      # @return [String]
      #
      def method_name
        @method.to_s.split('/').last.to_s
      end

      ##
      # Return the proper routing key for the request
      #
      # @return [String]
      #
      def route_key
        @method[1..].to_s.underscore.tr('/', '.')
      end
    end
  end
end

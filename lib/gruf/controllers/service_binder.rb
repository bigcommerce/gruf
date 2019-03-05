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
    # Binds gRPC services to a gruf controller
    #
    class ServiceBinder
      ##
      # Represents a bound RPC descriptor for future-proofing internal helpers
      #
      class BoundDesc < SimpleDelegator; end

      ##
      # Initialize a service binder instance with the given service
      #
      # @param [GRPC::GenericService] service The gRPC service stub to bind
      #
      def initialize(service)
        @service = service
      end

      ##
      # Bind all methods on the service to the passed controller
      #
      # @param [Gruf::Controllers::Base] controller
      #
      def bind!(controller)
        rpc_methods.each { |name, desc| bind_method(controller, name, desc) }
      end

      private

      ##
      # Bind the grpc methods to the service, allowing for server interception and execution control
      #
      # @param [Gruf::Controllers::Base] controller
      # @param [Symbol] method_name
      # @param [BoundDesc] desc
      #
      def bind_method(controller, method_name, desc)
        method_key = method_name.to_s.underscore.to_sym

        return unless controller.public_method_defined?(method_key)

        service_ref = @service

        @service.class_eval do
          if desc.request_response?
            define_method(method_key) do |message, active_call|
              c = controller.new(method_key: method_key, service: service_ref, message: message, active_call: active_call, rpc_desc: desc)
              c.call(method_key)
            end
          elsif desc.client_streamer?
            define_method(method_key) do |active_call|
              c = controller.new(method_key: method_key, service: service_ref, message: proc { |&block| active_call.each_remote_read(&block) }, active_call: active_call, rpc_desc: desc)
              c.call(method_key)
            end
          elsif desc.server_streamer?
            define_method(method_key) do |message, active_call, &block|
              c = controller.new(method_key: method_key, service: service_ref, message: message, active_call: active_call, rpc_desc: desc)
              c.call(method_key, &block)
            end
          else # bidi
            define_method(method_key) do |messages, active_call, &block|
              c = controller.new(method_key: method_key, service: service_ref, message: messages, active_call: active_call, rpc_desc: desc)
              c.call(method_key, &block)
            end
          end
        end
      end

      ##
      # @return Array<Gruf::Controllers::ServiceBinder::BoundDesc>
      #
      def rpc_methods
        @service.rpc_descs.map { |rd| BoundDesc.new(rd) }
      end
    end
  end
end

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
require_relative 'request'

module Gruf
  module Controllers
    ##
    # Base controller object for Gruf gRPC requests
    #
    class Base
      include Gruf::Errors::Helpers

      # @var [Gruf::Controller::Request] request
      attr_reader :request
      # @var [Gruf::Error] error
      attr_reader :error

      class << self
        # @var [GRPC::GenericService] bound_service
        attr_reader :bound_service
      end

      ##
      # Initialize the controller within the given request context
      #
      # @param [Symbol] method_key The gRPC method that this controller relates to
      # @param [GRPC::GenericService] service The gRPC service stub for this controller
      # @param [GRPC::RpcDesc] rpc_desc The RPC descriptor for this service method
      # @param [GRPC::ActiveCall] active_call The gRPC ActiveCall object
      # @param [Google::Protobuf::MessageExts] message The incoming protobuf request message
      #
      def initialize(method_key:, service:, rpc_desc:, active_call:, message:)
        @request = Request.new(
          method_key: method_key,
          service: service,
          rpc_desc: rpc_desc,
          active_call: active_call,
          message: message
        )
        @error = Gruf::Error.new
        @interceptors = Gruf.interceptors.prepare(@request, @error)
      end

      ##
      # Bind the controller to the given service and add it to the service registry
      #
      # @param [GRPC::GenericService] service The name of the service to bind this controller to
      #
      def self.bind(service)
        service_class = service.name.constantize
        Gruf.services << service_class unless Gruf.services.include?(service_class)
        Gruf.controller_registry.add(self, service_class)
        @bound_service = service_class
      end

      ##
      # Call a method on this controller
      #
      # @param [Symbol] method_key The name of the gRPC service method being called as a Symbol
      # @param [block] &block The passed block for executing the method
      #
      def call(method_key, &block)
        Interceptors::Context.new(@interceptors).intercept! do
          send(method_key, &block)
        end
      rescue GRPC::BadStatus
        raise # passthrough, to be caught by Gruf::Interceptors::Timer
      rescue GRPC::Core::CallError, StandardError => e # CallError is not a StandardError
        set_debug_info(e.message, e.backtrace) if Gruf.backtrace_on_error
        error_message = Gruf.use_exception_message ? e.message : Gruf.internal_error_message
        fail!(:internal, :unknown, error_message)
      end
    end
  end
end

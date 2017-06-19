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
  ##
  # Module for gRPC endpoints
  #
  module Service
    extend ActiveSupport::Concern

    included do
      include Gruf::Loggable

      ##
      # Hook into method_added to add pre/post interceptors for endpoints
      #
      # @param [String] method_name
      #
      def self.method_added(method_name)
        return if @__last_methods_added && @__last_methods_added.include?(method_name)
        if self.rpc_handler_names.include?(method_name)
          with = :"#{method_name}_with_intercept"
          without = :"#{method_name}_without_intercept"
          @__last_methods_added = [method_name, with, without]
          define_method with do |*args, &block|
            call_chain(without, args[0], args[1], &block)
          end
          alias_method without, method_name
          alias_method method_name, with
          @__last_methods_added = nil
        end
      end

      ##
      # Properly find all RPC handler methods
      #
      def self.rpc_handler_names
        self.rpc_descs.keys.map { |n| n.to_s.underscore.to_sym }.uniq
      end

      ##
      # Mount the service into the server automatically
      #
      def self.mount
        Gruf.services << self.name.constantize
      end

      mount
    end

    ##
    # Happens before a call.
    #
    # @param [Symbol] call_signature The method being called
    # @param [Object] req The request object
    # @param [GRPC::ActiveCall] call The gRPC active call object
    #
    def before_call(call_signature, req, call)
      authenticate(call_signature, req, call)
      Gruf::Hooks::Registry.each do |_name, h|
        h.new(self, Gruf.hook_options).before(call_signature, req, call) if h.instance_methods.include?(:before)
      end
    end

    ##
    # Happens around a call.
    #
    # @param [Symbol] call_signature The gRPC method being called
    # @param [Object] req The request object
    # @param [GRPC::ActiveCall] call The gRPC active call object
    #
    def around_call(call_signature, req, call, &block)
      around_hooks = []
      Gruf::Hooks::Registry.each do |_name, h|
        around_hooks << h.new(self, Gruf.hook_options) if h.instance_methods.include?(:around)
      end
      if around_hooks.any?
        run_around_hook(around_hooks, call_signature, req, call, &block)
      else
        yield
      end
    end

    ##
    # Run all around hooks recursively, starting with the last loaded
    #
    # @param [Array<Gruf::Hooks::Base>] hooks The current stack of hooks
    # @param [Symbol] call_signature The gRPC method being called
    # @param [Object] req The request object
    # @param [GRPC::ActiveCall] call The gRPC active call object
    #
    def run_around_hook(hooks, call_signature, req, call, &_)
      h = hooks.pop
      h.around(call_signature, req, call) do
        if hooks.any?
          run_around_hook(hooks, call_signature, req, call) { yield }
        else
          yield
        end
      end
    end

    ##
    # Happens around the entire call chain - before, around, the call itself, and after hooks.
    #
    # @param [Symbol] call_signature The gRPC method being called
    # @param [Object] req The request object
    # @param [GRPC::ActiveCall] call The gRPC active call object
    #
    def outer_around_call(call_signature, req, call, &block)
      outer_around_hooks = []
      Gruf::Hooks::Registry.each do |_name, h|
        outer_around_hooks << h.new(self, Gruf.hook_options) if h.instance_methods.include?(:outer_around)
      end
      if outer_around_hooks.any?
        run_outer_around_hook(outer_around_hooks, call_signature, req, call, &block)
      else
        yield
      end
    end

    ##
    # Run all outer around hooks recursively, starting with the last loaded
    #
    # @param [Array<Gruf::Hooks::Base>] hooks The current stack of hooks
    # @param [Symbol] call_signature The gRPC method being called
    # @param [Object] req The request object
    # @param [GRPC::ActiveCall] call The gRPC active call object
    #
    def run_outer_around_hook(hooks, call_signature, req, call, &_)
      h = hooks.pop
      h.outer_around(call_signature, req, call) do
        if hooks.any?
          run_outer_around_hook(hooks, call_signature, req, call) { yield }
        else
          yield
        end
      end
    end

    ##
    # Happens after a call
    #
    # @param [Boolean] success Whether or not the result was successful
    # @param [Object] response The response object returned from the gRPC call
    # @param [Symbol] call_signature The method being called
    # @param [Object] req The request object
    # @param [GRPC::ActiveCall] call The gRPC active call object
    # @return [Object] If extending this method or using the after_call_hook, you must return the response object
    #
    def after_call(success, response, call_signature, req, call)
      Gruf::Hooks::Registry.each do |_name, h|
        h.new(self, Gruf.hook_options).after(success, response, call_signature, req, call) if h.instance_methods.include?(:after)
      end
    end

    ##
    # Authenticate the endpoint caller.
    #
    # @param [Symbol] _method The method being called
    # @param [Object] req The request object
    # @param [GRPC::ActiveCall] call The gRPC active call object
    #
    def authenticate(_method, req, call)
      fail!(req, call, :unauthenticated) unless Authentication.verify(call)
    end

    ##
    # Will issue a GRPC BadStatus exception, with a code based on the code passed.
    #
    # @param [Object] _req The request object being sent
    # @param [GRPC::ActiveCall] call The gRPC active call
    # @param [Symbol] error_code The network error code that maps to gRPC status codes
    # @param [Symbol] app_code The application-specific code for the error
    # @param [String] message (Optional) A detail message about the error
    # @param [Hash] metadata (Optional) Any metadata to inject into the trailing metadata for the response
    # @return [RPC::Error]
    #
    def fail!(_req, call, error_code, app_code = nil, message = '', metadata = {})
      error.code = error_code.to_sym
      error.app_code = app_code ? app_code.to_sym : error.code
      error.message = message.to_s
      error.metadata = metadata
      error.fail!(call)
    end

    private

    ##
    # Encapsulate the call chain to provide before/around/after hooks
    #
    # @param [Symbol] original_call_sig The original call signature for the service
    # @param [Object] req The request object
    # @param [GRPC::ActiveCall] call The ActiveCall object being executed
    # @return [Object] The response object
    #
    def call_chain(original_call_sig, req, call, &block)
      outer_around_call(original_call_sig, req, call) do
        before_call(original_call_sig, req, call)
        timed = Timer.time do
          around_call(original_call_sig, req, call) do
            send(original_call_sig, req, call, &block) # send the actual request to gRPC
          end
        end
        after_call(timed.success?, timed.result, original_call_sig, req, call)

        Gruf::Instrumentation::Registry.each do |_name, h|
          h.new(self, req, timed.result, timed.time, original_call_sig, call, Gruf.instrumentation_options).call
        end

        if timed.success?
          timed.result
        else
          raise timed.result
        end
      end
    rescue => e
      raise e if e.is_a?(GRPC::BadStatus)
      set_debug_info(e.message, e.backtrace) if Gruf.backtrace_on_error
      fail!(req, call, :internal, :unknown, e.message)
    end

    ##
    # Add a field error to this endpoint
    #
    # @param [Symbol] field_name
    # @param [Symbol] error_code
    # @param [String] message
    #
    def add_field_error(field_name, error_code, message = '')
      error.add_field_error(field_name, error_code, message)
    end

    ##
    # Return true if there are any present field errors
    #
    # @return [Boolean]
    #
    def has_field_errors?
      error.field_errors.any?
    end

    ##
    # Set debugging information on the error payload
    #
    # @param [String] detail A string message that represents debugging information
    # @param [Array<String>] stack_trace An array of strings that contain the backtrace
    #
    def set_debug_info(detail, stack_trace = [])
      error.set_debug_info(detail, stack_trace)
    end

    ##
    # @return [Gruf::Error]
    #
    def error
      @error ||= Gruf::Error.new
    end
  end
end

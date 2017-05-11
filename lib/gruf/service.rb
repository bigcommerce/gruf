# Copyright 2017, Bigcommerce Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
# 1. Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
# 3. Neither the name of BigCommerce Inc. nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
      Gruf::Hooks::Registry.each do |_name, h|
        h.new(self, Gruf.hook_options).before(call_signature, req, call) if h.instance_methods.include?(:before)
      end
      authenticate(call_signature, req, call)
    end

    ##
    # Happens around a call.
    #
    # @param [Symbol] call_signature The gRPC method being called
    # @param [Object] req The request object
    # @param [GRPC::ActiveCall] call The gRPC active call object
    #
    def around_call(call_signature, req, call, &block)
      around_hook = nil
      Gruf::Hooks::Registry.each do |_name, h|
        around_hook = h.instance_methods.include?(:around)
      end
      # we only call the _last loaded_ around hook, if there is one
      if around_hook
        h.new(self, Gruf.hook_options).around(call_signature, req, call, &block)
      else
        yield
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
      fail!(req, call, :unauthorized) unless Authentication.verify(call)
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
      begin
        before_call(original_call_sig, req, call)
        timed = Timer.time do
          around_call(original_call_sig, req, call) do
            send(original_call_sig, req, call, &block) # send the actual request to gRPC
          end
        end
        after_call(timed.success?,timed.result, original_call_sig, req, call)

        Gruf::Instrumentation::Registry.each do |_name, h|
          h.new(self, req, timed.result, timed.time, original_call_sig, call, Gruf.instrumentation_options).call
        end

        if timed.success?
          timed.result
        else
          raise timed.result
        end
      rescue => e
        raise e if e.is_a?(GRPC::BadStatus)
        set_debug_info(e.message, e.backtrace) if Gruf.backtrace_on_error
        fail!(req, call, :internal, :unknown, e.message)
      end
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

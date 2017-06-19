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
require_relative 'errors/field'
require_relative 'errors/debug_info'
require_relative 'serializers/errors/base'
require_relative 'serializers/errors/json'

module Gruf
  ##
  # Represents a error that can be transformed into a gRPC error and have metadata attached to the trailing headers.
  # This layer acts as an middle layer that can have metadata injection, tracing support, and other functionality
  # not present in the gRPC core.
  #
  class Error
    include Gruf::Loggable

    TYPES = {
      ok: GRPC::Ok,
      cancelled: GRPC::Cancelled,
      unknown: GRPC::Unknown,
      invalid_argument: GRPC::InvalidArgument,
      bad_request: GRPC::InvalidArgument,
      deadline_exceeded: GRPC::DeadlineExceeded,
      not_found: GRPC::NotFound,
      already_exists: GRPC::AlreadyExists,
      unauthorized: GRPC::PermissionDenied,
      permission_denied: GRPC::PermissionDenied,
      unauthenticated: GRPC::Unauthenticated,
      resource_exhausted: GRPC::ResourceExhausted,
      failed_precondition: GRPC::FailedPrecondition,
      aborted: GRPC::Aborted,
      out_of_range: GRPC::OutOfRange,
      unimplemented: GRPC::Unimplemented,
      internal: GRPC::Internal,
      unavailable: GRPC::Unavailable,
      data_loss: GRPC::DataLoss
    }.freeze

    attr_accessor :code, :app_code, :message, :field_errors, :debug_info, :grpc_error
    attr_reader :metadata

    ##
    # Initialize the error, setting default values
    #
    def initialize(args = {})
      args.each do |k, v|
        send("#{k.to_sym}=", v) if respond_to?(k.to_sym)
      end
      @field_errors = []
    end

    ##
    # Add a field error to this error package
    #
    # @param [Symbol] field_name
    # @param [Symbol] error_code
    # @param [String] message
    #
    def add_field_error(field_name, error_code, message = '')
      @field_errors << Errors::Field.new(field_name, error_code, message)
    end

    ##
    # @param [String] detail
    # @param [Array<String>] stack_trace
    #
    def set_debug_info(detail, stack_trace = [])
      @debug_info = Errors::DebugInfo.new(detail, stack_trace)
    end

    ##
    # Ensure all metadata values are strings
    #
    def metadata=(md)
      @metadata = md.map { |k, str| [k, str.to_s] }.to_h
    end

    ##
    # Serialize the error for transport
    #
    # @return [String]
    #
    def serialize
      serializer = serializer_class.new(self)
      serializer.serialize.to_s
    end

    ##
    # @param [GRPC::ActiveCall]
    # @return [Error]
    #
    def attach_to_call(active_call)
      metadata[Gruf.error_metadata_key.to_sym] = serialize if Gruf.append_server_errors_to_trailing_metadata
      if !metadata.empty? && active_call && active_call.respond_to?(:output_metadata)
        active_call.output_metadata.update(metadata)
      end
      self
    end

    ##
    # @param [GRPC::ActiveCall]
    # @return [GRPC::BadStatus]
    #
    def fail!(active_call)
      raise attach_to_call(active_call).grpc_error
    end

    ##
    # @return [Hash]
    #
    def to_h
      {
        code: code,
        app_code: app_code,
        message: message,
        field_errors: field_errors.map(&:to_h),
        debug_info: debug_info.to_h
      }
    end

    ##
    # @return [GRPC::BadStatus]
    #
    def grpc_error
      @grpc_error = grpc_class.new(message, **@metadata)
    end

    private

    ##
    # @return [Gruf::Serializers::Errors::Base]
    #
    def serializer_class
      if Gruf.error_serializer
        Gruf.error_serializer.is_a?(Class) ? Gruf.error_serializer : Gruf.error_serializer.to_s.constantize
      else
        Gruf::Serializers::Errors::Json
      end
    end

    ##
    # @return [Class]
    #
    def grpc_class
      TYPES[code]
    end
  end
end

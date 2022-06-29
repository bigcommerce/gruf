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
  ##
  # Represents a error that can be transformed into a gRPC error and have metadata attached to the trailing headers.
  # This layer acts as an middle layer that can have metadata injection, tracing support, and other functionality
  # not present in the gRPC core.
  #
  class Error
    include Gruf::Loggable

    # @return [Hash<GRPC::BadStatus>] A hash mapping of gRPC BadStatus codes to error symbols
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

    # Default limit on trailing metadata is 8KB. We need to be careful
    # not to overflow this limit, or the response message will never
    # be sent. Instead, resource_exhausted will be thrown.
    MAX_METADATA_SIZE = 7.5 * 1_024
    METADATA_SIZE_EXCEEDED_CODE = 'metadata_size_exceeded'
    METADATA_SIZE_EXCEEDED_MSG = 'Metadata too long, risks exceeding http2 trailing metadata limit.'

    # @!attribute code
    #   @return [Symbol] The given internal gRPC code for the error
    attr_accessor :code
    # @!attribute app_code
    #   @return [Symbol] An arbitrary application code that can be used for logical processing of the error
    #     by the client
    attr_accessor :app_code
    # @!attribute message
    #   @return [String] The error message returned by the server
    attr_accessor :message
    # @!attribute field_errors
    #   @return [Array] An array of field errors that can be returned by the server
    attr_accessor :field_errors
    # @!attribute debug_info
    #   @return [Errors::DebugInfo] A object containing debugging information, such as a stack trace and exception name,
    #     that can be used to debug an given error response. This is sent by the server over the trailing metadata.
    attr_accessor :debug_info
    # @!attribute [w] grpc_error
    #   @return [GRPC::BadStatus] The gRPC BadStatus error object that was generated
    attr_writer :grpc_error
    # @!attribute [r] metadata
    #   @return [Hash] The trailing metadata that was attached to the error
    attr_reader :metadata

    ##
    # Initialize the error, setting default values
    #
    # @param [Hash] args (Optional) An optional hash of arguments that will set fields on the error object
    #
    def initialize(args = {})
      @field_errors = []
      @metadata = {}
      args.each do |k, v|
        send("#{k}=", v) if respond_to?(k)
      end
    end

    ##
    # Add a field error to this error package
    #
    # @param [Symbol] field_name The field name for the error
    # @param [Symbol] error_code The application error code for the error; e.g. :job_not_found
    # @param [String] message The application error message for the error; e.g. "Job not found with ID 123"
    #
    def add_field_error(field_name, error_code, message = '')
      @field_errors << Errors::Field.new(field_name, error_code, message)
    end

    ##
    # Return true if there are any present field errors
    #
    # @return [Boolean] True if the service has any field errors
    #
    def has_field_errors?
      @field_errors.any?
    end

    ##
    # Set the debugging information for the error message
    #
    # @param [String] detail The detailed message generated by the exception
    # @param [Array<String>] stack_trace An array of strings that represents the exception backtrace generated by the
    # service
    #
    def set_debug_info(detail, stack_trace = [])
      @debug_info = Errors::DebugInfo.new(detail, stack_trace)
    end

    ##
    # Ensure all metadata values are strings as HTTP/2 requires string values for transport
    #
    # @param [Hash] metadata The existing metadata hash
    # @return [Hash] The newly set metadata
    #
    def metadata=(metadata)
      @metadata = metadata.transform_values(&:to_s)
    end

    ##
    # Serialize the error for transport
    #
    # @return [String] The serialized error message
    #
    def serialize
      serializer = serializer_class.new(self)
      serializer.serialize.to_s
    end

    ##
    # Update the trailing metadata on the given gRPC call, including the error payload if configured
    # to do so.
    #
    # @param [GRPC::ActiveCall] active_call The marshalled gRPC call
    # @return [Error] Return the error itself after updating metadata on the given gRPC call.
    #                 In the case of a metadata overflow error, we replace the current error with
    #                 a new one that won't cause a low-level http2 error.
    #
    def attach_to_call(active_call)
      metadata[Gruf.error_metadata_key.to_sym] = serialize if Gruf.append_server_errors_to_trailing_metadata
      return self if metadata.empty? || !active_call || !active_call.respond_to?(:output_metadata)

      # Check if we've overflown the maximum size of output metadata. If so,
      # log a warning and replace the metadata with something smaller to avoid
      # resource exhausted errors.
      if metadata.inspect.size > MAX_METADATA_SIZE
        code = METADATA_SIZE_EXCEEDED_CODE
        msg = METADATA_SIZE_EXCEEDED_MSG
        logger.warn "#{code}: #{msg} Original error: #{to_h.inspect}"
        err = Gruf::Error.new(code: :internal, app_code: code, message: msg)
        return err.attach_to_call(active_call)
      end

      active_call.output_metadata.update(metadata)
      self
    end

    ##
    # Fail the current gRPC call with the given error, properly attaching it to the call and raising the appropriate
    # gRPC BadStatus code.
    #
    # @param [GRPC::ActiveCall] active_call The marshalled gRPC call
    # @return [GRPC::BadStatus] The gRPC BadStatus code this error is mapped to
    #
    def fail!(active_call)
      raise attach_to_call(active_call).grpc_error
    end

    ##
    # Return the error represented in Hash form
    #
    # @return [Hash] The error as a hash
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
    # Return the appropriately mapped GRPC::BadStatus error object for this error
    #
    # @return [GRPC::BadStatus]
    #
    def grpc_error
      md = @metadata || {}
      @grpc_error = grpc_class.new(message, **md)
    end

    private

    ##
    # Return the error serializer being used for gruf
    #
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
    # Return the appropriate gRPC class for the given error code
    #
    # @return [Class] The gRPC error class
    #
    def grpc_class
      TYPES[code]
    end
  end
end

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
  class Client < SimpleDelegator
    ##
    # Translates exceptions into Gruf::Client::Errors
    #
    class ErrorFactory
      ##
      # @param [Class] default_class
      # @param [Class] deserializer_class
      # @param [String|Symbol] metadata_key
      #
      def initialize(
        default_class: nil,
        deserializer_class: nil,
        metadata_key: nil
      )
        @default_class = default_class || Gruf::Client::Errors::Internal
        @metadata_key = (metadata_key || Gruf.error_metadata_key).to_s
        default_serializer = if Gruf.error_serializer
                               Gruf.error_serializer.is_a?(Class) ? Gruf.error_serializer : Gruf.error_serializer.to_s.constantize
                             else
                               Gruf::Serializers::Errors::Json
                             end
        @deserializer_class = deserializer_class || default_serializer
      end

      ##
      # Determine the proper error class to raise given the incoming exception. This will attempt to coalesce the
      # exception object into the appropriate Gruf::Client::Errors subclass, or fallback to the default class if none
      # is found (or it is a StandardError or higher-level error). It will leave alone Signals instead of attempting to
      # coalesce them.
      #
      # @param [Exception] exception
      # @return [Gruf::Client::Errors::Base|SignalException]
      #
      def from_exception(exception)
        # passthrough on Signals, we don't want to mess with these
        return exception if exception.is_a?(SignalException)

        exception_class = determine_class(exception)
        if exception.is_a?(GRPC::BadStatus)
          # if it's a GRPC::BadStatus code, let's check for any trailing error metadata and decode it
          exception_class.new(deserialize(exception))
        else
          # otherwise, let's just capture the error and build the wrapper class
          exception_class.new(exception)
        end
      end

      private

      ##
      # Deserialize any trailing metadata error payload from the exception
      #
      # @param [Gruf::Client::Errors::Base]
      # @return [String]
      #
      def deserialize(exception)
        if exception.respond_to?(:metadata)
          key = exception.metadata.key?(@metadata_key.to_s) ? @metadata_key.to_s : @metadata_key.to_sym
          return @deserializer_class.new(exception.metadata[key]).deserialize if exception.metadata.key?(key)
        end

        exception
      end

      ##
      # @param [Exception] exception
      # @return [Gruf::Client::Errors::Base]
      #
      def determine_class(exception)
        error_class = Gruf::Client::Errors.const_get(exception.class.name.demodulize)

        # Ruby module inheritance will have StandardError, ScriptError, etc still get to this point
        # So we need to explicitly check for ancestry here
        return @default_class unless error_class.ancestors.include?(Gruf::Client::Errors::Base)

        error_class
      rescue NameError => _
        @default_class
      end
    end
  end
end

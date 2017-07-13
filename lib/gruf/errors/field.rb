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
  module Errors
    ##
    # Represents a field-specific error
    #
    class Field
      # @return [Symbol] The name of the field as a Symbol
      attr_reader :field_name
      # @return [Symbol] The application error code for the field, e.g. :job_not_found
      attr_reader :error_code
      # @return [String] The error message for the field, e.g. "Job with ID 123 not found"
      attr_reader :message

      ##
      # @param [Symbol] field_name The name of the field as a Symbol
      # @param [Symbol] error_code The application error code for the field, e.g. :job_not_found
      # @param [String] message (Optional) The error message for the field, e.g. "Job with ID 123 not found"
      #
      def initialize(field_name, error_code, message = '')
        @field_name = field_name
        @error_code = error_code
        @message = message
      end

      ##
      # Return the field error represented as a hash
      #
      # @return [Hash] The error represented as a hash
      #
      def to_h
        {
          field_name: field_name,
          error_code: error_code,
          message: message
        }
      end
    end
  end
end

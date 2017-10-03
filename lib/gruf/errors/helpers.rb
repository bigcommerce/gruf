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
    module Helpers
      delegate :add_field_error, :set_debug_info, :has_field_errors?, to: :error

      ##
      # Will issue a GRPC BadStatus exception, with a code based on the code passed.
      #
      # @param [Symbol] error_code The network error code that maps to gRPC status codes
      # @param [Symbol] app_code The application-specific code for the error
      # @param [String] message (Optional) A detail message about the error
      # @param [Hash] metadata (Optional) Any metadata to inject into the trailing metadata for the response
      #
      def fail!(error_code, app_code = nil, message = '', metadata = {})
        e = error
        e.code = error_code.to_sym
        e.app_code = app_code ? app_code.to_sym : e.code
        e.message = message.to_s
        e.metadata = metadata
        e.fail!(request.active_call)
      end
    end
  end
end

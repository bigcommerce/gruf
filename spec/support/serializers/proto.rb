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
module Serializers
  ##
  # Serialize the errors into a Proto file. Requires test error classes.
  #
  class Proto < Gruf::Serializers::Errors::Base
    ##
    # Serialize the error into a string format
    #
    # @return [String]
    #
    def serialize
      header.to_proto
    end

    ##
    # @return [Gruf::Core::ErrorHeader]
    #
    def deserialize
      Google::Protobuf.decode(::Gruf::ErrorHeader, error)
    end

    ##
    # @return [Gruf::Core::ErrorHeader]
    #
    def header
      data = {
        error_code: error.app_code.to_s,
        error_message: error.message.to_s
      }
      data[:field_errors] = []
      error.field_errors.each do |fe|
        data[:field_errors] << Gruf::FieldError.new(
          field_name: fe.field_name.to_s,
          error_code: fe.error_code.to_s,
          error_message: fe.message.to_s
        )
      end
      if error.debug_info
        st = error.debug_info.stack_trace
        data[:debug_info] = Gruf::DebugInfo.new(
          detail: error.debug_info.detail.to_s,
          stack_trace: st.is_a?(String) ? st.split("\n") : st.map(&:to_s)
        )
      end
      Gruf::ErrorHeader.new(data)
    end
  end
end

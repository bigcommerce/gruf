# Copyright (c) 2017, BigCommerce Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 3. All advertising materials mentioning features or use of this software
# must display the following acknowledgement:
# This product includes software developed by BigCommerce Inc.
# 4. Neither the name of BigCommerce Inc. nor the
# names of its contributors may be used to endorse or promote products
# derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY BIGCOMMERCE INC ''AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL BIGCOMMERCE INC BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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

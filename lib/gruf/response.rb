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
  # Wraps the active call operation to provide metadata and timing around the request
  #
  class Response
    attr_reader :operation, :metadata, :trailing_metadata, :deadline, :cancelled, :execution_time

    ##
    # @param [GRPC::ActiveCall::Operation] op
    # @param [Float] execution_time
    #
    def initialize(op, execution_time = 0.0)
      @operation = op
      @message = op.execute
      @metadata = op.metadata
      @trailing_metadata = op.trailing_metadata
      @deadline = op.deadline
      @cancelled = op.cancelled?
      @execution_time = execution_time
    end

    ##
    # Return the message returned by the request
    #
    def message
      @message ||= op.execute
    end

    ##
    # Return execution time of the call internally on the server in ms
    #
    # @return [Integer]
    #
    def internal_execution_time
      trailing_metadata[Gruf.internal_timer_metadata_key].to_f
    end
  end
end

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
  # Wraps the active call operation to provide metadata and timing around the request
  #
  class Response
    attr_reader :operation, :metadata, :trailing_metadata, :deadline, :cancelled, :execution_time

    ##
    # @param [GRPC::ActiveCall::Operation] op
    # @param [Float] execution_time
    #
    def initialize(op, execution_time = nil)
      @operation = op
      @message = op.execute
      @metadata = op.metadata
      @trailing_metadata = op.trailing_metadata
      @deadline = op.deadline
      @cancelled = op.cancelled?
      @execution_time = execution_time || 0.0
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
      key = Gruf.instrumentation_options.fetch(:output_metadata_timer, {}).fetch(:metadata_key, 'timer')
      trailing_metadata[key].to_f
    end
  end
end

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
    # @return [GRPC::ActiveCall::Operation] The operation that was executed for the given request
    attr_reader :operation
    # @return [Hash] The metadata that was attached to the operation
    attr_reader :metadata
    # @return [Hash] The trailing metadata that the service returned
    attr_reader :trailing_metadata
    # @return [Time] The set deadline on the call
    attr_reader :deadline
    # @return [Boolean] Whether or not the operation was cancelled
    attr_reader :cancelled
    # @return [Float] The time that the request took to execute
    attr_reader :execution_time

    ##
    # Initialize a response object with the given gRPC operation
    #
    # @param [GRPC::ActiveCall::Operation] operation The given operation for the current call
    # @param [StdClass] message
    # @param [Float] execution_time The amount of time that the response took to occur
    #
    def initialize(operation:, message:, execution_time: nil)
      @operation = operation
      @message = message
      @metadata = operation.metadata
      @trailing_metadata = operation.trailing_metadata
      @deadline = operation.deadline
      @cancelled = operation.cancelled?
      @execution_time = execution_time || 0.0
    end

    ##
    # Return the message returned by the request
    #
    # @return [Object] The protobuf response message
    #
    def message
      @message ||= @operation.execute
    end

    ##
    # Return execution time of the call internally on the server in ms
    #
    # @return [Float] The execution time of the response
    #
    def internal_execution_time
      trailing_metadata['timer'].to_f
    end
  end
end

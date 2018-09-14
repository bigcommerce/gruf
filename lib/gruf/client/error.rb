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
    # Represents an error that was returned from the server's trailing metadata. Used as a custom exception object
    # that is instead raised in the case of the service returning serialized error data, as opposed to the normal
    # GRPC::BadStatus error
    #
    class Error < StandardError
      # @return [Object] error The deserialized error
      attr_reader :error

      ##
      # Initialize the client error
      #
      # @param [Object] error The deserialized error
      #
      def initialize(error)
        @error = error
      end
    end

    ##
    # See https://github.com/grpc/grpc-go/blob/master/codes/codes.go for a detailed summary of each error type
    #
    module Errors
      class Base < Gruf::Client::Error; end
      class Error < Base; end
      class Validation < Base; end

      class Ok < Base; end

      class InvalidArgument < Validation; end
      class NotFound < Validation; end
      class AlreadyExists < Validation; end
      class OutOfRange < Validation; end

      class Cancelled < Error; end
      class DataLoss < Error; end
      class DeadlineExceeded < Error; end
      class FailedPrecondition < Error; end
      class Internal < Error; end
      class PermissionDenied < Error; end
      class Unauthenticated < Error; end
      class Unavailable < Error; end
      class Unimplemented < Error; end
      class Unknown < Error; end
    end
  end
end

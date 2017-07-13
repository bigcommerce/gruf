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
  module Serializers
    module Errors
      ##
      # Base class for serialization of errors for transport across the grpc protocol
      #
      class Base
        # @return [Gruf::Error|String] The error being serialized
        attr_reader :error

        ##
        # @param [Gruf::Error|String] err The error to serialize
        #
        def initialize(err)
          @error = err
        end

        ##
        # Must be implemented in a derived class. This method should serialize the error into a transportable String
        # that can be pushed into GRPC metadata across the wire.
        #
        # @return [String] The serialized error
        #
        def serialize
          raise NotImplementedError
        end

        ##
        # Must be implemented in a derived class. This method should deserialize the error object that is transported
        # over the gRPC trailing metadata payload.
        #
        # @return [Object|Hash] The deserialized error object
        #
        def deserialize
          raise NotImplementedError
        end
      end
    end
  end
end

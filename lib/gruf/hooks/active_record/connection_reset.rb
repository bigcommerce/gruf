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
  module Hooks
    module ActiveRecord
      ##
      # Resets the ActiveRecord connection to maintain accurate connected state in the thread pool
      #
      class ConnectionReset < Gruf::Hooks::Base
        ##
        # Reset any ActiveRecord connections after a gRPC service is called. Because of the way gRPC manages its
        # connection pool, we need to ensure that this is done to properly
        #
        # @param [Boolean] _success Whether or not the call was successful
        # @param [Object] _response The protobuf response object
        # @param [Symbol] _call_signature The gRPC method on the service that was called
        # @param [Object] _request The protobuf request object
        # @param [GRPC::ActiveCall] _call the gRPC core active call object, which represents marshalled data for
        # the call itself
        #
        def after(_success, _response, _call_signature, _request, _call)
          ::ActiveRecord::Base.clear_active_connections! if enabled?
        end

        private

        ##
        # @return [Boolean] If AR is loaded, we can enable this hook safely
        #
        def enabled?
          defined?(::ActiveRecord::Base)
        end
      end
    end
  end
end

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
module Gruf
  module Interceptors
    module ActiveRecord
      ##
      # Resets the ActiveRecord connection to maintain accurate connected state in the thread pool
      #
      class ConnectionReset < ::Gruf::Interceptors::ServerInterceptor
        ##
        # Reset any ActiveRecord connections after a gRPC service is called. Because of the way gRPC manages its
        # connection pool, we need to ensure that this is done properly
        #
        def call
          yield
        ensure
          if enabled?
            target_classes.each do |klass|
              klass.connection_handler.clear_active_connections!(::ActiveRecord::Base.current_role)
            end
          end
        end

        private

        ##
        # @return [Boolean] If AR is loaded, we can enable this hook safely
        #
        def enabled?
          defined?(::ActiveRecord::Base)
        end

        ##
        # @return [Array<Class>] The list of ActiveRecord classes to reset
        #
        def target_classes
          options[:target_classes] || [::ActiveRecord::Base]
        end
      end
    end
  end
end

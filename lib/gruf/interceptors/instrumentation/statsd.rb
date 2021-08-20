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
    module Instrumentation
      ##
      # Adds increment and timing stats to gRPC routes, pushing data to StatsD
      #
      class Statsd < Gruf::Interceptors::ServerInterceptor
        ##
        # Push data to StatsD, only doing so if a client is set
        #
        def call(&block)
          unless client
            Gruf.logger.error 'Statsd module loaded, but no client configured!'
            return yield
          end

          client.increment(route_key)

          result = Gruf::Interceptors::Timer.time(&block)

          client.increment("#{route_key}.#{postfix(result.successful?)}")
          client.timing(route_key, result.elapsed)

          raise result.message unless result.successful?

          result.message
        end

        private

        ##
        # @param [Boolean] successful Whether or not the request was successful
        # @return [String] The appropriate postfix for the key dependent on response status
        #
        def postfix(successful)
          successful ? 'success' : 'failure'
        end

        ##
        # @return [String] Return a composed route key that is used in the statsd metric
        #
        def route_key
          "#{key_prefix}#{request.method_name}"
        end

        ##
        # @return [String] Return the sanitized key prefix for the statsd metric key
        #
        def key_prefix
          prefix = options.fetch(:prefix, '').to_s
          prefix.empty? ? '' : "#{prefix}."
        end

        ##
        # @return [::Statsd] Return the given StatsD client
        # @return [NilClass]
        #
        def client
          @client ||= options.fetch(:client, nil)
        end
      end
    end
  end
end

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
  module Instrumentation
    ##
    # Adds increment and timing stats to gRPC routes, pushing data to StatsD
    #
    class Statsd < Gruf::Instrumentation::Base
      ##
      # Push data to StatsD, only doing so if a client is set
      #
      # @param [Gruf::Instrumentation::RequestContext] rc The current request context for the call
      #
      def call(rc)
        if client
          rk = route_key(rc.call_signature)
          client.increment(rk)
          client.increment("#{rk}.#{postfix(rc.success?)}")
          client.timing(rk, rc.execution_time)
        else
          Gruf.logger.error 'Statsd module loaded, but no client configured!'
        end
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
      # @param [Symbol] call_signature The method call signature for the handler
      # @return [String] Return a composed route key that is used in the statsd metric
      #
      def route_key(call_signature)
        "#{key_prefix}#{method_key(call_signature)}"
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
      #
      def client
        @client ||= options.fetch(:client, nil)
      end

      ##
      # @return [Hash] Return a hash of options for this hook
      #
      def options
        super().fetch(:statsd, {})
      end
    end
  end
end

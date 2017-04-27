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
  module Instrumentation
    ##
    # Adds increment and timing stats to gRPC routes, pushing data to StatsD
    #
    class Statsd < Gruf::Instrumentation::Base
      ##
      # Push data to StatsD, only doing so if a client is set
      #
      def call
        if client
          client.increment(route_key)
          client.timing(route_key, execution_time)
        else
          Gruf.logger.error 'Statsd module loaded, but no client configured!'
        end
      end

      private

      ##
      # @return [String]
      #
      def route_key
        "#{key_prefix}#{service_key}.#{call_signature}"
      end

      ##
      # @return [String]
      #
      def service_key
        service.class.name.underscore.gsub('/','.')
      end

      ##
      # @return [String]
      #
      def key_prefix
        prefix = options.fetch(:prefix, '').to_s
        prefix.empty? ? '' : "#{prefix}."
      end

      ##
      # @return [::Statsd]
      #
      def client
        @client ||= options.fetch(:client, nil)
      end

      ##
      # @return [Hash]
      #
      def options
        @options.fetch(:statsd, {})
      end
    end
  end
end

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
require_relative 'authentication/strategies'
require_relative 'authentication/base'
require_relative 'authentication/basic'
require_relative 'authentication/none'

module Gruf
  module Authentication
    class UnauthorizedError < StandardError; end

    ##
    # @param [GRPC::ActiveCall] call
    # @param [Symbol] strategy The authentication strategy to use
    # @return [Boolean]
    #
    def self.verify(call)
      credentials = call && call.respond_to?(:metadata) ? call.metadata[Gruf.authorization_metadata_key] : nil

      if Gruf::Authentication::Strategies.any?
        verified = false
        Gruf::Authentication::Strategies.each do |_label, klass|
          begin
            # if a strategy passes, we've successfully authenticated and can proceed
            if klass.verify(call, credentials)
              verified = true
              break
            end
          rescue => e
            Gruf.logger.error "#{e.message} - #{e.backtrace[0..4].join("\n")}"
            # NOOP, we don't want to fail other strategies because of a bad neighbor
            # or if a strategy throws an exception because of a failed auth
            # we should just proceed to the next strategy
          end
        end
        verified
      else
        # we're not using any strategies, so no auth
        true
      end
    rescue
      false
    end
  end
end

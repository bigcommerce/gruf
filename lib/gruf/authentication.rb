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
require_relative 'authentication/strategies'
require_relative 'authentication/base'
require_relative 'authentication/basic'
require_relative 'authentication/none'

module Gruf
  ##
  # Handles authentication for gruf services
  #
  module Authentication
    ##
    # Custom error class for handling unauthorized requests
    #
    class UnauthorizedError < StandardError; end

    ##
    # Verify a given gruf request
    #
    # @param [GRPC::ActiveCall] call The gRPC active call with marshalled data that is being executed
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
    end
  end
end

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
require 'base64'

module Gruf
  module Interceptors
    module Authentication
      ##
      # Handles basic authentication for gRPC requests
      #
      class Basic < Gruf::Interceptors::ServerInterceptor
        ##
        # Validate authentication
        #
        def call
          fail!(:unauthenticated, :unauthenticated) unless bypass? || valid?
          yield
        end

        private

        ##
        # @return [Boolean] If this method is in the excluded list, bypass
        #
        def bypass?
          options.fetch(:excluded_methods, []).include?(request.method_name)
        end

        ##
        # @return [Boolean] True if the basic authentication was valid
        #
        def valid?
          server_credentials.any? do |cred|
            username = cred.fetch(:username, '').to_s
            password = cred.fetch(:password, '').to_s
            if username.empty?
              request_password == password
            else
              request_credentials == "#{username}:#{password}"
            end
          end
        end

        ##
        # @return [Array<Hash>] An array of valid server credentials for this service
        #
        def server_credentials
          options.fetch(:credentials, [])
        end

        ##
        # @return [String] The decoded request credentials
        #
        def request_credentials
          credentials = if request.active_call.respond_to?(:metadata)
                          request.active_call.metadata['authorization'].to_s
                        else
                          ''
                        end
          Base64.decode64(credentials.to_s.gsub('Basic ', '').strip)
        end

        ##
        # @return [String] The decoded request password
        #
        def request_password
          @request_password ||= request_credentials.split(':').last
        end
      end
    end
  end
end

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
require 'base64'

module Gruf
  module Authentication
    ##
    # Handles basic authentication for gRPC requests
    #
    class Basic < Base
      ##
      # @param [GRPC::ActiveCall] _call
      # @return [Boolean]
      #
      def valid?(_call)
        server_credentials.any? do |cred|
          username = cred.fetch(:username, '').to_s
          password = cred.fetch(:password, '').to_s
          if username.empty?
            request_password == password
          else
            "#{username}:#{password}" == request_credentials
          end
        end
      end

      private

      ##
      # @return [Array<Hash>]
      #
      def server_credentials
        options.fetch(:credentials, [])
      end

      ##
      # @return [String]
      #
      def request_credentials
        Base64.decode64(credentials.to_s.gsub('Basic ', '').strip)
      end

      ##
      # @return [String]
      # @deprecated
      # :nocov:
      def request_username
        @request_username ||= request_credentials.split(':').first
      end
      # :nocov:

      ##
      # @return [String]
      #
      def request_password
        @request_password ||= request_credentials.split(':').last
      end
    end
  end
end

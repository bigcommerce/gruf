# Copyright (c) 2017, BigCommerce Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 3. All advertising materials mentioning features or use of this software
# must display the following acknowledgement:
# This product includes software developed by BigCommerce Inc.
# 4. Neither the name of BigCommerce Inc. nor the
# names of its contributors may be used to endorse or promote products
# derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY BIGCOMMERCE INC ''AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL BIGCOMMERCE INC BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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

      def server_credentials
        options.fetch(:credentials, [])
      end

      ##
      # @return [String]
      #
      def server_credentials_old
        prefix = username.empty? ? '' : "#{username}:"
        Base64.encode64("#{prefix}#{password}").strip
      end

      def request_credentials
        Base64.decode64(credentials.to_s.gsub('Basic ', '').strip)
      end

      def request_username
        @request_username ||= request_credentials.split(':').first
      end

      def request_password
        @request_password ||= request_credentials.split(':').last
      end
    end
  end
end

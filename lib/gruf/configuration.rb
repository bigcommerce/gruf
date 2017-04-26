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
module Gruf
  ##
  # Represents configuration settings for the system
  #
  module Configuration
    VALID_CONFIG_KEYS = {
      root_path: '',
      server_binding_url: '0.0.0.0:9001',
      authentication: :none, # deprecated
      authentication_options: {},
      default_client_host: '',
      use_ssl: false,
      ssl_crt_file: '',
      ssl_key_file: '',
      servers_path: '',
      services: [],
      logger: nil,
      error_metadata_key: :'error-internal-bin',
      error_serializer: nil,
      authorization_metadata_key: 'authorization',
      internal_timer_metadata_key: 'timer',
      append_server_errors_to_trailing_metadata: true,
      use_default_hooks: true
    }.freeze

    attr_accessor *VALID_CONFIG_KEYS.keys

    ##
    # Whenever this is extended into a class, setup the defaults
    #
    def self.extended(base)
      base.reset
    end

    ##
    # Yield self for ruby-style initialization
    #
    # @yields [Gruf::Configuration]
    # @return [Gruf::Configuration]
    #
    def configure
      yield self
    end

    ##
    # Return the current configuration options as a Hash
    #
    # @return [Hash]
    #
    def options
      opts = {}
      VALID_CONFIG_KEYS.each do |k, v|
        opts.merge!(k => send(k))
      end
      opts
    end

    ##
    # Set the default configuration onto the extended class
    #
    # @return [Hash] options The reset options hash
    #
    def reset
      VALID_CONFIG_KEYS.each do |k, v|
        self.send((k.to_s+'=').to_sym, v)
      end
      if defined?(Rails)
        self.root_path = Rails.root
        self.logger = Rails.logger
      else
        require 'logger'
        self.logger = ::Logger.new(STDOUT)
      end
      self.ssl_crt_file = "#{self.root_path}/config/ssl/#{environment}.crt"
      self.ssl_key_file = "#{self.root_path}/config/ssl/#{environment}.key"
      self.servers_path = "#{self.root_path}/app/rpc"
      self.authentication_options = {
        credentials: [{
          username: 'grpc',
          password: 'magic'
        }]
      }
      if self.use_default_hooks
        Gruf::Hooks::Registry.add(:ar_connection_reset, Gruf::Hooks::ActiveRecord::ConnectionReset)
      end
      options
    end

    private

    ##
    # Automatically determine environment
    #
    # @return [String]
    #
    def environment
      if defined?(Rails)
        Rails.env.to_s
      else
        (ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development').to_s
      end
    end
  end
end

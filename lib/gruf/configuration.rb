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
  ##
  # Represents configuration settings for the system
  #
  module Configuration
    VALID_CONFIG_KEYS = {
      root_path: '',
      server_binding_url: '0.0.0.0:9001',
      authentication_options: {},
      instrumentation_options: {},
      hook_options: {},
      default_client_host: '',
      use_ssl: false,
      ssl_crt_file: '',
      ssl_key_file: '',
      servers_path: '',
      services: [],
      logger: nil,
      grpc_logger: nil,
      error_metadata_key: :'error-internal-bin',
      error_serializer: nil,
      authorization_metadata_key: 'authorization',
      append_server_errors_to_trailing_metadata: true,
      use_default_hooks: true,
      backtrace_on_error: false,
      use_exception_message: true,
      internal_error_message: 'Internal Server Error'
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
    # @yields [Gruf::Configuration] The configuration object for gruf
    # @return [Gruf::Configuration] The configuration object for gruf
    #
    def configure
      yield self
    end

    ##
    # Return the current configuration options as a Hash
    #
    # @return [Hash] The configuration for gruf, represented as a Hash
    #
    def options
      opts = {}
      VALID_CONFIG_KEYS.each do |k, _v|
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
        send((k.to_s + '=').to_sym, v)
      end
      if defined?(Rails) && Rails.logger
        self.root_path = Rails.root
        self.logger = Rails.logger
      else
        require 'logger'
        self.logger = ::Logger.new(STDOUT)
      end
      self.grpc_logger = logger if grpc_logger.nil?
      self.ssl_crt_file = "#{root_path}/config/ssl/#{environment}.crt"
      self.ssl_key_file = "#{root_path}/config/ssl/#{environment}.key"
      self.servers_path = "#{root_path}/app/rpc"
      self.authentication_options = {
        credentials: [{
          username: 'grpc',
          password: 'magic'
        }]
      }
      if use_default_hooks
        Gruf::Hooks::Registry.add(:ar_connection_reset, Gruf::Hooks::ActiveRecord::ConnectionReset)
        Gruf::Instrumentation::Registry.add(:output_metadata_timer, Gruf::Instrumentation::OutputMetadataTimer)
      end
      options
    end

    private

    ##
    # Automatically determine environment
    #
    # @return [String] The current Ruby environment
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

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
  ##
  # Represents configuration settings for the system
  #
  module Configuration
    # @!attribute root_path
    #   @return [String] The root path for your application
    # @!attribute server_binding_url
    #   @return [String] The full hostname:port that the gRPC server should bind to
    # @!attribute server_options
    #   @return [Hash] A hash of options to pass to the server instance
    # @!attribute interceptors
    #   @return [::Gruf::Interceptors::Registry] A registry of Gruf server interceptors
    # @!attribute hooks
    #   @return [::Gruf::Hooks::Registry] A registry of Gruf hooks for the server
    # @!attribute default_channel_credentials
    #   @return [NilClass]
    #   @return [Symbol]
    #   @return [Hash]
    # @!attribute default_client_host
    #   @return [String] The default host for all new Gruf::Client objects to use as their target host
    # @!attribute use_ssl
    #   @return [Boolean] If true, will setup the server to use TLS
    # @!attribute ssl_crt_file
    #   @return [String] If use_ssl is true, the relative path from the root_path to the CRT file for the server
    # @!attribute ssl_key_file
    #   @return [String] If use_ssl is true, the relative path from the root_path to the key file for the server
    # @!attribute controllers_path
    #   @return [String] The relative path from root_path to locate Gruf Controllers in
    # @!attribute services
    #   @return [Array<Class>] An array of services to serve with this Gruf server
    # @!attribute logger
    #   @return [Logger] The logger class for Gruf-based logging
    # @!attribute grpc_logger
    #   @return [Logger] The logger to use with GRPC's core logger (which logs plaintext). It is recommended to set
    #      this to an STDOUT logger and use a logging pipeline that can translate plaintext logs given GRPC's
    #      unformatted logging.
    # @!attribute error_metadata_key
    #   @return [Symbol] The metadata key to use for error messages sent back in trailing metadata.
    # @!attribute error_serializer
    #   @return [NilClass|::Gruf::Serializers::Errors::Base] The error serializer to use for error messages sent
    #      back in trailing metadata. Defaults to the base JSON serializer.
    # @!attribute append_server_errors_to_trailing_metadata
    #   @return [Boolean] If true, will append all server error information into the trailing metadata in the response
    #      from the server
    # @!attribute use_default_interceptors
    #   @return [Boolean] If true, will use the default ActiveRecord and Timer interceptors for servers
    # @!attribute backtrace_on_error
    #   @return [Boolean] If true, will return the backtrace on any errors in servers in the trailing metadata
    # @!attribute backtrace_limit
    #   @return [Integer] The limit of lines to use in backtraces returned
    # @!attribute use_exception_message
    #   @return [String] If true, will pass the actual exception message from the error in a server
    # @!attribute internal_error_message
    #   @return [String] If use_exception_message is false, this message will be used instead as a replacement
    # @!attribute event_listener_proc
    #   @return [NilClass]
    #   @return [Proc] If set, this will be used during GRPC events (such as pool exhaustions)
    # @!attribute synchronized_client_internal_cache_expiry
    #   @return [Integer] Internal cache expiry period (in seconds) for the SynchronizedClient
    # @!attribute rpc_server_options
    #   @return [Hash] A hash of RPC options for GRPC server configuration
    # @!attribute health_check_enabled
    #   @return [Boolean] If true, will load and register `Gruf::Controllers::HealthController` with the default gRPC
    #     health check to the loaded gRPC server
    # @!attribute health_check_hook
    #   @return [NilClass]
    #   @return [Proc] If set, will call this in the gRPC health check. It is required to return a
    #     `::Grpc::Health::V1::HealthCheckResponse` object in this proc to indicate the health of the server.
    VALID_CONFIG_KEYS = {
      root_path: '',
      server_binding_url: '0.0.0.0:9001',
      server_options: {},
      interceptors: nil,
      hooks: nil,
      default_channel_credentials: nil,
      default_client_host: '0.0.0.0:9001',
      use_ssl: false,
      ssl_crt_file: '',
      ssl_key_file: '',
      controllers_path: '',
      services: [],
      logger: nil,
      grpc_logger: nil,
      error_metadata_key: :'error-internal-bin',
      error_serializer: nil,
      append_server_errors_to_trailing_metadata: true,
      use_default_interceptors: true,
      backtrace_on_error: false,
      backtrace_limit: 10,
      use_exception_message: true,
      internal_error_message: 'Internal Server Error',
      event_listener_proc: nil,
      health_check_enabled: false,
      health_check_hook: nil,
      synchronized_client_internal_cache_expiry: 60,
      rpc_server_options: {
        pool_size: GRPC::RpcServer::DEFAULT_POOL_SIZE,
        max_waiting_requests: GRPC::RpcServer::DEFAULT_MAX_WAITING_REQUESTS,
        poll_period: GRPC::RpcServer::DEFAULT_POLL_PERIOD,
        pool_keep_alive: GRPC::Pool::DEFAULT_KEEP_ALIVE,
        connect_md_proc: nil,
        server_args: {}
      }.freeze
    }.freeze

    attr_accessor(*VALID_CONFIG_KEYS.keys)

    ##
    # Whenever this is extended into a class, setup the defaults
    #
    def self.extended(base)
      if defined?(::Rails)
        ::Gruf::Integrations::Rails::Railtie.config.before_initialize { base.reset }
      else
        base.reset
      end
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
      VALID_CONFIG_KEYS.each_key do |k|
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
        send(:"#{k}=", v)
      end
      self.server_binding_url = "#{::ENV.fetch('GRPC_SERVER_HOST',
                                               '0.0.0.0')}:#{::ENV.fetch('GRPC_SERVER_PORT', 9_001)}"
      self.interceptors = ::Gruf::Interceptors::Registry.new
      self.hooks = ::Gruf::Hooks::Registry.new
      self.root_path = ::Rails.root.to_s.chomp('/') if defined?(::Rails)
      determine_loggers
      self.ssl_crt_file = "#{root_path}config/ssl/#{environment}.crt"
      self.ssl_key_file = "#{root_path}config/ssl/#{environment}.key"
      cp = ::ENV.fetch('GRUF_CONTROLLERS_PATH', 'app/rpc').to_s
      self.controllers_path = root_path.to_s.empty? ? cp : "#{root_path}/#{cp}"
      self.backtrace_on_error = ::ENV.fetch('GRPC_BACKTRACE_ON_ERROR', 0).to_i.positive?
      self.rpc_server_options = {
        max_waiting_requests: ::ENV.fetch('GRPC_SERVER_MAX_WAITING_REQUESTS',
                                          GRPC::RpcServer::DEFAULT_MAX_WAITING_REQUESTS).to_i,
        pool_size: ::ENV.fetch('GRPC_SERVER_POOL_SIZE', GRPC::RpcServer::DEFAULT_POOL_SIZE).to_i,
        pool_keep_alive: ::ENV.fetch('GRPC_SERVER_POOL_KEEP_ALIVE', GRPC::Pool::DEFAULT_KEEP_ALIVE).to_i,
        poll_period: ::ENV.fetch('GRPC_SERVER_POLL_PERIOD', GRPC::RpcServer::DEFAULT_POLL_PERIOD).to_i,
        connect_md_proc: nil,
        server_args: {}
      }
      self.use_default_interceptors = ::ENV.fetch('GRUF_USE_DEFAULT_INTERCEPTORS', 1).to_i.positive?

      if use_default_interceptors
        interceptors.use(::Gruf::Interceptors::ActiveRecord::ConnectionReset)
        interceptors.use(::Gruf::Interceptors::Instrumentation::OutputMetadataTimer)
      end
      self.health_check_enabled = ::ENV.fetch('GRUF_HEALTH_CHECK_ENABLED', 0).to_i.positive?
      options
    end

    ##
    # @return [Boolean]
    #
    def development?
      environment == 'development'
    end

    private

    ##
    # Automatically determine environment
    #
    # @return [String] The current Ruby environment
    #
    def environment
      if defined?(::Rails)
        ::Rails.env.to_s
      else
        ENV.fetch('RACK_ENV') { ENV.fetch('RAILS_ENV', 'development') }.to_s
      end
    end

    ##
    # Dynamically determine the appropriate logger
    #
    def determine_loggers
      if defined?(::Rails) && ::Rails.logger
        self.logger = ::Rails.logger
      else
        require 'logger'
        self.logger = ::Logger.new($stdout)
        log_level = ::ENV.fetch('LOG_LEVEL', 'info').to_s.upcase
        begin
          logger.level = ::Logger::Severity.const_get(log_level)
        rescue NameError => _e
          logger.level = ::Logger::Severity::INFO
        end
      end
      self.grpc_logger = logger if grpc_logger.nil?
    end
  end
end

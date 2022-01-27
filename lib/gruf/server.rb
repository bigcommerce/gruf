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
  # Represents a gRPC server. Automatically loads and augments gRPC handlers and services
  # based on configuration values.
  #
  class Server
    class ServerAlreadyStartedError < StandardError; end

    KILL_SIGNALS = %w[INT TERM QUIT].freeze

    include Gruf::Loggable

    # @!attribute [r] port
    #   @return [Integer] The port the server is bound to
    attr_reader :port
    # @!attribute [r] options
    #   @return [Hash] Hash of options passed into the server
    attr_reader :options

    ##
    # Initialize the server and load and setup the services
    #
    # @param [Hash] opts
    #
    def initialize(opts = {})
      @options = opts || {}
      @interceptors = opts.fetch(:interceptor_registry, Gruf.interceptors)
      @interceptors = Gruf::Interceptors::Registry.new unless @interceptors.is_a?(Gruf::Interceptors::Registry)
      @services = []
      @started = false
      @hostname = opts.fetch(:hostname, Gruf.server_binding_url)
      @event_listener_proc = opts.fetch(:event_listener_proc, Gruf.event_listener_proc)
      setup
    end

    ##
    # @return [GRPC::RpcServer] The GRPC server running
    #
    def server
      @server ||= begin
        # For backward compatibility, we allow these options to be passed directly
        # in the Gruf::Server options, or via Gruf.rpc_server_options.
        server_options = {
          pool_size: options.fetch(:pool_size, Gruf.rpc_server_options[:pool_size]),
          max_waiting_requests: options.fetch(:max_waiting_requests, Gruf.rpc_server_options[:max_waiting_requests]),
          poll_period: options.fetch(:poll_period, Gruf.rpc_server_options[:poll_period]),
          pool_keep_alive: options.fetch(:pool_keep_alive, Gruf.rpc_server_options[:pool_keep_alive]),
          connect_md_proc: options.fetch(:connect_md_proc, Gruf.rpc_server_options[:connect_md_proc]),
          server_args: options.fetch(:server_args, Gruf.rpc_server_options[:server_args])
        }

        server = if @event_listener_proc
                   server_options[:event_listener_proc] = @event_listener_proc
                   Gruf::InstrumentableGrpcServer.new(**server_options)
                 else
                   GRPC::RpcServer.new(**server_options)
                 end

        @port = server.add_http2_port(@hostname, ssl_credentials)
        @services.each { |s| server.handle(s) }
        server
      end
    end

    ##
    # Start the gRPC server
    #
    # :nocov:
    def start!
      update_proc_title(:starting)

      server_thread = Thread.new do
        logger.info { "Starting gruf server at #{@hostname}..." }
        server.run_till_terminated_or_interrupted(KILL_SIGNALS)
      end
      server.wait_till_running
      @started = true
      update_proc_title(:serving)
      server_thread.join
      @started = false

      update_proc_title(:stopped)
      logger.info { 'Goodbye!' }
    end
    # :nocov:

    ##
    # Add a gRPC service stub to be served by gruf
    #
    # @param [Class] klass
    # @raise [ServerAlreadyStartedError] if the server is already started
    #
    def add_service(klass)
      raise ServerAlreadyStartedError if @started

      @services << klass unless @services.include?(klass)
    end

    ##
    # Add an interceptor to the server
    #
    # @param [Class] klass The Interceptor to add to the registry
    # @param [Hash] opts A hash of options for the interceptor
    # @raise [ServerAlreadyStartedError] if the server is already started
    #
    def add_interceptor(klass, opts = {})
      raise ServerAlreadyStartedError if @started

      @interceptors.use(klass, opts)
    end

    ##
    # Insert an interceptor before another in the currently registered order of execution
    #
    # @param [Class] before_class The interceptor that you want to add the new interceptor before
    # @param [Class] interceptor_class The Interceptor to add to the registry
    # @param [Hash] opts A hash of options for the interceptor
    #
    def insert_interceptor_before(before_class, interceptor_class, opts = {})
      raise ServerAlreadyStartedError if @started

      @interceptors.insert_before(before_class, interceptor_class, opts)
    end

    ##
    # Insert an interceptor after another in the currently registered order of execution
    #
    # @param [Class] after_class The interceptor that you want to add the new interceptor after
    # @param [Class] interceptor_class The Interceptor to add to the registry
    # @param [Hash] opts A hash of options for the interceptor
    #
    def insert_interceptor_after(after_class, interceptor_class, opts = {})
      raise ServerAlreadyStartedError if @started

      @interceptors.insert_after(after_class, interceptor_class, opts)
    end

    ##
    # Return the current list of added interceptor classes
    #
    # @return [Array<Class>]
    #
    def list_interceptors
      @interceptors.list
    end

    ##
    # Remove an interceptor from the server
    #
    # @param [Class] klass
    #
    def remove_interceptor(klass)
      raise ServerAlreadyStartedError if @started

      @interceptors.remove(klass)
    end

    ##
    # Clear the interceptor registry of interceptors
    #
    def clear_interceptors
      raise ServerAlreadyStartedError if @started

      @interceptors.clear
    end

    private

    ##
    # Setup server
    #
    # :nocov:
    def setup
      load_controllers
    end
    # :nocov:

    ##
    # Auto-load all gRPC handlers
    #
    # :nocov:
    def load_controllers
      return unless File.directory?(controllers_path)

      path = File.realpath(controllers_path)
      $LOAD_PATH.unshift(path)
      Dir["#{path}/**/*.rb"].each do |f|
        next if f.include?('_pb') # exclude if people include proto generated files in app/rpc

        logger.info "- Loading gRPC service file: #{f}"
        load File.realpath(f)
      end
    end
    # :nocov:

    ##
    # @param [String]
    #
    def controllers_path
      options.fetch(:controllers_path, Gruf.controllers_path)
    end

    ##
    # Load the SSL/TLS credentials for this server
    #
    # @return [GRPC::Core::ServerCredentials|Symbol]
    #
    # :nocov:
    def ssl_credentials
      return :this_port_is_insecure unless options.fetch(:use_ssl, Gruf.use_ssl)

      private_key = File.read(options.fetch(:ssl_key_file, Gruf.ssl_key_file))
      cert_chain = File.read(options.fetch(:ssl_crt_file, Gruf.ssl_crt_file))
      certs = [nil, [{ private_key: private_key, cert_chain: cert_chain }], false]
      GRPC::Core::ServerCredentials.new(*certs)
    end
    # :nocov:

    ##
    # Updates proc name/title
    #
    # @param [Symbol] state
    #
    # :nocov:
    def update_proc_title(state)
      Process.setproctitle("gruf #{Gruf::VERSION} -- #{state}")
    end
    # :nocov:
  end
end

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

    include Gruf::Loggable

    # @return [Integer] The port the server is bound to
    attr_reader :port
    # @return [Hash] Hash of options passed into the server
    attr_reader :options

    ##
    # Initialize the server and load and setup the services
    #
    # @param [Hash] options
    #
    def initialize(options = {})
      @options = options || {}
      @interceptors = options.fetch(:interceptor_registry, Gruf.interceptors)
      @interceptors = Gruf::Interceptors::Registry.new unless @interceptors.is_a?(Gruf::Interceptors::Registry)
      @services = []
      @started = false
      @stop_server = false
      @stop_server_cv = ConditionVariable.new
      @stop_server_mu = Monitor.new
      setup
    end

    ##
    # @return [GRPC::RpcServer] The GRPC server running
    #
    def server
      unless @server
        @server = GRPC::RpcServer.new(options)
        @port = @server.add_http2_port(options.fetch(:hostname, Gruf.server_binding_url), ssl_credentials)
        @services.each { |s| @server.handle(s) }
      end
      @server
    end

    ##
    # Start the gRPC server
    #
    # :nocov:
    def start!
      stop_server_thread = Thread.new do
        loop do
          break if @stop_server
          @stop_server_mu.synchronize { @stop_server_cv.wait(@stop_server_mu, 10) }
        end
        logger.info { 'Shutting down...' }
        server.stop
      end

      logger.info { 'Booting gRPC Server...' }
      @started = true
      server.run
      stop_server_thread.join
      @started = false

      logger.info { 'Goodbye!' }
    end
    # :nocov:

    ##
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
    # @param [Class] before_class The interceptor that you want to add the new interceptor before
    # @param [Class] interceptor_class The Interceptor to add to the registry
    # @param [Hash] options A hash of options for the interceptor
    #
    def insert_interceptor_before(before_class, interceptor_class, options = {})
      raise ServerAlreadyStartedError if @started
      @interceptors.insert_before(before_class, interceptor_class, options)
    end

    ##
    # @param [Class] after_class The interceptor that you want to add the new interceptor after
    # @param [Class] interceptor_class The Interceptor to add to the registry
    # @param [Hash] options A hash of options for the interceptor
    #
    def insert_interceptor_after(after_class, interceptor_class, options = {})
      raise ServerAlreadyStartedError if @started
      @interceptors.insert_after(after_class, interceptor_class, options)
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
      setup_signal_handlers
      load_controllers
    end
    # :nocov:

    ##
    # Register signal handlers
    #
    # :nocov:
    def setup_signal_handlers
      Thread.abort_on_exception = true

      Signal.trap('INT') do
        @stop_server = true
        @stop_server_cv.broadcast
      end

      Signal.trap('TERM') do
        @stop_server = true
        @stop_server_cv.broadcast
      end
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
      if options.fetch(:use_ssl, Gruf.use_ssl)
        private_key = File.read(options.fetch(:ssl_key_file, Gruf.ssl_key_file))
        cert_chain = File.read(options.fetch(:ssl_crt_file, Gruf.ssl_crt_file))
        certs = [nil, [{ private_key: private_key, cert_chain: cert_chain }], false]
        GRPC::Core::ServerCredentials.new(*certs)
      else
        :this_port_is_insecure
      end
    end
    # :nocov:
  end
end

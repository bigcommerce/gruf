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
      setup!
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
    # rubocop:disable Lint/ShadowedException
    def start!
      logger.info { 'Booting gRPC Server...' }
      server.run_till_terminated
    rescue Interrupt, SignalException, SystemExit
      logger.info { 'Shutting down gRPC server...' }
      server.stop
    end
    # :nocov:
    # rubocop:enable Lint/ShadowedException

    ##
    # @param [Class] klass
    #
    def add_service(klass)
      @services << klass unless @services.include?(klass)
    end

    ##
    # Add an interceptor to the server
    #
    # @param [Gruf::Interceptors::Base]
    # @param [Hash]
    #
    def add_interceptor(klass, opts = {})
      @interceptors.use(klass, opts)
    end

    private

    ##
    # Auto-load all gRPC handlers
    #
    # :nocov:
    def setup!
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

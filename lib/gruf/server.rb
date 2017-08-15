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
  # Represents a gRPC server. Automatically loads and augments gRPC handlers and services
  # based on configuration values.
  #
  class Server
    include Gruf::Loggable

    # @return [Array<Class>] The services this server is handling
    attr_accessor :services

    ##
    # Initialize the server and load and setup the services
    #
    # @param [Array<Class>] services The services that this server should handle
    #
    def initialize(services: [])
      setup!
      load_services(services)
    end

    ##
    # Start the gRPC server
    #
    # :nocov:
    def start!
      logger.info { 'Booting gRPC Server...' }
      server = GRPC::RpcServer.new(Gruf.server_options)
      server.add_http2_port Gruf.server_binding_url, ssl_credentials
      services.each do |s|
        server.handle(s)
      end
      server.run_till_terminated
      logger.info { 'Shutting down gRPC server...' }
    end
    # :nocov:

    private

    ##
    # Return all loaded gRPC services
    #
    # @param [Array<Class>] svcs An array of service classes that will be handled by this server
    # @return [Array<Class>] The given services that were added
    #
    def load_services(svcs)
      unless @services
        @services = Gruf.services.concat(svcs)
        @services.uniq!
      end
      @services
    end

    ##
    # Auto-load all gRPC handlers
    #
    # :nocov:
    def setup!
      Dir["#{Gruf.servers_path}/**/*.rb"].each do |f|
        logger.info "- Loading gRPC service file: #{f}"
        require f
      end
    end
    # :nocov:

    ##
    # Load the SSL/TLS credentials for this server
    #
    # @return [GRPC::Core::ServerCredentials|Symbol]
    #
    # :nocov:
    def ssl_credentials
      if Gruf.use_ssl
        private_key = File.read Gruf.ssl_key_file
        cert_chain = File.read Gruf.ssl_crt_file
        certs = [nil, [{ private_key: private_key, cert_chain: cert_chain }], false]
        GRPC::Core::ServerCredentials.new(*certs)
      else
        :this_port_is_insecure
      end
    end
    # :nocov:
  end
end

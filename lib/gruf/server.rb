# Copyright 2017, Bigcommerce Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
# 1. Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
# 3. Neither the name of BigCommerce Inc. nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
module Gruf
  ##
  # Represents a gRPC server. Automatically loads and augments gRPC handlers and services
  # based on configuration values.
  #
  class Server
    include Gruf::Loggable

    attr_accessor :services

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
      server = GRPC::RpcServer.new
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
    # @param [Array<Class>] svcs
    # @return [Array<Class>]
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

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
  class Client < SimpleDelegator
    include Gruf::Loggable

    class Error < StandardError
      attr_reader :error

      def initialize(error)
        @error = error
      end
    end

    attr_reader :base_klass, :service_klass, :opts

    ##
    # @param [Module] service The namespace of the client Stub that is desired to load
    # @param [Hash] options
    # @option options [String] :password The password for basic authentication for the service.
    # @option options [String] :hostname The hostname of the service. Defaults to linkerd.
    #
    def initialize(service:, options: {})
      @base_klass = service
      @service_klass = "#{base_klass}::Service".constantize
      @opts = options || {}
      @opts[:password] = options.fetch(:password, '').to_s
      @opts[:hostname] = options.fetch(:hostname, Gruf.default_client_host)
      client = "#{service}::Stub".constantize.new(@opts[:hostname], build_ssl_credentials)
      super(client)
    end

    ##
    # Call the client's method with given params
    #
    def call(request_method, params = {}, metadata = {})
      req = request_object(request_method, params)
      md = build_metadata(metadata)
      call_signature = call_signature(request_method)
      if call_signature
        begin
          timed = Timer.time do
            self.send(call_signature, req, return_op: true, metadata: md)
          end
          Gruf::Response.new(timed.result, timed.time)
        rescue GRPC::BadStatus => e
          emk = Gruf.error_metadata_key.to_s
          if e.respond_to?(:metadata) && e.metadata.key?(emk)
            raise Gruf::Client::Error, error_deserializer_class.new(e.metadata[emk]).deserialize
          else
            raise # passthrough
          end
        end
      else
        raise NotImplementedError.new("The method #{request_method} has not been implemented in this service.")
      end
    end

    private

    ##
    # @return [Struct<GRPC::RpcDesc>]
    #
    def rpc_desc(request_method)
      service_klass.rpc_descs[request_method.to_sym]
    end

    ##
    # @return [Class] The request object
    #
    def request_object(request_method, params = {})
      desc = rpc_desc(request_method)
      if desc && desc.input
        desc.input.new(params)
      else
        nil
      end
    end

    ##
    # @return [Symbol]
    #
    def call_signature(request_method)
      desc = rpc_desc(request_method)
      desc && desc.name ? desc.name.to_s.underscore.to_sym : nil
    end

    ##
    # @return [Hash]
    #
    def build_metadata(metadata = {})
      unless opts[:password].empty?
        username = opts.fetch(:username, 'grpc').to_s
        username = username.empty? ? '' : "#{username}:"
        auth_string = Base64.encode64("#{username}#{opts[:password]}")
        metadata[:authorization] = "Basic #{auth_string}".gsub("\n",'')
      end
      metadata
    end

    ##
    # @return [Symbol|GRPC::Core::ChannelCredentials]
    #
    def build_ssl_credentials
      cert = nil
      if opts[:ssl_certificate_file]
        cert = File.read(opts[:ssl_certificate_file]).to_s.strip
      elsif opts[:ssl_certificate]
        cert = opts[:ssl_certificate].to_s.strip
      end

      cert ? GRPC::Core::ChannelCredentials.new(cert) : :this_channel_is_insecure
    end

    ##
    # @return [Class]
    #
    def error_deserializer_class
      if Gruf.error_serializer
        Gruf.error_serializer.is_a?(Class) ? Gruf.error_serializer : Gruf.error_serializer.to_s.constantize
      else
        Gruf::Serializers::Errors::Json
      end
    end
  end
end

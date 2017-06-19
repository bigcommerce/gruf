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
      call_sig = call_signature(request_method)
      if call_sig
        execute(call_sig, req, md)
      else
        raise NotImplementedError.new("The method #{request_method} has not been implemented in this service.")
      end
    rescue GRPC::BadStatus => e
      emk = Gruf.error_metadata_key.to_s
      if e.respond_to?(:metadata) && e.metadata.key?(emk)
        raise Gruf::Client::Error, error_deserializer_class.new(e.metadata[emk]).deserialize
      else
        raise # passthrough
      end
    end

    private

    ##
    # @param [Symbol] call_sig The call signature being executed
    # @param [Object] req
    # @param [Hash] md
    #
    def execute(call_sig, req, md)
      timed = Timer.time do
        self.send(call_sig, req, return_op: true, metadata: md)
      end
      Gruf::Response.new(timed.result, timed.time)
    end

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
    # :nocov:
    def build_ssl_credentials
      cert = nil
      if opts[:ssl_certificate_file]
        cert = File.read(opts[:ssl_certificate_file]).to_s.strip
      elsif opts[:ssl_certificate]
        cert = opts[:ssl_certificate].to_s.strip
      end

      cert ? GRPC::Core::ChannelCredentials.new(cert) : :this_channel_is_insecure
    end
    # :nocov:

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

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
require_relative 'client/error'
require_relative 'client/error_factory'

module Gruf
  ##
  # Abstracts out the calling interface for interacting with gRPC clients. Streamlines calling and provides
  # instrumented response objects that also can contain deserialized error messages via serialized objects transported
  # via the service's trailing metadata.
  #
  #   begin
  #     client = ::Gruf::Client.new(service: ::Demo::ThingService)
  #     response = client.call(:GetMyThing, id: 123)
  #     puts response.message.inspect
  #   rescue Gruf::Client::Error => e
  #     puts e.error.inspect
  #   end
  #
  # Utilizes SimpleDelegator to wrap the given service that the client is connecting to, which allows a clean interface
  # to the underlying RPC descriptors and methods.
  #
  class Client < SimpleDelegator
    include Gruf::Loggable

    # @return [Class] The base, friendly name of the service being requested
    attr_reader :base_klass
    # @return [Class] The class name of the gRPC service being requested
    attr_reader :service_klass
    # @return [Hash] A hash of options for the client
    attr_reader :opts

    ##
    # Initialize the client and setup the stub
    #
    # @param [Module] service The namespace of the client Stub that is desired to load
    # @param [Hash] options A hash of options for the client
    # @option options [String] :password The password for basic authentication for the service.
    # @option options [String] :hostname The hostname of the service. Defaults to linkerd.
    # @param [Hash] client_options A hash of options to pass to the gRPC client stub
    #
    def initialize(service:, options: {}, client_options: {})
      @base_klass = service
      @service_klass = "#{base_klass}::Service".constantize
      @opts = options || {}
      @opts[:password] = options.fetch(:password, '').to_s
      @opts[:hostname] = options.fetch(:hostname, Gruf.default_client_host)
      @error_factory = Gruf::Client::ErrorFactory.new
      client = "#{service}::Stub".constantize.new(@opts[:hostname], build_ssl_credentials, client_options)
      super(client)
    end

    ##
    # Call the client's method with given params
    #
    # @param [String|Symbol] request_method The method that is being requested on the service
    # @param [Hash] params (Optional) A hash of parameters that will be inserted into the gRPC request message that is required
    # for the given above call
    # @param [Hash] metadata (Optional) A hash of metadata key/values that are transported with the client request
    # @param [Hash] opts (Optional) A hash of options to send to the gRPC request_response method
    # @return [Gruf::Response] The response from the server
    # @raise [Gruf::Client::Error|GRPC::BadStatus] If an error occurs, an exception will be raised according to the
    # error type that was returned
    #
    def call(request_method, params = {}, metadata = {}, opts = {}, &block)
      request_method = request_method.to_sym
      req = streaming_request?(request_method) ? params : request_object(request_method, params)
      md = build_metadata(metadata)
      call_sig = call_signature(request_method)

      raise NotImplementedError, "The method #{request_method} has not been implemented in this service." unless call_sig

      resp, operation = execute(call_sig, req, md, opts, &block)

      raise @error_factory.from_exception(resp.result) unless resp.success?

      Gruf::Response.new(operation: operation, message: resp.result, execution_time: resp.time)
    end

    ##
    # Returns the currently set timeout on the client stub
    #
    # @return [Integer|NilClass]
    #
    def timeout
      __getobj__.instance_variable_get(:@timeout)
    end

    private

    ##
    # @param [Symbol] request_method
    # @return [Boolean]
    #
    def streaming_request?(request_method)
      desc = rpc_desc(request_method)
      desc && (desc.client_streamer? || desc.bidi_streamer?)
    end

    ##
    # Execute the given request to the service
    #
    # @param [Symbol] call_sig The call signature being executed
    # @param [Object] req (Optional) The protobuf request message to send
    # @param [Hash] metadata (Optional) A hash of metadata key/values that are transported with the client request
    # @param [Hash] opts (Optional) A hash of options to send to the gRPC request_response method
    # @return [Array<Gruf::Timer::Result, GRPC::ActiveCall::Operation>]
    #
    def execute(call_sig, req, metadata, opts = {}, &block)
      operation = nil
      result = Gruf::Timer.time do
        opts[:return_op] = true
        opts[:metadata] = metadata
        operation = send(call_sig, req, opts, &block)
        operation.execute
      end
      [result, operation]
    end

    ##
    # Get the appropriate RPC descriptor given the method on the service being called
    #
    # @param [Symbol] request_method The method name being called on the remote service
    # @return [Struct<GRPC::RpcDesc>] Return the given RPC descriptor given the method on the service being called
    #
    def rpc_desc(request_method)
      service_klass.rpc_descs[request_method]
    end

    ##
    # Get the appropriate protobuf request message for the given request method on the service being called
    #
    # @param [Symbol] request_method The method name being called on the remote service
    # @param [Hash] params (Optional) A hash of parameters that will populate the request object
    # @return [Class] The request object that corresponds to the method being called
    #
    def request_object(request_method, params = {})
      desc = rpc_desc(request_method)
      desc && desc.input ? desc.input.new(params) : nil
    end

    ##
    # Properly find the appropriate call signature for the GRPC::GenericService given the request method name
    #
    # @return [Symbol]
    #
    def call_signature(request_method)
      desc = rpc_desc(request_method)
      desc && desc.name ? desc.name.to_s.underscore.to_sym : nil
    end

    ##
    # Build a sanitized, authenticated metadata hash for the given request
    #
    # @param [Hash] metadata A base metadata hash to build from
    # @return [Hash] The compiled metadata hash that is ready to be transported over the wire
    #
    def build_metadata(metadata = {})
      unless opts[:password].empty?
        username = opts.fetch(:username, 'grpc').to_s
        username = username.empty? ? '' : "#{username}:"
        auth_string = Base64.encode64("#{username}#{opts[:password]}")
        metadata[:authorization] = "Basic #{auth_string}".tr("\n", '')
      end
      metadata
    end

    ##
    # Build the SSL/TLS credentials for the outbound gRPC request
    #
    # @return [Symbol|GRPC::Core::ChannelCredentials] The generated SSL credentials for the outbound gRPC request
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
    # Return the specified error deserializer class by the configuration
    #
    # @return [Class] The proper error deserializer class. Defaults to JSON.
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

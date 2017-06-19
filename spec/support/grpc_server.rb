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
require 'google/protobuf'
require 'grpc'

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_message 'rpc.things.GetThingRequest' do
    optional :id, :int64, 1
  end
  add_message 'rpc.things.GetThingResponse' do
    optional :id, :int64, 1
  end
  add_message 'rpc.things.GetFailRequest' do
    optional :id, :int64, 1
  end
  add_message 'rpc.things.GetFailResponse' do
    optional :id, :int64, 1
  end
  add_message 'rpc.things.GetFieldErrorFailRequest' do
    optional :id, :int64, 1
  end
  add_message 'rpc.things.GetFieldErrorFailResponse' do
    optional :id, :int64, 1
  end
  add_message 'rpc.things.GetExceptionRequest' do
    optional :id, :int64, 1
  end
  add_message 'rpc.things.GetExceptionResponse' do
    optional :id, :int64, 1
  end
  add_message 'rpc.things.GetUncaughtExceptionRequest' do
    optional :id, :int64, 1
  end
  add_message 'rpc.things.GetUncaughtExceptionResponse' do
    optional :id, :int64, 1
  end
end

module Rpc
  GetThingRequest = Google::Protobuf::DescriptorPool.generated_pool.lookup('rpc.things.GetThingRequest').msgclass
  GetThingResponse = Google::Protobuf::DescriptorPool.generated_pool.lookup('rpc.things.GetThingResponse').msgclass
  GetFailRequest = Google::Protobuf::DescriptorPool.generated_pool.lookup('rpc.things.GetFailRequest').msgclass
  GetFailResponse = Google::Protobuf::DescriptorPool.generated_pool.lookup('rpc.things.GetFailResponse').msgclass
  GetFieldErrorFailRequest = Google::Protobuf::DescriptorPool.generated_pool.lookup('rpc.things.GetFieldErrorFailRequest').msgclass
  GetFieldErrorFailResponse = Google::Protobuf::DescriptorPool.generated_pool.lookup('rpc.things.GetFieldErrorFailResponse').msgclass
  GetExceptionRequest = Google::Protobuf::DescriptorPool.generated_pool.lookup('rpc.things.GetExceptionRequest').msgclass
  GetExceptionResponse = Google::Protobuf::DescriptorPool.generated_pool.lookup('rpc.things.GetExceptionResponse').msgclass
  GetUncaughtExceptionRequest = Google::Protobuf::DescriptorPool.generated_pool.lookup('rpc.things.GetUncaughtExceptionRequest').msgclass
  GetUncaughtExceptionResponse = Google::Protobuf::DescriptorPool.generated_pool.lookup('rpc.things.GetUncaughtExceptionResponse').msgclass

  module ThingService
    class Service

      include GRPC::GenericService

      self.marshal_class_method = :encode
      self.unmarshal_class_method = :decode
      self.service_name = 'rpc.things.ThingService'

      rpc :GetThing, GetThingRequest, GetThingResponse
      rpc :GetFail, GetFailRequest, GetFailResponse
      rpc :GetFieldErrorFail, GetFieldErrorFailRequest, GetFieldErrorFailResponse
      rpc :GetException, GetExceptionRequest, GetExceptionResponse
      rpc :GetUncaughtException, GetUncaughtExceptionRequest, GetUncaughtExceptionResponse
    end

    Stub = Service.rpc_stub_class
  end
end

class ThingService < Rpc::ThingService::Service
  include Gruf::Service

  def get_thing(req, _call)
    Math.sqrt(4) # used for testing
    ::Rpc::GetThingResponse.new(id: req.id)
  end

  def get_fail(req, c)
    fail!(req, c, :not_found, :thing_not_found, "#{req.id} not found!", foo: :bar)
  end

  def get_field_error_fail(req, c)
    add_field_error(:name, :no_name, 'Please specify a name.')
    fail!(req, c, :invalid_argument, :no_thing_name, 'Please correct your errors.', my: :sharona)
  end

  def get_exception(req, c)
    raise 'oh noes'
  rescue => e
    set_debug_info(e.message, e.backtrace)
    fail!(req, c, :internal, :oh_noes, 'We done failed', oops: :man)
  end

  def get_uncaught_exception(req, c)
    raise 'epic fail'
  end

  def not_an_endpoint
    'i like turtles'
  end
end

module Rpc
  module Test
    class Call
      attr_reader :metadata

      def initialize(md = nil)
        @metadata = md || { 'authorization' => "Basic #{Base64.encode64('grpc:magic')}" }
      end

      def output_metadata
        @output_metadata ||= {}
      end
    end
  end
end

class TestClient
  def get_thing(id: 1)
    request = ::Rpc::GetThingRequest.new(id: id)
    rpc_client = ::ThingService.new

    c = Rpc::Test::Call.new('authorization' => "Basic #{Base64.encode64('grpc:magic')}")
    begin
      thing = rpc_client.get_thing(request, c)
    rescue Gruf::Client::Error => e
      puts e.error.inspect
    end
    thing
  end
end

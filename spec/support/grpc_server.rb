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
    end

    Stub = Service.rpc_stub_class
  end
end

class ThingService < Rpc::ThingService::Service
  include Gruf::Endpoint

  def get_thing(req, _call)
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

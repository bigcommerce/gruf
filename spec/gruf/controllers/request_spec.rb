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
require 'spec_helper'

describe ::Gruf::Controllers::Request do
  let(:method_key) { :get_thing }
  let(:service) { Rpc::ThingService::Service }
  let(:rpc_desc) { Rpc::ThingService::Service.rpc_descs[:GetThing] }
  let(:active_call) { Rpc::Test::Call.new }
  let(:message) { Rpc::GetThingRequest.new(id: 1) }

  let(:request) do
    described_class.new(
      method_key: method_key,
      service: service,
      rpc_desc: rpc_desc,
      active_call: active_call,
      message: message
    )
  end

  describe '#service_key' do
    subject { request.service_key }

    it 'returns the translated name' do
      expect(subject).to eq 'rpc.thing_service'
    end

    context 'when service name contains .service in the middle and at the end' do
      let(:service) do
        Class.new do
          def self.name
            'Rpc::ServiceHandler::TestService::Service'
          end
        end
      end

      it 'only removes the trailing .service suffix, not all occurrences' do
        expect(subject).to eq 'rpc.service_handler.test_service'
      end
    end
  end

  describe '#service' do
    subject { request.service }

    it 'returns the service class name' do
      expect(subject).to eq service
    end
  end

  describe '#method_name' do
    subject { request.method_name }

    it 'returns the translated service and method name' do
      expect(subject).to eq 'rpc.thing_service.get_thing'
    end
  end

  describe '#request_class' do
    subject { request.request_class }

    it 'returns the gRPC request class' do
      expect(subject).to eq Rpc::GetThingRequest
    end
  end

  describe '#response_class' do
    subject { request.response_class }

    it 'returns the gRPC response class' do
      expect(subject).to eq Rpc::GetThingResponse
    end
  end

  describe '#messages' do
    subject { request.messages }

    context 'when it is a request/response type' do
      it 'returns the message in an array' do
        expect(subject).to eq [message]
      end
    end

    context 'when it is a client streamer type' do
      let(:rpc_desc) { Rpc::ThingService::Service.rpc_descs[:CreateThings] }
      let(:messages) { [Rpc::Thing.new(id: 1), Rpc::Thing.new(id: 2)] }
      let(:message) { proc { messages } }

      it 'returns the messages' do
        expect(subject).to eq messages
      end
    end

    context 'when it is a server streamer type' do
      let(:rpc_desc) { Rpc::ThingService::Service.rpc_descs[:GetThings] }
      let(:message) { Rpc::GetThingsRequest.new }

      it 'returns the request message in an array' do
        expect(subject).to eq [message]
      end
    end

    context 'when it is a bidi streamer type' do
      let(:rpc_desc) { Rpc::ThingService::Service.rpc_descs[:CreateThingsInStream] }
      let(:messages) { [Rpc::Thing.new(id: 1), Rpc::Thing.new(id: 2)] }
      let(:message) { messages }

      it 'returns the messages' do
        expect(subject).to eq messages
      end
    end
  end

  describe '#context' do
    subject { request.context }

    it 'allows access to the context' do
      expect(subject).to eq({})

      subject[:foo] = 'bar'
      expect(subject[:foo]).to eq 'bar'
    end

    it 'accesses values indifferently' do
      subject[:foo] = 'bar'
      expect(subject['foo']).to eq 'bar'

      subject['foo'] = 'baz'
      expect(subject['foo']).to eq 'baz'
      expect(subject[:foo]).to eq 'baz'
    end
  end

  describe '#metadata' do
    subject { request.metadata }

    it 'delegates to the active call' do
      expect(subject).to eq active_call.metadata
    end
  end

  describe '#metadata=' do
    subject { request.metadata[:foo] = 'bar' }

    it 'delegates to the active call' do
      expect { subject }.not_to raise_error
      expect(request.metadata[:foo]).to eq 'bar'
    end
  end
end

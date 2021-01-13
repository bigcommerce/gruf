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

describe Gruf::Interceptors::ClientInterceptor do
  let(:interceptor) { TestClientInterceptor.new }

  let(:type) { :request_response }
  let(:requests) { [Rpc::GetThingRequest.new] }
  let(:call) { double(:call, output_metadata: {}) }
  let(:grpc_method) { '/rpc.ThingService/GetThing' }
  let(:metadata) { { foo: 'bar' } }
  let(:request_context) do
    Gruf::Outbound::RequestContext.new(
      type: type,
      requests: requests,
      call: call,
      method: grpc_method,
      metadata: metadata
    )
  end

  describe 'interception' do
    context 'when it is a request_response call' do
      it 'routes appropriately and yields control' do
        expect(Gruf.logger).to receive(:info).once
        test = false
        interceptor.request_response(request: requests.first, call: call, method: grpc_method, metadata: metadata) do
          test = true
        end
        expect(test).to be_truthy
      end
    end

    context 'when it is a client_streamer call' do
      it 'routes appropriately and yields control' do
        expect(Gruf.logger).to receive(:info).once
        test = false
        interceptor.client_streamer(requests: requests, call: call, method: grpc_method, metadata: metadata) do
          test = true
        end
        expect(test).to be_truthy
      end
    end

    context 'when it is a server_streamer call' do
      it 'routes appropriately and yields control' do
        expect(Gruf.logger).to receive(:info).once
        test = false
        interceptor.server_streamer(request: requests.first, call: call, method: grpc_method, metadata: metadata) do
          test = true
        end
        expect(test).to be_truthy
      end
    end

    context 'when it is a bidi_streamer call' do
      it 'routes appropriately and yields control' do
        expect(Gruf.logger).to receive(:info).once
        test = false
        interceptor.bidi_streamer(requests: requests, call: call, method: grpc_method, metadata: metadata) do
          test = true
        end
        expect(test).to be_truthy
      end
    end
  end

  describe '#call' do
    let(:interceptor) { described_class.new }

    it 'yields control' do
      expect(Gruf.logger).to receive(:debug).once
      expect { |r| interceptor.call(request_context: request_context, &r) }.to yield_control.once
    end
  end
end

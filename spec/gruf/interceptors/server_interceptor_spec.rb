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

describe Gruf::Interceptors::ServerInterceptor do
  let(:interceptor) { TestServerInterceptor }
  let(:interceptor_args) { {} }
  let(:interceptors) { { interceptor => interceptor_args } }

  describe 'statelessness' do
    let(:interceptor) { TestServerInterceptorInstanceVar }

    it 'does not persist interceptor instance variables across requests', :run_thing_server do
      client = build_client
      resp = client.call(:GetThing)
      expect(resp.message).to be_a(Rpc::GetThingResponse)
      resp = client.call(:GetThing)
      expect(resp.message).to be_a(Rpc::GetThingResponse)
    end
  end

  describe '#call' do
    subject { interceptor.new(request, error, {}).call }

    let(:request) { build(:controller_request) }
    let(:error) { build(:error) }

    context 'when it is not extended' do
      let(:interceptor) { described_class }

      it 'raises a NotImplementedError' do
        expect { subject }.to raise_error(NotImplementedError)
      end
    end
  end

  describe 'request context propagation' do
    subject { controller.call(:get_thing) }

    let(:rpc_service) { ::Rpc::ThingService::Service }
    let(:rpc_desc) { Rpc::ThingService::Service.rpc_descs.values.first }
    let(:message) { Rpc::GetThingRequest.new(id: 1) }
    let(:controller_class) { ThingController }
    let(:controller) do
      controller_class.new(
        method_key: :get_thing,
        service: rpc_service,
        active_call: Rpc::Test::Call.new,
        message: message,
        rpc_desc: rpc_desc
      )
    end

    before do
      Gruf.interceptors.use(TestServerInterceptor, context_setting: 'one')
      Gruf.interceptors.use(TestServerInterceptor2, context_setting: 'two')
    end

    it 'allows passing the request context between interceptors' do
      expect(subject).to be_a(Rpc::GetThingResponse)

      ctx = controller.request.context
      expect(ctx).to have_key(:setting1)
      expect(ctx[:setting1]).to eq('one')
      expect(ctx).to have_key(:setting2)
      expect(ctx[:setting2]).to eq('two')

      # overwritten in second interceptor
      expect(ctx).to have_key(:setting)
      expect(ctx[:setting]).to eq('two')
    end
  end
end

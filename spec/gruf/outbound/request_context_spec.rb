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

describe Gruf::Outbound::RequestContext do
  let(:type) { :request_response }
  let(:requests) { [Rpc::GetThingRequest.new] }
  let(:call) { double(:call, output_metadata: {}) }
  let(:grpc_method) { '/rpc.ThingService/GetThing' }
  let(:metadata) { { foo: 'bar' } }
  let(:request_context) do
    described_class.new(
      type: type,
      requests: requests,
      call: call,
      method: grpc_method,
      metadata: metadata
    )
  end

  describe '#method_name' do
    subject { request_context.method_name }

    it 'parses out the method name' do
      expect(subject).to eq 'GetThing'
    end
  end

  describe '#route_key' do
    subject { request_context.route_key }

    it 'returns a friendly routing key' do
      expect(subject).to eq 'rpc.thing_service.get_thing'
    end
  end
end

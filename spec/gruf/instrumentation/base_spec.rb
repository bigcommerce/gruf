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
require 'spec_helper'

describe Gruf::Instrumentation::Base do
  let(:service) { ThingService.new }
  let(:id) { rand(1..1000) }
  let(:request) { Rpc::GetThingRequest.new(id: id) }
  let(:response) { Rpc::GetThingResponse.new(id: id) }
  let(:execution_time) { rand(0.001..10.000).to_f }
  let(:call_signature) { :get_thing }
  let(:active_call) { Rpc::Test::Call.new }
  let(:options) { {} }
  let(:obj) { described_class.new(service, request, response, execution_time, call_signature, active_call, options) }

  describe '#success?' do
    subject { obj.success? }

    context 'when is a normal response' do
      it 'should return true' do
        expect(obj.response).to be_a(Rpc::GetThingResponse)
        expect(obj.response).to eq response
        expect(subject).to be_truthy
      end
    end

    context 'when is a GRPC::BadStatus' do
      let(:response) { GRPC::BadStatus.new('thing not found') }

      it 'should return false' do
        expect(obj.response).to be_a(GRPC::BadStatus)
        expect(obj.response).to eq response
        expect(subject).to be_falsey
      end
    end
  end
end

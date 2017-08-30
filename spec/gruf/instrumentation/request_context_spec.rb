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

describe Gruf::Instrumentation::RequestContext do
  let(:service) { ThingService.new }
  let(:id) { rand(1..1000) }
  let(:request) { Rpc::GetThingRequest.new(id: id) }
  let(:response) { Rpc::GetThingResponse.new(thing: Rpc::Thing.new(id: id)) }
  let(:execution_time) { rand(0.001..10.000).to_f }
  let(:call_signature) { :get_thing }
  let(:active_call) { Rpc::Test::Call.new }

  let(:rc) do
    described_class.new(
      service: service,
      request: request,
      response: response,
      call_signature: call_signature,
      active_call: active_call,
      execution_time: execution_time
    )
  end

  describe '.success?' do
    subject { rc.success? }

    context 'when the response is successful' do
      it 'should return true' do
        expect(subject).to be_truthy
      end
    end

    context 'when the response is a failure' do
      let(:response) { GRPC::Internal.new }

      it 'should return false' do
        expect(subject).to be_falsey
      end
    end
  end

  describe '.response_class_name' do
    subject { rc.response_class_name }
  
    it 'should return the response class as a string' do
      expect(subject).to eq 'Rpc::GetThingResponse'
    end
  end

  describe '.execution_time_rounded' do
    let(:precision) { 2 }
    let(:execution_time) { 1.12345 }
    subject { rc.execution_time_rounded(precision: precision) }

    it 'should return the execution time rounded to 2 decimal places' do
      expect(subject).to eq 1.12
    end

    context 'when a precision is specified' do
      let(:precision) { 4 }

      it 'should return the execution time rounded to X decimal places' do
        expect(subject).to eq 1.1235
      end
    end
  end
end

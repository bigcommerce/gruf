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
  let(:response) { Rpc::GetThingResponse.new(thing: Rpc::Thing.new(id: id)) }
  let(:execution_time) { rand(0.001..10.000).to_f }
  let(:call_signature) { :get_thing }
  let(:active_call) { Rpc::Test::Call.new }
  let(:options) { {} }
  let(:obj) { TestInstrumentationHook.new(service, options) }
  let(:call) { obj.outer_around(call_signature, request, active_call) { response } }

  describe 'successful responses' do
    context 'when is a normal response' do
      it 'should return true' do
        expect { call }.to_not raise_error
      end
    end

    context 'when is a GRPC::BadStatus' do
      let(:call) do
        obj.outer_around(call_signature, request, active_call) do |_cs, req, ac|
          service.fail!(req, ac, :not_found, :thing_not_found, 'thing not found')
        end
      end

      it 'should return false' do
        expect { call }.to raise_error(GRPC::BadStatus) do |e|
          expect(e.details).to eq 'thing not found'
        end
      end
    end
  end

  describe '.success?' do
    subject { obj.success?(response) }

    context 'when the response is a success' do
      it 'should return truthy' do
        expect(subject).to be_truthy
      end
    end

    context 'when the response is a failure' do
      let(:response) { GRPC::Internal.new }

      it 'should return falsey' do
        expect(subject).to be_falsey
      end
    end
  end

  describe '.service_key' do
    subject { obj.service_key }

    it 'should return the proper service key' do
      expect(subject).to eq 'thing_service'
    end
  end

  describe '.method_key' do
    let(:delimiter) { '.' }
    subject { obj.method_key(call_signature, delimiter: delimiter) }

    it 'should return a proper key delimited' do
      expect(subject).to eq "#{service.class.name.underscore}#{delimiter}#{call_signature}"
    end

    context 'with a custom delimiter' do
      let(:delimiter) { '/' }

      it 'should return the key with the specified delimiter' do
        expect(subject).to eq "#{service.class.name.underscore}#{delimiter}#{call_signature}"
      end
    end
  end
end

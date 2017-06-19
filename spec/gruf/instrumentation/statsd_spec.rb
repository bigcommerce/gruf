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

describe Gruf::Instrumentation::Statsd do
  let(:service) { ThingService.new }
  let(:id) { rand(1..1000) }
  let(:request) { Rpc::GetThingRequest.new(id: id) }
  let(:response) { Rpc::GetThingResponse.new(id: id) }
  let(:execution_time) { rand(0.001..10.000).to_f }
  let(:call_signature) { :get_thing_without_intercept }
  let(:active_call) { Rpc::Test::Call.new }
  let(:options) { { statsd: statsd_options } }
  let(:statsd_options) { { client: client, prefix: prefix } }
  let(:client) { double(:statsd, increment: true, timing: true )}
  let(:prefix) { 'app.rpc' }
  let(:obj) { described_class.new(service, request, response, execution_time, call_signature, active_call, options) }

  let(:expected_route_key) { "#{prefix ? "#{prefix}." : ''}thing_service.get_thing" }

  describe '.call' do
    subject { obj.call }

    context 'with a valid client' do
      it 'should send the metrics to statsd' do
        expect(client).to receive(:increment).with(expected_route_key).once
        expect(client).to receive(:timing).with(expected_route_key, execution_time).once
        subject
      end
    end

    context 'with no client specified' do
      let(:statsd_options) { {} }

      it 'should noop and log an error' do
        expect(Gruf.logger).to receive(:error)
        subject
      end
    end
  end

  describe '.key_prefix' do
    subject { obj.send(:key_prefix) }

    context 'if a prefix is specified' do
      it 'should postfix a dot to it' do
        expect(subject).to eq "#{prefix}."
      end
    end

    context 'if no prefix is specified' do
      let(:prefix) { '' }
      it 'should return an empty string' do
        expect(subject).to eq ''
      end
    end
  end

  describe '.route_key' do
    subject { obj.send(:route_key) }

    it 'should build the proper route key based on the prefix, service, and call signature' do
      expect(subject).to eq expected_route_key
    end
  end

  describe '.service_key' do
    subject { obj.send(:service_key) }

    it 'should return the proper service key' do
      expect(subject).to eq 'thing_service'
    end
  end

  describe '.client' do
    subject { obj.send(:client) }

    context 'if a client is specified' do
      it 'should return it' do
        expect(subject).to eq client
      end
    end

    context 'if no client is specified' do
      let(:client) { nil }

      it 'should return nil' do
        expect(subject).to be_nil
      end
    end
  end
end

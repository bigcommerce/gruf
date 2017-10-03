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

describe Gruf::Interceptors::Instrumentation::Statsd do
  let(:options) { { client: client, prefix: prefix } }
  let(:client) { double(:statsd, increment: true, timing: true) }
  let(:prefix) { 'app' }

  let(:request) { build :controller_request, method_key: :get_thing }
  let(:errors) { build :error }
  let(:interceptor) { described_class.new(request, errors, options) }

  let(:expected_route_key) { "#{prefix ? "#{prefix}." : ''}rpc.thing_service.get_thing" }

  describe '.call' do
    subject { interceptor.call { true } }

    context 'with a valid client' do
      it 'should send the metrics to statsd' do
        expect(client).to receive(:increment).with(expected_route_key).once
        expect(client).to receive(:timing).with(expected_route_key, kind_of(Float)).once
        subject
      end
    end

    context 'with no client specified' do
      let(:options) { {} }

      it 'should noop and log an error' do
        expect(Gruf.logger).to receive(:error)
        subject
      end
    end
  end

  describe '.key_prefix' do
    subject { interceptor.send(:key_prefix) }

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
    subject { interceptor.send(:route_key) }

    it 'should build the proper route key based on the prefix, service, and call signature' do
      expect(subject).to eq expected_route_key
    end
  end

  describe '.client' do
    subject { interceptor.send(:client) }

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

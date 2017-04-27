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

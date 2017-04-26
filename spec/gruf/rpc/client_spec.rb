# Copyright (c) 2017, BigCommerce Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 3. All advertising materials mentioning features or use of this software
# must display the following acknowledgement:
# This product includes software developed by BigCommerce Inc.
# 4. Neither the name of BigCommerce Inc. nor the
# names of its contributors may be used to endorse or promote products
# derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY BIGCOMMERCE INC ''AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL BIGCOMMERCE INC BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
require 'spec_helper'

describe Gruf::Client do
  let(:options) { {} }
  let(:client) { described_class.new(service: Rpc::ThingService, options: options) }

  describe '#initialize' do
    subject { client }

    it 'should initialize a new client for the given service' do
      expect(subject).to be_a(Gruf::Client)
    end

    it 'should have the handlers' do
      expect(subject.respond_to?(:get_thing)).to be_truthy
      expect(subject.respond_to?(:get_fail)).to be_truthy
    end

    context 'when no hostname is provided' do
      it 'should default to the default client host' do
        Gruf.configure do |c|
          c.default_client_host = 'test.dev'
        end
        expect(subject).to be_a(Gruf::Client)
        expect(subject.opts[:hostname]).to eq 'test.dev'
      end
    end
  end

  describe '.call' do
    let(:metadata) { { foo: 'bar' } }
    let(:params) { { id: 1 } }
    let(:op) { double(:op, execute: true, metadata: metadata, trailing_metadata: {}, deadline: nil, cancelled?: false) }
    subject { client.call(:GetThing, params, metadata) }

    it 'should call the appropriate method with the right signature' do
      req = Rpc::GetThingRequest.new(params)
      expect(client).to receive(:get_thing).with(req, return_op: true, metadata: metadata).and_return(op)
      expect(subject).to be_truthy
    end
  end

  describe '.build_metadata' do
    let(:metadata) { { foo: 'bar' } }
    subject { client.send(:build_metadata, metadata) }

    context 'with a password' do
      let(:options) { { username: 'grpc', password: 'abcd' } }
      let(:auth_string_encoded) { "Basic #{Base64.encode64("#{options[:username]}:#{options[:password]}")}".strip }

      context 'and a passed metadata hash' do
        it 'should return the merged hash with the authorization data' do
          expect(subject).to eq metadata.merge(authorization: auth_string_encoded)
        end
      end

      context 'and no passed metadata hash' do
        let(:metadata) { {} }
        it 'should return a hash with only the authorization data' do
          expect(subject).to eq({ authorization: auth_string_encoded })
        end
      end
    end

    context 'without a password' do
      context 'and a passed hash' do
        it 'should return the hash untouched' do
          expect(subject).to eq metadata
        end
      end

      context 'and nothing passed' do
        let(:options) { { username: '', password: '' } }
        let(:metadata) { {} }
        it 'should return an empty hash' do
          expect(subject).to be_empty
        end
      end
    end
  end
end

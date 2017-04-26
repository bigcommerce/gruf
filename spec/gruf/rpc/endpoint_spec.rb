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

describe Gruf::Endpoint do
  let(:endpoint) { ThingService.new }
  let(:id) { 1 }
  let(:req) { ::Rpc::GetThingRequest.new(id: id) }
  let(:active_call) { double(:active_call, output_metadata: {}, metadata: {})}

  describe 'hooks' do
    subject { endpoint }

    describe '.before_call' do
      it 'should exist on the service' do
        expect(endpoint.respond_to?(:before_call)).to be_truthy
      end
    end

    describe '.after_call' do
      it 'should exist on the service' do
        expect(endpoint.respond_to?(:after_call)).to be_truthy
      end
    end

    describe '.around_call' do
      it 'should exist on the service' do
        expect(endpoint.respond_to?(:around_call)).to be_truthy
      end
    end
  end

  describe '.fail!' do
    context 'on a failure' do
      subject { endpoint.get_fail(req, active_call) }
      let(:metadata) { {foo: :bar} }
      let(:error) { Gruf::Error.new(code: :not_found, app_code: :thing_not_found, message: "#{req.id} not found!") }

      it 'should raise a GRPC::NotFound error' do
        expect { subject }.to raise_error { |err|
          expect(err).to be_a(GRPC::NotFound)
          expect(err.code).to eq 5
          expect(err.message).to eq "5:#{id} not found!"
          expect(err.metadata).to eq(foo: 'bar', :'error-internal-bin' => error.serialize)
        }
      end
    end

    context 'on a success' do
      subject { endpoint.get_thing(req, active_call) }

      it 'should return normally' do
        expect(subject).to be_a(Rpc::GetThingResponse)
      end
    end
  end

  describe '.authorize' do
    subject { endpoint.get_thing(req, active_call) }

    it 'should be called for every method call' do
      expect(endpoint).to receive(:authenticate).once
      expect(subject).to be_a(Rpc::GetThingResponse)
    end
  end

  describe 'functional test' do
    let(:client) { TestClient.new }
    let(:id) { 1 }
    subject { client.get_thing(id: id) }

    it 'should return the thing' do
      expect(subject).to be_a(Rpc::GetThingResponse)
      expect(subject.id).to eq id
    end
  end
end

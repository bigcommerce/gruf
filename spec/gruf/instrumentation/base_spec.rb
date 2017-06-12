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

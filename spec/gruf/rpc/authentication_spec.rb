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
require 'base64'

describe Gruf::Authentication do

  describe '#verify' do
    let(:username) { 'grpc' }
    let(:password) { 'magic' }
    let(:md) { { 'authorization' => "Basic #{Base64.encode64("#{username}:#{password}")}" } }
    let(:call) { Rpc::Test::Call.new(md) }

    subject { described_class.verify(call) }

    before do
      Gruf.configure do |c|
        c.authentication_options = {
          credentials: [{ username: 'grpc', password: 'magic' }]
        }
      end
    end

    context 'with no strategies' do
      it 'should execute no strategies and return true' do
        expect(Gruf::Authentication::Basic).to_not receive(:verify)
        expect(Gruf::Authentication::None).to_not receive(:verify)
        expect(subject).to be_truthy
      end
    end

    context 'with the none strategy' do
      before do
        Gruf::Authentication::Strategies.add(:none, Gruf::Authentication::None)
      end

      it 'should execute the None strategy and return true' do
        expect(Gruf::Authentication::Basic).to_not receive(:verify)
        expect(Gruf::Authentication::None).to receive(:verify).and_return(true)
        expect(subject).to be_truthy
      end
    end

    context 'with basic auth strategy' do
      before do
        Gruf::Authentication::Strategies.add(:basic, Gruf::Authentication::Basic)
      end

      context 'when with good credentials' do
        it 'should execute the basic strategy and return true' do
          expect(Gruf::Authentication::Basic).to receive(:verify).and_call_original
          expect(Gruf::Authentication::None).to_not receive(:verify)
          expect(subject).to be_truthy
        end
      end

      context 'when with bad credentials' do
        let(:password) { 'bad' }

        it 'should execute the basic strategy and return false' do
          expect(Gruf::Authentication::Basic).to receive(:verify).and_call_original
          expect(Gruf::Authentication::None).to_not receive(:verify)
          expect(subject).to be_falsey
        end
      end
    end
  end
end

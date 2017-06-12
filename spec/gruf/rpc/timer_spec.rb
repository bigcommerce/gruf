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

describe Gruf::Timer do

  describe '#time' do
    let(:result) { { foo: 'bar' } }

    context 'when the operation yields normally' do
      subject { described_class.time { result } }

      it 'should return a timed result with the proper values' do
        expect(subject).to be_a(Gruf::Timer::Result)
        expect(subject.result).to eq result
        expect(subject.time).to be > 0.00
      end
    end

    context 'when the operation raises an error' do
      subject { described_class.time { raise err } }

      context 'that is a BadStatus exception' do
        let(:err) { GRPC::Internal.new('ack!') }

        it 'should return the BadStatus as the result with a time' do
          expect(subject).to be_a(Gruf::Timer::Result)
          expect(subject.result).to eq err
          expect(subject.time).to be > 0.00
        end
      end

      context 'that is any other exception' do
        let(:err) { StandardError.new("it's a trap!") }

        it 'should pass through that exception' do
          expect { subject }.to raise_error(err)
        end
      end
    end
  end
end

describe Gruf::Timer::Result do
  let(:time) { rand(10.00..500.00) }
  let(:result) { {} }
  let(:timed_result) { described_class.new(result, time) }

  describe '.initialize' do
    subject { timed_result }

    it 'should setup and cast the values appropriately' do
      expect(subject).to be_a described_class
      expect(subject.time).to eq time
      expect(subject.result).to eq result
    end
  end

  describe '.success?' do
    subject { timed_result.success? }

    context 'with a normal result' do
      it 'should return true' do
        expect(subject).to be_truthy
      end
    end

    context 'with a BadStatus result' do
      let(:result) { GRPC::BadStatus.new(5, 'Boo', foo: 'bar') }

      it 'should return false' do
        expect(subject).to be_falsey
      end
    end
  end
end

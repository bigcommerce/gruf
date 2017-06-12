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

describe Gruf::Response do
  let(:internal_execution_time) { rand(1.00..500.00) }
  let(:trailing_metadata) { { 'timer' => internal_execution_time } }
  let(:operation) { build_operation(trailing_metadata: trailing_metadata, execution_time: execution_time) }
  let(:execution_time) { nil }
  let(:response) { described_class.new(operation, execution_time) }

  describe '.initialize' do
    subject { response }

    it 'should setup the appropriate values' do
      expect(subject).to be_a(described_class)
      expect(subject.operation).to eq operation
      expect(subject.message).to eq operation.execute
      expect(subject.metadata).to eq operation.metadata
      expect(subject.trailing_metadata).to eq operation.trailing_metadata
      expect(subject.deadline).to eq operation.deadline
      expect(subject.cancelled).to eq operation.cancelled?
    end

    context 'with no specified execution time' do
      it 'should set the execution time to 0.0' do
        expect(subject.execution_time).to eq 0.0
      end
    end

    context 'with no specified execution time' do
      let(:execution_time) { rand(1.00..200.00) }

      it 'should set it to the passed value' do
        expect(subject.execution_time).to eq execution_time
      end
    end
  end

  describe '.message' do
    subject { response.message }

    it 'should return the operation execution result' do
      expect(subject).to eq operation.execute
    end
  end

  describe '.internal_execution_time' do
    subject { response.internal_execution_time }

    context 'when the time is passed through the trailing metadata' do
      it 'should return that time' do
        expect(subject).to eq internal_execution_time
      end
    end

    context 'when no time is passed' do
      let(:trailing_metadata) { {} }

      it 'it should return 0.0' do
        expect(subject).to eq 0.0
      end
    end
  end
end

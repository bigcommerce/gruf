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

describe Gruf::Response do
  let(:internal_execution_time) { rand(1.00..500.00) }
  let(:trailing_metadata) { { 'timer' => internal_execution_time } }
  let(:operation) { build_operation(trailing_metadata: trailing_metadata, execution_time: execution_time) }
  let(:execution_time) { nil }
  let(:message) { Rpc::GetThingResponse.new }
  let(:response) { described_class.new(operation: operation, message: message, execution_time: execution_time) }

  describe '.initialize' do
    subject { response }

    it 'should setup the appropriate values' do
      expect(subject).to be_a(described_class)
      expect(subject.operation).to eq operation
      expect(subject.message).to eq message
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
      expect(subject).to eq message
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

# frozen_string_literal: true

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

describe Gruf::Timer do
  describe '#time' do
    let(:result) { { foo: 'bar' } }

    context 'when the operation yields normally' do
      subject { described_class.time { result } }

      it 'returns a timed result with the proper values' do
        expect(subject).to be_a(Gruf::Timer::Result)
        expect(subject.result).to eq result
        expect(subject.time).to be > 0.00
      end
    end

    context 'when the operation raises an error' do
      subject { described_class.time { raise err } }

      context 'when that is a BadStatus exception' do
        let(:err) { GRPC::Internal.new('ack!') }

        it 'returns the BadStatus as the result with a time' do
          expect(subject).to be_a(Gruf::Timer::Result)
          expect(subject.result).to eq err
          expect(subject.time).to be > 0.00
        end
      end

      context 'when that is a GRPC::Core::CallError' do
        let(:err) { GRPC::Core::CallError.new('really bad things') }

        it 'returns it as the result with a time' do
          expect(subject).to be_a(Gruf::Timer::Result)
          expect(subject.result).to eq err
          expect(subject.time).to be > 0.00
        end
      end

      context 'when that is any other exception' do
        let(:err) { StandardError.new("it's a trap!") }

        it 'returns it as the result with a time' do
          expect(subject).to be_a(Gruf::Timer::Result)
          expect(subject.result).to eq err
          expect(subject.time).to be > 0.00
        end
      end
    end
  end

  describe Gruf::Timer::Result do
    let(:time) { rand(10.00..500.00).to_f }
    let(:result) { {} }
    let(:timed_result) { described_class.new(result, time) }

    describe '#initialize' do
      subject { timed_result }

      it 'sets up and casts the values appropriately' do
        expect(subject).to be_a described_class
        expect(subject.time).to eq time
        expect(subject.result).to eq result
      end
    end

    describe '.success?' do
      subject { timed_result.success? }

      context 'with a normal result' do
        it 'returns true' do
          expect(subject).to be_truthy
        end
      end

      context 'with a BadStatus result' do
        let(:result) { GRPC::BadStatus.new(5, 'Boo', foo: 'bar') }

        it 'returns false' do
          expect(subject).to be_falsey
        end
      end
    end
  end
end

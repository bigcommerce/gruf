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

describe Gruf::Interceptors::Timer do
  describe '#time' do
    context 'when the result does not throw a GRPC::BadStatus exception' do
      subject { described_class.time { message } }

      let(:message) { Rpc::GetThingResponse.new }

      it 'returns a successful result' do
        expect(subject).to be_a(described_class::Result)
        expect(subject).to be_successful
        expect(subject.message).to eq message
        expect(subject.elapsed).not_to be_zero
      end
    end

    context 'when the result does throw a GRPC::BadStatus exception' do
      subject { described_class.time { raise error } }

      let(:error_message) { FFaker::Lorem.sentence }
      let(:error) { GRPC::NotFound.new(error_message) }

      it 'returns an unsuccessful result' do
        expect(subject).to be_a(described_class::Result)
        expect(subject).not_to be_successful
        expect(subject.message).to eq error
        expect(subject.elapsed).not_to be_zero
      end
    end
  end

  describe Gruf::Interceptors::Timer::Result do
    context 'with a successful result' do
      let(:message) { Rpc::GetThingResponse.new }
      let(:result) { Gruf::Interceptors::Timer.time { message } }

      describe '#successful?' do
        subject { result.successful? }

        it 'returns true' do
          expect(subject).to be_truthy
        end
      end

      describe '#message_class_name' do
        subject { result.message_class_name }

        it 'returns the name of the message class' do
          expect(subject).to eq message.class.name
        end
      end

      describe '#elapsed_rounded' do
        subject { result.elapsed_rounded(precision: precision) }

        let(:precision) { 2 }

        it 'rounds the elapsed time' do
          expect(subject).to eq result.elapsed.round(precision)
        end
      end
    end

    context 'with an unsuccessful result' do
      let(:error_message) { FFaker::Lorem.sentence }
      let(:error) { GRPC::NotFound.new(error_message) }
      let(:result) { Gruf::Interceptors::Timer.time { raise error } }

      describe '#successful?' do
        subject { result.successful? }

        it 'returns false' do
          expect(subject).to be_falsey
        end
      end
    end
  end
end

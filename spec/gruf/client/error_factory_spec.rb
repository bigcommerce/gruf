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

describe Gruf::Client::ErrorFactory do
  let(:default_class) { Gruf::Client::Errors::Internal }
  let(:deserializer_class) { Gruf::Serializers::Errors::Json }
  let(:metadata_key) { Gruf.error_metadata_key }
  let(:factory) do
    described_class.new(
      default_class: default_class,
      deserializer_class: deserializer_class,
      metadata_key: metadata_key
    )
  end

  describe '.from_exception' do
    let(:error_message) { FFaker::Lorem.sentence }
    let(:exception) { GRPC::NotFound.new(error_message) }

    subject { factory.from_exception(exception) }


    context 'when the exception is a BadStatus' do
      Gruf::Client::Errors.constants.reject {|e| [:Error, :Validation, :Exception, :Base].include?(e) }.each do |error_class|
        context "and is a GRPC::#{error_class} exception" do
          let(:exception) { "GRPC::#{error_class}".constantize.new(error_message) }
          let(:expected_class) { "Gruf::Client::Errors::#{error_class}".constantize }

          it "should wrap it with the Gruf::Client::Errors::#{error_class} class" do
            expect(subject).to be_a(expected_class)
            expect(subject.error).to eq exception
          end
        end
      end
    end

    context 'when the exception is a StandardError' do
      let(:exception) { StandardError.new(error_message) }

      it 'should wrap it in the default exception class' do
        expect(subject).to be_a(default_class)
        expect(subject.error).to eq exception
      end
    end

    context 'when the exception is a GRPC::Core::CallError' do
      let(:exception) { GRPC::Core::CallError.new(error_message) }

      it 'should wrap it in the default exception class' do
        expect(subject).to be_a(default_class)
        expect(subject.error).to eq exception
      end
    end

    context 'when the exception is a SignalException' do
      let(:exception) { SignalException.new('HUP') }

      it 'should return the original exception' do
        expect(subject).to eq exception
      end
    end
  end
end

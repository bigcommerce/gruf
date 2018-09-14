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

describe Gruf::Error do
  let(:code) { :not_found }
  let(:app_code) { :thing_not_found }
  let(:message) { '' }
  let(:metadata) { {} }
  let(:error) { described_class.new(code: code, app_code: app_code, message: message, metadata: metadata) }
  let(:call) { double(:call, output_metadata: {}) }

  describe '.serialize' do
    subject { error.serialize }

    context 'with the JSON serializer' do
      it 'should return the serialized error in JSON' do
        expected_json = {
          code: code,
          app_code: app_code,
          message: message,
          field_errors: [],
          debug_info: {}
        }.to_json
        expect(subject).to be_a(String)
        expect(subject).to eq expected_json
      end
    end
  end

  describe '.attach_to_call' do
    subject { error.attach_to_call(call) }

    context 'with a provided serializer' do
      context 'with no metadata on the error' do
        it 'should attach the proto metadata' do
          expect(call.output_metadata).to receive(:update)
          expect(subject).to be_a(described_class)
        end
      end

      context 'with metadata on the error' do
        let(:metadata) { { foo: :bar } }
        it 'should attach the proto metadata and custom metadata, and strings for values' do
          expect(call.output_metadata).to receive(:update).with({ foo: 'bar' }.merge('error-internal-bin': error.serialize))
          expect(subject).to be_a(described_class)
        end
      end

      context 'with a very large error message' do
        let(:message) { SecureRandom.hex(described_class::MAX_METADATA_SIZE + 100) }

        it 'should log the original error and replace the outgoing error with a new one' do
          # expect(Gruf.logger).to receive(:warn)
          expect(subject).to be_a(described_class)
          expect(subject.code).to eq(:internal)
          expect(subject.app_code).to eq(described_class::METADATA_SIZE_EXCEEDED_CODE)
          expect(subject.message).to eq(described_class::METADATA_SIZE_EXCEEDED_MSG)
        end
      end
    end
  end

  describe '.metadata=' do
    let(:md) { { foo: 'bar' } }
    let(:expected_md) { { foo: 'bar' } }

    subject { error.metadata = md }
    it 'should set the metadata on the error object' do
      subject
      expect(error.metadata).to eq expected_md
    end

    context 'when some values are not strings' do
      let(:md) { { foo: :bar, abc: 123 } }
      let(:expected_md) { { foo: 'bar', abc: '123' } }

      it 'should serialize all values into strings' do
        subject
        expect(error.metadata).to eq expected_md
      end
    end
  end

  describe '.set_debug_info' do
    let(:detail) { FFaker::Lorem.sentence }
    let(:stack_trace) { FFaker::Lorem.sentences(2) }

    subject { error.set_debug_info(detail, stack_trace) }

    it 'should set the debug info object with the provided arguments' do
      expect(subject).to be_a(Gruf::Errors::DebugInfo)
      expect(subject.detail).to eq detail
      expect(subject.stack_trace).to eq stack_trace
    end
  end

  describe '.add_field_error' do
    let(:field_name) { FFaker::Lorem.word.to_sym }
    let(:error_code) { FFaker::Lorem.word.to_sym }
    let(:message) { FFaker::Lorem.sentence }

    subject { error.add_field_error(field_name, error_code, message) }

    it 'should set a field error with the provided arguments' do
      errors = subject
      expect(errors.last).to be_a(Gruf::Errors::Field)
      expect(errors.last.field_name).to eq field_name
      expect(errors.last.error_code).to eq error_code
      expect(errors.last.message).to eq message
      expect(errors.last.to_h).to eq(
        field_name: field_name,
        error_code: error_code,
        message: message
      )
    end
  end

  describe '.fail!' do
    let(:subject) { error.fail!(call) }

    it 'should fail with the proper grpc error code' do
      expect { subject }.to raise_error(GRPC::NotFound)
    end
  end

  describe 'functional test' do
    let(:id) { 1 }

    context 'with a call that returns a field error' do
      it 'should raise a Gruf::Client::Error and return the unserialized error object', run_thing_server: true do
        client = build_client
        expect do
          resp = client.call(:GetContextualFieldErrorFail, id: 1)
          expect(resp.error).to be_a(Gruf::ErrorHeader)
          expect(resp.error_code).to eq :invalid
          expect(resp.field_errors).to_not be_empty

          fe = resp.field_errors.first
          expect(fe).to_not be_a(Gruf::FieldError)
          expect(fe).to_not be_a(Gruf::FieldError)
        end.to raise_error(Gruf::Client::Errors::InvalidArgument)
      end
    end

    context 'with multiple calls, where the first returns a field error, the second does not' do
      it 'should not raise a Gruf::Client::Error the second time', run_thing_server: true do
        client = build_client
        expect do
          client.call(:GetContextualFieldErrorFail, id: 1)
        end.to raise_error(Gruf::Client::Errors::InvalidArgument)

        expect do
          resp = client.call(:GetContextualFieldErrorFail, id: 2)
          expect(resp.message).to be_a(Rpc::GetThingResponse)
        end.to_not raise_error
      end
    end

    context 'with multiple calls, with multiple having field errors' do
      it 'should not aggregate errors across calls', run_thing_server: true do
        ts = []
        10.times do
          ts << Thread.new do
            sleep(rand(0.001..1))
            client = build_client
            expect do
              resp = client.call(:GetContextualFieldErrorFail, id: 1)
              expect(resp.error).to be_a(Gruf::ErrorHeader)
              expect(resp.field_errors.count).to eq(1)
            end.to raise_error(Gruf::Client::Errors::InvalidArgument)
          end
        end
        ts.map(&:join)

        expect do
          client = build_client
          resp = client.call(:GetContextualFieldErrorFail, id: 2)
          expect(resp.message).to be_a(Rpc::GetThingResponse)
        end.to_not raise_error
      end
    end

    context 'with a call that returns no errors' do
      it 'should raise no errors', run_thing_server: true do
        client = build_client
        expect do
          resp = client.call(:GetThing, id: 1)
          expect(resp.message).to be_a(Rpc::GetThingResponse)
        end.to_not raise_error
      end
    end
  end

  context 'with a call that raises an exception' do
    it 'should fail with an internal error message', run_thing_server: true do
      client = build_client
      expect do
        resp = client.call(:GetException, id: 1)
        expect(resp.error).to be_a(Gruf::ErrorHeader)
        expect(resp.error_code).to eq :internal
      end.to raise_error(Gruf::Client::Errors::Internal)
    end
  end
end

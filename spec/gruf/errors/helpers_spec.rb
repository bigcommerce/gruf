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

describe ::Gruf::Errors::Helpers do
  let(:rpc_service) { ::Rpc::ThingService::Service }
  let(:rpc_desc) { Rpc::ThingService::Service.rpc_descs.values.first }
  let(:message) { Rpc::GetThingRequest.new(id: 1) }
  let(:metadata) { { foo: 'bar' } }
  let(:controller_class) { ThingController }
  let(:controller) do
    controller_class.new(
      method_key: :get_thing,
      service: rpc_service,
      active_call: Rpc::Test::Call.new,
      message: message,
      rpc_desc: rpc_desc
    )
  end

  describe '#fail!' do
    subject { controller.fail!(error_code, app_code, error_message, metadata) }

    let(:error_code) { :not_found }
    let(:error_message) { 'Thing 1 not found!' }
    let(:app_code) { :thing_not_found }

    it 'calls fail! on the error and sets the appropriate values' do
      expect { subject }.to raise_error(GRPC::NotFound) do |e|
        expect(e.code).to eq GRPC::Core::StatusCodes::NOT_FOUND
        expect(e.message).to eq "#{GRPC::Core::StatusCodes::NOT_FOUND}:#{error_message}"
        expect(e.metadata.except(:'error-internal-bin')).to eq metadata

        parsed_error = JSON.parse(e.metadata[:'error-internal-bin']).deep_symbolize_keys
        expect(parsed_error[:code]).to eq error_code.to_s
        expect(parsed_error[:app_code]).to eq app_code.to_s
        expect(parsed_error[:message]).to eq error_message.to_s
      end
    end
  end

  describe '#has_field_errors?' do
    subject { controller.has_field_errors? }

    context 'when there are field errors' do
      before do
        controller.add_field_error(:name, :invalid, 'Invalid name')
      end

      it 'returns true' do
        expect(subject).to be_truthy
      end
    end

    context 'when there are no field errors' do
      it 'returns false' do
        expect(subject).to be_falsey
      end
    end
  end

  describe '#set_debug_info' do
    subject { controller.set_debug_info(detail, stack_trace) }

    let(:detail) { FFaker::Lorem.sentence }
    let(:stack_trace) { FFaker::Lorem.sentences(2) }
    let(:error) { controller.error }

    it 'passes through to the error call' do
      expect(error).to receive(:set_debug_info).with(detail, stack_trace)
      subject
    end
  end

  describe '#error' do
    subject { controller.error }

    it 'returns a Gruf::Error object' do
      expect(subject).to be_a(Gruf::Error)
    end
  end
end

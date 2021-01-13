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

describe ::Gruf::Controllers::Base do
  let(:rpc_service) { ::Rpc::ThingService::Service }
  let(:rpc_desc) { Rpc::ThingService::Service.rpc_descs.values.first }
  let(:message) { Rpc::GetThingRequest.new(id: 1) }
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

  describe '#bind' do
    it 'binds the controller to the service and generates the methods' do
      expect(Gruf.services).to include(rpc_service)
      expect(rpc_service.instance_methods).to include(:get_thing)
      expect(controller_class.instance_methods).to include(:get_thing)
    end

    it 'binds the service name to the service class' do
      expect(controller_class.bound_service).to eq rpc_service
    end

    it 'does not bind the service name to the base class' do
      expect(Gruf::Controllers::Base.bound_service).to be_nil
    end
  end

  describe '#call' do
    subject { controller.call(:get_thing) }

    it 'exposes the methods properly' do
      expect(subject).to be_a(Rpc::GetThingResponse)
    end

    context 'when there are interceptors' do
      it 'passes the request to interceptors' do
        Gruf.interceptors.use(TestServerInterceptor)
        expect(subject).to be_a(Rpc::GetThingResponse)
      end
    end

    context 'when the call results in a GRPC::BadStatus error' do
      let(:error_message) { FFaker::Lorem.sentence }

      before do
        allow(controller).to receive(:get_thing).and_raise(GRPC::NotFound, error_message)
      end

      it 'passes through the error' do
        expect { subject }.to raise_error(GRPC::NotFound) do |e|
          expect(e.message).to eq "#{GRPC::Core::StatusCodes::NOT_FOUND}:#{error_message}"
        end
      end
    end

    context 'when the call results in an uncaught error' do
      let(:error_message) { FFaker::Lorem.sentence }
      let(:error) { Gruf::Error.new(code: :internal, app_code: :unknown, message: error_message) }

      before do
        allow(controller).to receive(:get_thing).and_raise(StandardError, error_message)
      end

      it 'raises a GRPC::Internal error' do
        expect { subject }.to raise_error(GRPC::Internal) do |e|
          expect(e.code).to eq GRPC::Core::StatusCodes::INTERNAL
          expect(e.message).to eq "#{GRPC::Core::StatusCodes::INTERNAL}:#{error_message}"
          expect(e.metadata).to eq('error-internal-bin': error.serialize)
        end
      end

      context 'when backtrace_on_error is set to true' do
        before do
          Gruf.backtrace_on_error = true
        end

        it 'attaches a backtrace' do
          expect { subject }.to raise_error(GRPC::Internal) do |e|
            parsed_error = JSON.parse(e.metadata[:'error-internal-bin'])
            expect(parsed_error['debug_info']).not_to be_empty
            expect(parsed_error['debug_info']['stack_trace']).not_to be_empty
          end
        end
      end

      context 'when we override the base exception message' do
        let(:error_message) { FFaker::Lorem.word }

        before do
          Gruf.use_exception_message = false
          Gruf.internal_error_message = error_message
        end

        it 'raises a GRPC::Internal error with the correct message' do
          expect { subject }.to raise_error(GRPC::Internal) do |e|
            expect(e).to be_a(GRPC::Internal)
            expect(e.code).to eq GRPC::Core::StatusCodes::INTERNAL
            expect(e.message).to eq "#{GRPC::Core::StatusCodes::INTERNAL}:#{error_message}"
          end
        end
      end

      context 'when we enable the internal exception message config' do
        before do
          Gruf.use_exception_message = false
        end

        it 'raises a GRPC::Internal error and uses e.message' do
          expect { subject }.to raise_error(GRPC::Internal) do |e|
            expect(e).to be_a(GRPC::Internal)
            expect(e.code).to eq GRPC::Core::StatusCodes::INTERNAL
            expect(e.message).to eq "#{GRPC::Core::StatusCodes::INTERNAL}:#{Gruf.internal_error_message}"
          end
        end
      end
    end
  end
end

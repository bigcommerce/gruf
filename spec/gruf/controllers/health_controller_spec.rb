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

describe ::Gruf::Controllers::HealthController do
  let(:rpc_service) { ::Grpc::Health::V1::Health::Service }
  let(:rpc_desc) { rpc_service.rpc_descs.values.first }
  let(:message) { ::Grpc::Health::V1::HealthCheckRequest.new }
  let(:controller) do
    described_class.new(
      method_key: :get_thing,
      service: rpc_service,
      active_call: Rpc::Test::Call.new,
      message: message,
      rpc_desc: rpc_desc
    )
  end

  describe '#check' do
    subject { controller.check }

    let(:response) do
      ::Grpc::Health::V1::HealthCheckResponse.new(
        status: ::Grpc::Health::V1::HealthCheckResponse::ServingStatus::SERVING
      )
    end

    context 'when Gruf.health_check_hook is nil' do
      it 'returns a serving response' do
        expect(subject).to eq response
      end
    end

    context 'when Gruf.health_check_hook responds to call' do
      before do
        Gruf.health_check_hook = lambda do |_request, _error|
          Math.sqrt(4)
          response
        end
      end

      it 'returns a health check response, calling the proc instead' do
        expect(Math).to receive(:sqrt).with(4).once
        expect(subject).to eq response
      end
    end
  end
end

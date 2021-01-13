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

describe Gruf::Interceptors::Instrumentation::RequestLogging::Formatters::Plain do
  let(:formatter) { described_class.new }
  let(:status) { 'GRPC::Ok' }
  let(:route_key) { 'thing_service.get_thing' }
  let(:execution_time) { 0.001 }
  let(:message) { 'foo' }
  let(:params) { { id: 1 } }
  let(:request) { build :controller_request }
  let(:result) { Gruf::Interceptors::Timer.time { Rpc::GetThingResponse.new } }
  let(:payload) { { message: message, status: status, method: route_key, duration: execution_time, params: params } }

  describe '#format' do
    subject { formatter.format(payload, request: request, result: result) }

    context 'when params are sent to the formatter' do
      it 'returns the message, without params' do
        expect(subject).to eq(
          "[#{status}] (#{route_key}) [#{execution_time}ms] #{message} Parameters: #{params.to_h}".strip
        )
      end
    end

    context 'when params are not sent to the formatter' do
      let(:payload) { super().except(:params) }

      it 'returns the message' do
        expect(subject).to eq "[#{status}] (#{route_key}) [#{execution_time}ms] #{message}".strip
      end
    end
  end
end

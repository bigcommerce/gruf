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

describe Gruf::Interceptors::ServerInterceptor do
  let(:interceptor) { TestServerInterceptor }
  let(:interceptor_args) { {} }
  let(:interceptors) { { interceptor => interceptor_args } }

  describe 'statelessness' do
    let(:interceptor) { TestServerInterceptorInstanceVar }

    it 'does not persist interceptor instance variables across requests', run_thing_server: true do
      client = build_client
      resp = client.call(:GetThing)
      expect(resp.message).to be_a(Rpc::GetThingResponse)
      resp = client.call(:GetThing)
      expect(resp.message).to be_a(Rpc::GetThingResponse)
    end
  end

  describe '#call' do
    subject { interceptor.new(request, error, {}).call }

    let(:request) { build :controller_request }
    let(:error) { build :error }

    context 'when it is not extended' do
      let(:interceptor) { described_class }

      it 'raises a NotImplementedError' do
        expect { subject }.to raise_error(NotImplementedError)
      end
    end
  end
end

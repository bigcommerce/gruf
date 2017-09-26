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

describe Gruf::Server do
  let(:options) { {} }
  let(:gruf_server) { described_class.new(options) }
  subject { gruf_server }

  describe '#start!' do
    let(:server_mock) { double(GRPC::RpcServer, add_http2_port: nil, run_till_terminated: nil) }

    context 'when options passed' do
      let(:options) { { pool_size: 1 } }

      it 'runs server with given configuration' do
        expect(GRPC::RpcServer).to receive(:new).with(options).and_return(server_mock)
        gruf_server.start!
      end
    end

    context 'when no options passed' do
      it 'runs server with empty configuration' do
        expect(GRPC::RpcServer).to receive(:new).with({}).and_return(server_mock)
        gruf_server.start!
      end
    end
  end

  describe '.add_service' do
    let(:service) { Rpc::ThingService }
    subject { gruf_server.add_service(service) }

    context 'if the service is not yet in the registry' do
      it 'should add a service to the registry' do
        expect { subject }.to(change { gruf_server.instance_variable_get('@services').count }.by(1))
        expect(gruf_server.instance_variable_get('@services')).to eq [service]
      end
    end

    context 'if the service is already in the registry' do
      it 'should not add the service' do
        gruf_server.add_service(service)
        expect { subject }.to_not(change { gruf_server.instance_variable_get('@services').count })
      end
    end
  end

  describe '.add_interceptor' do
    let(:interceptor_class) { TestServerInterceptor }
    let(:options) { { foo: 'bar' } }
    subject { gruf_server.add_interceptor(interceptor_class, options) }

    before do
      Gruf.interceptors.clear
    end

    it 'should add the interceptor to the registry' do
      expect { subject }.to(change { gruf_server.instance_variable_get('@interceptors').count }.by(1))
      is = gruf_server.instance_variable_get('@interceptors').prepare(nil, nil)
      i = is.first
      expect(i).to be_a(interceptor_class)
      expect(i.options).to eq options
    end
  end
end

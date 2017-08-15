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
  let(:services) { [] }
  let(:gruf_server) { described_class.new(services: services) }
  subject { gruf_server }

  describe '.load_services' do
    context 'when passed no services' do
      context 'but some are configured in initializer' do
        before do
          Gruf.configure do |c|
            c.services << ThingService
            c.services << ThingService
          end
        end

        it 'should return all services loaded in configuration uniquely' do
          expect(subject.services).to eq [ThingService]
        end
      end

      context 'and none are configured in initializer' do
        before do
          Gruf.configure do |c|
            c.services = []
          end
        end

        it 'should return an empty array' do
          expect(subject.services).to eq []
        end
      end
    end

    context 'when passed a service' do
      let(:services) { [ThingService] }

      context 'and some are configured in an initializer' do
        before do
          Gruf.configure do |c|
            c.services << ThingService
            c.services << ThingService
          end
        end

        it 'should return all services loaded in configuration uniquely' do
          expect(subject.services).to eq [ThingService]
        end
      end

      context 'and none are configured in initializer' do
        before do
          Gruf.configure do |c|
            c.services = []
          end
        end

        it 'should return all services loaded in configuration uniquely' do
          expect(subject.services).to eq services
        end
      end
    end
  end

  describe '#start!' do
    let(:server_mock) { double(GRPC::RpcServer, add_http2_port: nil, run_till_terminated: nil) }

    context 'when server_options passed' do
      let(:configuration) { { pool_size: 5 } }

      before do
        Gruf.configure do |c|
          c.server_options = configuration
          c.services = []
        end
      end

      it 'runs server with given configuration' do
        expect(GRPC::RpcServer).to receive(:new).with(configuration).and_return(server_mock)

        gruf_server.start!
      end
    end

    context 'when no server_options passed' do
      before do
        Gruf.configure do |c|
          c.server_options = {}
          c.services = []
        end
      end

      it 'runs server with empty configuration' do
        expect(GRPC::RpcServer).to receive(:new).with({}).and_return(server_mock)

        gruf_server.start!
      end
    end
  end
end

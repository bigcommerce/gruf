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

describe Gruf::Cli::Executor do
  let(:args) { [] }
  let(:server) { double(:server, add_service: true, start!: true) }
  let(:services) { [Rpc::ThingService::Service] }
  let(:hook_executor) { double(:hook_executor, call: true) }
  let(:logger) { Gruf.logger }
  let(:executor) do
    described_class.new(
      args,
      server: server,
      services: services,
      hook_executor: hook_executor,
      logger: logger
    )
  end

  describe '.run' do
    subject { executor.run }

    it 'should add each specified service to the server' do
      services.each do |svc|
        expect(server).to receive(:add_service).ordered.with(svc)
      end
      expect(hook_executor).to receive(:call).with(:before_server_start, server: server).once
      expect(server).to receive(:start!).once
      expect(logger).to_not receive(:fatal)
      expect(hook_executor).to receive(:call).with(:after_server_stop, server: server).once
      subject
    end

    context 'if the server raises an exception' do
      let(:exception) { StandardError.new('Failure') }

      before do
        expect(server).to receive(:start!).once.and_raise(exception)
      end

      it 'should still run the pre and post hooks' do
        expect(hook_executor).to receive(:call).with(:before_server_start, server: server).once
        expect(logger).to receive(:fatal).once
        expect(hook_executor).to receive(:call).with(:after_server_stop, server: server).once
        expect { subject }.to raise_error(exception)
      end
    end

    context 'if the before hook raises an exception' do
      let(:exception) { StandardError.new('Failure') }

      it 'should still run the post hooks' do
        expect(hook_executor).to receive(:call).with(:before_server_start, server: server).and_raise(exception)
        expect(logger).to receive(:fatal).once
        expect(hook_executor).to receive(:call).with(:after_server_stop, server: server).once
        expect { subject }.to raise_error(exception)
      end
    end

  end

  describe '.setup!' do
    let(:interceptors) { Gruf.interceptors.list }

    subject { executor }

    before do
      Gruf.reset
    end

    context 'if --host is' do
      context 'passed' do
        let(:args) { %w[--host 0.0.0.0:9999] }

        it 'should set server_binding_url to the host' do
          subject
          expect(Gruf.server_binding_url).to eq '0.0.0.0:9999'
        end
      end

      context 'not passed' do
        let(:args) { [] }

        it 'should set server_binding_url to the default host' do
          subject
          expect(Gruf.server_binding_url).to eq '0.0.0.0:9001'
        end
      end
    end

    context 'if --suppress-default-interceptors is' do
      context 'passed' do
        let(:args) { %w[--suppress-default-interceptors] }

        it 'should unset the default interceptors' do
          subject
          expect(interceptors).to be_empty
        end
      end

      context 'not passed' do
        let(:args) { [] }

        it 'should leave the default interceptors intact' do
          subject
          expect(interceptors.count).to eq 2
          expect(interceptors).to include(Gruf::Interceptors::ActiveRecord::ConnectionReset)
          expect(interceptors).to include(Gruf::Interceptors::Instrumentation::OutputMetadataTimer)
        end
      end
    end

    context 'if --backtrace-on-error is' do
      context 'passed' do
        let(:args) { %w[--backtrace-on-error] }
        it 'should set backtrace_on_error to true' do
          subject
          expect(Gruf.backtrace_on_error).to be_truthy
        end
      end

      context 'not passed' do
        it 'should leave backtrace_on_error at the default value' do
          subject
          expect(Gruf.backtrace_on_error).to be_falsey
        end
      end
    end
  end
end

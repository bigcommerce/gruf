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

describe Gruf::Cli::Executor do
  let(:args) { [] }
  let(:server) { double(:server, add_service: true, start!: true) }
  let(:services) { [Rpc::ThingService::Service] }
  let(:options_services) { services }
  let(:hook_executor) { double(:hook_executor, call: true) }
  let(:logger) { Gruf.logger }
  let(:executor) do
    described_class.new(
      args,
      server: server,
      services: options_services,
      hook_executor: hook_executor,
      logger: logger
    )
  end

  describe '#run' do
    subject { executor.run }

    it 'adds each specified service to the server' do
      services.each do |svc|
        expect(server).to receive(:add_service).ordered.with(svc)
      end
      expect(hook_executor).to receive(:call).with(:before_server_start, server: server).once
      expect(server).to receive(:start!).once
      expect(logger).not_to receive(:fatal)
      expect(hook_executor).to receive(:call).with(:after_server_stop, server: server).once
      subject
    end

    context 'when services are set via the Gruf.services accessor' do
      let(:options_services) { [] }
      let(:global_services) { [Rpc::ThingService::Service] }

      before do
        global_services.each do |svc|
          ::Gruf.services << svc
        end
      end

      after do
        ::Gruf.services = []
      end

      it 'adds each specified service to the server' do
        expect(hook_executor).to receive(:call).with(:before_server_start, server: server).once
        expect(server).to receive(:start!).once
        global_services.each do |svc|
          expect(server).to receive(:add_service).with(svc).ordered
        end
        expect(logger).not_to receive(:fatal)
        expect(hook_executor).to receive(:call).with(:after_server_stop, server: server).once
        subject
      end
    end

    context 'when services are set via options accessor' do
      let(:options_services) { services }
      let(:global_services) { [Rpc::ThingService::Service] }

      before do
        ::Gruf.services = []
      end

      it 'adds each specified service to the server' do
        expect(hook_executor).to receive(:call).with(:before_server_start, server: server).once
        expect(server).to receive(:start!).once
        services.each do |svc|
          expect(server).to receive(:add_service).with(svc).ordered
        end
        expect(logger).not_to receive(:fatal)
        expect(hook_executor).to receive(:call).with(:after_server_stop, server: server).once
        subject
      end
    end

    context 'when no services are set in either Gruf.services or passed in as options' do
      let(:options_services) { [] }

      before do
        Gruf.services = []
      end

      it 'raises a NoServicesBoundError exception' do
        expect { subject }.to raise_error(Gruf::Cli::Executor::NoServicesBoundError)
      end
    end

    context 'when the server raises an exception' do
      let(:exception) { StandardError.new('Failure') }

      before do
        allow(server).to receive(:start!).once.and_raise(exception)
      end

      it 'still runs the pre and post hooks' do
        expect(hook_executor).to receive(:call).with(:before_server_start, server: server).once
        expect(logger).to receive(:fatal).once
        expect(hook_executor).to receive(:call).with(:after_server_stop, server: server).once
        expect { subject }.to raise_error(exception)
      end
    end

    context 'when the before hook raises an exception' do
      let(:exception) { StandardError.new('Failure') }

      it 'still runs the post hooks' do
        expect(hook_executor).to receive(:call).with(:before_server_start, server: server).and_raise(exception)
        expect(logger).to receive(:fatal).once
        expect(hook_executor).to receive(:call).with(:after_server_stop, server: server).once
        expect { subject }.to raise_error(exception)
      end
    end
  end

  describe '#setup!' do
    subject { executor }

    let(:interceptors) { Gruf.interceptors.list }

    before do
      Gruf.reset
    end

    context 'when --host is' do
      context 'when --host is passed' do
        let(:args) { %w[--host 0.0.0.0:9999] }

        it 'sets server_binding_url to the host' do
          subject
          expect(Gruf.server_binding_url).to eq '0.0.0.0:9999'
        end
      end

      context 'when --host is not passed' do
        let(:args) { [] }

        it 'sets server_binding_url to the default host' do
          subject
          expect(Gruf.server_binding_url).to eq '0.0.0.0:9001'
        end
      end
    end

    context 'when --suppress-default-interceptors is' do
      context 'when --suppress-default-interceptors is passed' do
        let(:args) { %w[--suppress-default-interceptors] }

        it 'unsets the default interceptors' do
          subject
          expect(interceptors).to be_empty
        end
      end

      context 'when --suppress-default-interceptors is not passed' do
        let(:args) { [] }

        it 'leaves the default interceptors intact' do
          subject
          expect(interceptors.count).to eq 2
          expect(interceptors).to include(Gruf::Interceptors::ActiveRecord::ConnectionReset)
          expect(interceptors).to include(Gruf::Interceptors::Instrumentation::OutputMetadataTimer)
        end
      end
    end

    context 'when --backtrace-on-error is' do
      context 'when --backtrace-on-error is passed' do
        let(:args) { %w[--backtrace-on-error] }

        it 'sets backtrace_on_error to true' do
          subject
          expect(Gruf.backtrace_on_error).to be_truthy
        end
      end

      context 'when --backtrace-on-error is not passed' do
        it 'leaves backtrace_on_error at the default value' do
          subject
          expect(Gruf.backtrace_on_error).to be_falsey
        end
      end
    end
  end
end

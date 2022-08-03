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
  let(:initializer_services) { [::Rpc::Test::Service1::Service] }
  let(:cli_services) { [] }
  let(:global_services) { [] }
  let(:hook_executor) { double(:hook_executor, call: true) }
  let(:logger) { Gruf.logger }
  let(:executor) do
    described_class.new(
      args,
      server: server,
      services: initializer_services,
      hook_executor: hook_executor,
      logger: logger
    )
  end

  before do
    ::Gruf.reset
    ::Gruf.services = global_services
  end

  after do
    ::Gruf.services = []
  end

  describe '#run' do
    subject { executor.run }

    it 'adds each specified service to the server' do
      initializer_services.each do |svc|
        expect(server).to receive(:add_service).ordered.with(svc)
      end
      expect(hook_executor).to receive(:call).with(:before_server_start, server: server).once
      expect(server).to receive(:start!).once
      expect(logger).not_to receive(:fatal)
      expect(hook_executor).to receive(:call).with(:after_server_stop, server: server).once
      subject
    end

    context 'when services are set via the initializer args' do
      let(:initializer_services) { [Rpc::Test::Service1::Service] }
      let(:cli_services) { [Rpc::Test::Service2::Service] }
      let(:global_services) { [Rpc::Test::Service3::Service] }

      it 'adds only initializer args services to the server' do
        expect(hook_executor).to receive(:call).with(:before_server_start, server: server).once
        expect(server).to receive(:start!).once
        initializer_services.each do |svc|
          expect(server).to receive(:add_service).with(svc).ordered
        end
        expect(logger).not_to receive(:fatal)
        expect(hook_executor).to receive(:call).with(:after_server_stop, server: server).once
        subject
      end
    end

    context 'when services are set via the CLI argument' do
      let(:initializer_services) { [] }
      let(:cli_services) { [Rpc::Test::Service2::Service] }
      let(:global_services) { [Rpc::Test::Service3::Service] }
      let(:args) { %w[--services Rpc::Test::Service2::Service] }

      it 'adds each specified service to the server' do
        expect(hook_executor).to receive(:call).with(:before_server_start, server: server).once
        expect(server).to receive(:start!).once
        cli_services.each do |svc|
          expect(server).to receive(:add_service).with(svc).ordered
        end
        expect(logger).not_to receive(:fatal)
        expect(hook_executor).to receive(:call).with(:after_server_stop, server: server).once
        subject
      end

      context 'when the CLI argument has a service that does not exist' do
        let(:args) { %w[--services FakeServiceThatIsNotReal::AtAll] }

        it 'does not run the server' do
          expect(server).not_to receive(:start!)
          expect(hook_executor).not_to receive(:call).with(:before_server_start, server: server)
          expect(hook_executor).not_to receive(:call).with(:after_server_stop, server: server)
          expect(logger).to receive(:fatal).with(
            /FATAL ERROR: Could not start server; passed services to run are not loaded or valid constants:/
          )
          expect { subject }.to raise_error(SystemExit)
        end
      end
    end

    context 'when services are set via the Gruf.services global accessor' do
      let(:initializer_services) { [] }
      let(:cli_services) { [] }
      let(:global_services) { [Rpc::Test::Service3::Service] }

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

      context 'when the health check is enabled' do
        let(:initializer_services) { [] }
        let(:cli_services) { [] }
        let(:args) { %w[--health-check] }

        it 'registers the health check' do
          expect(hook_executor).to receive(:call).with(:before_server_start, server: server).once
          expect(server).to receive(:start!).once
          global_services.each do |svc|
            expect(server).to receive(:add_service).with(svc).ordered
          end
          expect(server).to receive(:add_service).with(::Grpc::Health::V1::Health::Service).ordered
          expect(logger).not_to receive(:fatal)
          expect(hook_executor).to receive(:call).with(:after_server_stop, server: server).once
          subject
        end
      end
    end

    context 'when no services are set in either the initializer, ARGV, or Gruf.services' do
      let(:initializer_services) { [] }
      let(:cli_services) { [] }
      let(:global_services) { [] }

      it 'exits and fails cleanly' do
        expect(server).not_to receive(:start!)
        expect(hook_executor).not_to receive(:call).with(:before_server_start, server: server)
        expect(hook_executor).not_to receive(:call).with(:after_server_stop, server: server)
        expect(logger).to receive(:fatal).with(
          'FATAL ERROR: No services bound to this gruf process; please bind a service to a Gruf ' \
          'controller to start the server successfully'
        )
        expect { subject }.to raise_error(SystemExit)
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

    context 'with --host' do
      context 'when passed' do
        let(:args) { %w[--host 0.0.0.0:9999] }

        it 'sets server_binding_url to the host' do
          subject
          expect(Gruf.server_binding_url).to eq '0.0.0.0:9999'
        end
      end

      context 'when not passed' do
        let(:args) { [] }

        it 'sets server_binding_url to the default host' do
          subject
          expect(Gruf.server_binding_url).to eq '0.0.0.0:9001'
        end
      end
    end

    context 'with --suppress-default-interceptors' do
      context 'when passed' do
        let(:args) { %w[--suppress-default-interceptors] }

        it 'unsets the default interceptors' do
          subject
          expect(interceptors).to be_empty
        end
      end

      context 'when not passed' do
        let(:args) { [] }

        it 'leaves the default interceptors intact' do
          subject
          expect(interceptors.count).to eq 2
          expect(interceptors).to include(Gruf::Interceptors::ActiveRecord::ConnectionReset)
          expect(interceptors).to include(Gruf::Interceptors::Instrumentation::OutputMetadataTimer)
        end
      end
    end

    context 'with --backtrace-on-error' do
      context 'when passed' do
        let(:args) { %w[--backtrace-on-error] }

        it 'sets backtrace_on_error to true' do
          subject
          expect(Gruf.backtrace_on_error).to be_truthy
        end
      end

      context 'when not passed' do
        it 'leaves backtrace_on_error at the default value' do
          subject
          expect(Gruf.backtrace_on_error).to be_falsey
        end
      end
    end

    context 'with --health-check' do
      context 'when passed' do
        let(:args) { %w[--health-check] }

        it 'sets health_check_enabled to true' do
          subject
          expect(Gruf.health_check_enabled).to be_truthy
        end
      end

      context 'when not passed' do
        let(:args) { %w[] }

        it 'leaves health_check_enabled alone' do
          Gruf.health_check_enabled = false
          subject
          expect(Gruf.health_check_enabled).to be_falsey
        end
      end
    end
  end
end

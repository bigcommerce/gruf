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
end

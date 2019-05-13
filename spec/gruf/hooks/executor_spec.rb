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

describe Gruf::Hooks::Executor do
  let(:hook1) { TestHook1.new }
  let(:hook2) { TestHook2.new }
  let(:hook3) { TestHook3.new }
  let(:hooks) { [hook1, hook2, hook3] }
  let(:executor) { described_class.new(hooks: hooks) }

  describe '.call' do
    let(:cmd) { :before_server_start }
    let(:arguments) { { foo: :bar } }

    subject { executor.call(cmd, arguments) }

    context 'if the hook has the command' do
      it 'should run the command for each hook' do
        expect(hook1).to receive(:send).with(cmd, arguments).once
        expect(hook2).to receive(:send).with(cmd, arguments).once
        expect(hook3).to receive(:send).with(cmd, arguments).once
        subject
      end
    end

    context 'if the hook does not have the command' do
      let(:cmd) { :a_fake_hook_point_that_never_exists }

      it 'should not execute against hooks that do not have it defined' do
        expect(hook1).to_not receive(:send).with(cmd, arguments)
        subject
      end
    end

    context 'when some hooks have the method and others do not' do
      let(:cmd) { :after_server_stop }

      it 'should run only against the appropriate hooks' do
        expect(hook1).to receive(:send).with(cmd, arguments).once
        expect(hook2).to receive(:send).with(cmd, arguments).once
        expect(hook3).to_not receive(:send).with(cmd, arguments)
        subject
      end
    end

    context 'if the second hook raises an exception' do
      let(:exception) { StandardError.new('Failure') }

      before do
        allow(hook2).to receive(:send).with(cmd, arguments).and_raise(exception)
      end

      it 'the third hook should not execute, but the first should' do
        expect(hook1).to receive(:send).with(cmd, arguments).once
        expect(hook3).to_not receive(:send).with(cmd, arguments)
        expect { subject }.to raise_error(exception)
      end
    end
  end
end

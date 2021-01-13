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

describe Gruf::Hooks::Registry do
  let(:registry) { described_class.new }
  let(:hook_class) { TestHook1 }
  let(:hook_class2) { TestHook2 }
  let(:hook_class3) { TestHook3 }
  let(:hook_class4) { TestHook4 }
  let(:hook_options) { { one: 'two' } }

  describe '#use' do
    subject { registry.use(hook_class, hook_options) }

    it 'adds the hook to the registry' do
      expect { subject }.not_to raise_error
      expect(registry.count).to eq 1
      expect(registry.instance_variable_get('@registry').first).to eq(
        klass: hook_class,
        options: hook_options
      )
    end
  end

  describe '#insert_before' do
    subject { registry.insert_before(hook_class3, hook_class4, hook_options) }

    context 'when the before hook exists in the registry' do
      before do
        registry.use(hook_class)
        registry.use(hook_class2)
        registry.use(hook_class3)
      end

      it 'inserts the hook before it in the registry' do
        expect { subject }.not_to raise_error

        reg = registry.instance_variable_get('@registry')
        expect(reg[2][:klass]).to eq(hook_class4)
        expect(reg[3][:klass]).to eq(hook_class3)
      end
    end

    context 'when the before hook does not exist in the registry' do
      before do
        registry.use(hook_class)
        registry.use(hook_class2)
      end

      it 'raises a HookNotFoundError' do
        expect { subject }.to raise_error(described_class::HookNotFoundError)
      end
    end
  end

  describe '#insert_after' do
    subject { registry.insert_after(hook_class2, hook_class3, hook_options) }

    context 'when the before hook exists in the registry' do
      before do
        registry.use(hook_class)
        registry.use(hook_class2)
        registry.use(hook_class4)
      end

      it 'inserts the hook before it in the registry' do
        expect { subject }.not_to raise_error

        reg = registry.instance_variable_get('@registry')
        expect(reg[2][:klass]).to eq(hook_class3)
        expect(reg[1][:klass]).to eq(hook_class2)
      end
    end

    context 'when the before hook does not exist in the registry' do
      before do
        registry.use(hook_class)
        registry.use(hook_class4)
      end

      it 'raises a HookNotFoundError' do
        expect { subject }.to raise_error(described_class::HookNotFoundError)
      end
    end
  end

  describe '#remove' do
    subject { registry.remove(hook_class) }

    before do
      registry.use(hook_class2)
      registry.use(hook_class3)
    end

    context 'when the hook is in the registry' do
      before do
        registry.use(hook_class)
      end

      it 'removes the hook from the registry' do
        expect { subject }.not_to raise_error
        expect(registry.count).to eq 2
      end
    end

    context 'when the hook is not in the registry' do
      it 'raises an HookNotFoundError exception' do
        expect { subject }.to raise_error(described_class::HookNotFoundError)
      end
    end
  end

  describe '#clear' do
    subject { registry.clear }

    before do
      registry.use(hook_class)
      registry.use(hook_class2)
    end

    it 'clears the registry of hooks' do
      expect { subject }.not_to raise_error
      expect(registry.count).to be_zero
    end
  end

  describe '#count' do
    subject { registry.count }

    context 'with no hooks' do
      it 'returns 0' do
        expect(subject).to be_zero
      end
    end

    context 'with one hook' do
      before do
        registry.use(hook_class)
      end

      it 'returns 1' do
        expect(subject).to eq 1
      end
    end

    context 'with multiple hooks' do
      before do
        registry.use(hook_class)
        registry.use(hook_class2)
        registry.use(hook_class3)
      end

      it 'returns the number' do
        expect(subject).to eq 3
      end
    end
  end

  describe '#prepare' do
    subject { registry.prepare }

    before do
      registry.use(hook_class)
      registry.use(hook_class3)
      registry.use(hook_class2)
    end

    it 'returns all the hooks prepared by the request and maintains insertion order' do
      prepped = subject
      expect(prepped.count).to eq 3
      expect(prepped[0]).to be_a(hook_class)
      expect(prepped[1]).to be_a(hook_class3)
      expect(prepped[2]).to be_a(hook_class2)
    end
  end
end

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

describe Gruf::Authentication::Strategies do
  let(:registry) { described_class }
  before do
    registry.clear
  end

  describe '#add' do
    let(:hook_name) { :test_hook }

    context 'when the hook is a class' do
      let(:hook_class) { TestAuthenticationHook }
      subject { registry.add(hook_name, hook_class) }

      context 'when the hook properly extends Gruf::Authentication::Base' do
        it 'should be added to the list of strategies' do
          expect(subject).to eq hook_class
          expect(registry[hook_name]).to eq hook_class
        end
      end

      context 'when the hook does not extend Gruf::Authentication::Base' do
        let(:hook_class) { TestInvalidInheritanceAuthenticationHook }
        it 'should raise a HookDescendantError' do
          expect { subject }.to raise_error(Gruf::Authentication::Strategies::StrategyDescendantError)
        end
      end
    end

    context 'when the hook is a block' do
      subject do
        registry.add(hook_name) do
          def call
            true
          end
        end
      end

      it 'should add the hook as a proc implemented using the base hook' do
        expect(subject).to be_a(Class)
        expect(registry[hook_name]).to_not be_nil
      end
    end
  end

  describe '#[]' do
    let(:hook_class) { TestAuthenticationHook }
    let(:hook_name) { :test }

    subject { registry }

    context 'when the hook exists with the given key' do
      before do
        registry.add(hook_name, hook_class)
      end

      it 'should return the hook class' do
        expect(subject[hook_name]).to eq hook_class
      end
    end

    context 'when no hook exists with the given key' do
      it 'should return nil' do
        expect(subject[hook_name]).to be_nil
      end
    end
  end

  describe '#each' do
    before do
      registry.add(:test, TestAuthenticationHook)
      registry.add(:test2, TestAuthenticationHook2)
      registry.add(:test3, TestAuthenticationHook3)
    end

    it 'should iterate over every hook in the registry' do
      hook_names = []
      hook_classes = []
      registry.each do |name, hook|
        hook_names << name
        hook_classes << hook
      end
      expect(hook_names).to include(:test)
      expect(hook_names).to include(:test2)
      expect(hook_names).to include(:test3)
      expect(hook_classes).to include(TestAuthenticationHook)
      expect(hook_classes).to include(TestAuthenticationHook2)
      expect(hook_classes).to include(TestAuthenticationHook3)
    end
  end

  describe '#to_h' do
    subject { registry.to_h }

    context 'when the registry has hooks' do
      before do
        registry.add(:test, TestAuthenticationHook)
        registry.add(:test2, TestAuthenticationHook2)
        registry.add(:test3, TestAuthenticationHook3)
      end

      it 'should convert the registry to a hash' do
        expect(subject).to eq({
          test: TestAuthenticationHook,
          test2: TestAuthenticationHook2,
          test3: TestAuthenticationHook3
        })
      end
    end

    context 'when there are no registered hooks' do
      it 'should return an empty hash' do
        expect(subject).to eq({})
      end
    end
  end

  describe '#any?' do
    subject { registry.any? }

    context 'when the registry has hooks' do
      before do
        registry.add(:test, TestAuthenticationHook)
        registry.add(:test2, TestAuthenticationHook2)
      end

      it 'should return true' do
        expect(subject).to be_truthy
      end
    end

    context 'when there are no registered hooks' do
      it 'should return false' do
        expect(subject).to be_falsey
      end
    end
  end
end

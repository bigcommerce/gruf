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

describe Gruf::Interceptors::Registry do
  let(:registry) { described_class.new }
  let(:interceptor_class) { TestServerInterceptor }
  let(:interceptor_class2) { TestServerInterceptor2 }
  let(:interceptor_class3) { TestServerInterceptor3 }
  let(:interceptor_class4) { TestServerInterceptor4 }
  let(:interceptor_options) { { one: 'two' } }

  describe '#use' do
    subject { registry.use(interceptor_class, interceptor_options) }

    it 'adds the interceptor to the registry' do
      expect { subject }.not_to raise_error
      expect(registry.count).to eq 1
      expect(registry.instance_variable_get(:@registry).first).to eq(
        klass: interceptor_class,
        options: interceptor_options
      )
    end
  end

  describe '#insert_before' do
    subject { registry.insert_before(interceptor_class3, interceptor_class4, interceptor_options) }

    context 'when the before interceptor exists in the registry' do
      before do
        registry.use(interceptor_class)
        registry.use(interceptor_class2)
        registry.use(interceptor_class3)
      end

      it 'inserts the interceptor before it in the registry' do
        expect { subject }.not_to raise_error

        reg = registry.instance_variable_get(:@registry)
        expect(reg[2][:klass]).to eq(interceptor_class4)
        expect(reg[3][:klass]).to eq(interceptor_class3)
      end
    end

    context 'when the before interceptor does not exist in the registry' do
      before do
        registry.use(interceptor_class)
        registry.use(interceptor_class2)
      end

      it 'raises a InterceptorNotFoundError' do
        expect { subject }.to raise_error(described_class::InterceptorNotFoundError)
      end
    end
  end

  describe '#insert_after' do
    subject { registry.insert_after(interceptor_class2, interceptor_class3, interceptor_options) }

    context 'when the before interceptor exists in the registry' do
      before do
        registry.use(interceptor_class)
        registry.use(interceptor_class2)
        registry.use(interceptor_class4)
      end

      it 'inserts the interceptor before it in the registry' do
        expect { subject }.not_to raise_error

        reg = registry.instance_variable_get(:@registry)
        expect(reg[2][:klass]).to eq(interceptor_class3)
        expect(reg[1][:klass]).to eq(interceptor_class2)
      end
    end

    context 'when the before interceptor does not exist in the registry' do
      before do
        registry.use(interceptor_class)
        registry.use(interceptor_class4)
      end

      it 'raises an InterceptorNotFoundError' do
        expect { subject }.to raise_error(described_class::InterceptorNotFoundError)
      end
    end
  end

  describe '#remove' do
    subject { registry.remove(interceptor_class) }

    before do
      registry.use(interceptor_class2)
      registry.use(interceptor_class3)
    end

    context 'when the interceptor is in the registry' do
      before do
        registry.use(interceptor_class)
      end

      it 'removes the interceptor from the registry' do
        expect { subject }.not_to raise_error
        expect(registry.count).to eq 2
      end
    end

    context 'when the interceptor is not in the registry' do
      it 'raises an InterceptorNotFoundError' do
        expect { subject }.to raise_error(described_class::InterceptorNotFoundError)
      end
    end
  end

  describe '#clear' do
    subject { registry.clear }

    before do
      registry.use(interceptor_class)
      registry.use(interceptor_class2)
    end

    it 'clears the registry of interceptors' do
      expect { subject }.not_to raise_error
      expect(registry.count).to be_zero
    end
  end

  describe '#count' do
    subject { registry.count }

    context 'with no interceptors' do
      it 'returns 0' do
        expect(subject).to be_zero
      end
    end

    context 'with one interceptor' do
      before do
        registry.use(interceptor_class)
      end

      it 'returns 1' do
        expect(subject).to eq 1
      end
    end

    context 'with multiple interceptors' do
      before do
        registry.use(interceptor_class)
        registry.use(interceptor_class2)
        registry.use(interceptor_class3)
      end

      it 'returns the number' do
        expect(subject).to eq 3
      end
    end
  end

  describe '#prepare' do
    subject { registry.prepare(request, errors) }

    let(:request) { build :controller_request }
    let(:errors) { build :error }

    before do
      registry.use(interceptor_class)
      registry.use(interceptor_class3)
      registry.use(interceptor_class2)
    end

    it 'returns all the interceptors prepared by the request and maintains insertion order' do
      prepped = subject
      expect(prepped.count).to eq 3
      expect(prepped[0]).to be_a(interceptor_class)
      expect(prepped[1]).to be_a(interceptor_class3)
      expect(prepped[2]).to be_a(interceptor_class2)
    end
  end
end

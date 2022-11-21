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

describe Gruf::Interceptors::Context do
  let(:interceptor_class) { TestServerInterceptor }
  let(:interceptors) do
    [interceptor_class.new(request, errors)]
  end
  let(:request) { build(:controller_request) }
  let(:errors) { build(:error) }
  let(:interceptor_context) { described_class.new(interceptors) }

  describe '#intercept!' do
    context 'when an interceptor is added' do
      it 'executes it and yields the block' do
        expect_any_instance_of(interceptor_class).to receive(:call).once.and_call_original

        expect(Gruf.logger).to receive(:debug).once
        expect { |b| interceptor_context.intercept!(&b) }.to yield_control.once
      end
    end

    context 'with multiple interceptors' do
      let(:interceptors) do
        [
          TestServerInterceptor.new(request, errors),
          TestServerInterceptor2.new(request, errors),
          TestServerInterceptor3.new(request, errors)
        ]
      end

      it 'executes each as added' do
        expect_any_instance_of(TestServerInterceptor).to receive(:call).once.and_call_original
        expect_any_instance_of(TestServerInterceptor2).to receive(:call).once.and_call_original
        expect_any_instance_of(TestServerInterceptor3).to receive(:call).once.and_call_original
        expect { |b| interceptor_context.intercept!(&b) }.to yield_control.once
      end

      it 'executes each in the order it was added' do
        expect(Math).to receive(:sqrt).ordered.with(4)
        expect(Math).to receive(:sqrt).ordered.with(16)
        expect(Math).to receive(:sqrt).ordered.with(256)
        expect(Gruf.logger).to receive(:debug).thrice
        expect { |b| interceptor_context.intercept!(&b) }.to yield_control.once
      end
    end
  end
end

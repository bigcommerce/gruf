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
require 'thwait'

describe Gruf::SynchronizedClient, :run_thing_server do
  subject { build_sync_client(options) }

  let(:options) { {} }

  describe '#initialize' do
    context 'when no exclusion list is provided' do
      it 'defaults to an empty list' do
        expect(subject).to be_a(described_class)
        expect(subject.unsynchronized_methods).to eq []
      end
    end

    context 'when exclusion list is passed' do
      let(:excluded) { [:foo] }
      let(:options) { { unsynchronized_methods: excluded } }

      it 'remembers them' do
        expect(subject).to be_a(described_class)
        expect(subject.unsynchronized_methods).to eq excluded
      end
    end
  end

  describe '#call' do
    let(:params) { { id: 1, sleep: 1 } }
    let(:metadata) { {} }
    let(:opts) { {} }
    let(:method_name) { :GetThing }

    context 'with multiple calls in parallel' do
      it 'makes only one rpc and return the same response object' do
        threads = []
        values = Concurrent::Map.new
        threads << Thread.new { values.put(:t1, subject.call(method_name, params, metadata, opts)) }
        threads << Thread.new { values.put(:t2, subject.call(method_name, params, metadata, opts)) }
        ThreadsWait.all_waits(*threads)

        expect(values[:t1]).to be_truthy
        expect(values[:t2]).to be_truthy
        expect(values[:t1]).to eq(values[:t2])
      end
    end

    context 'with multiple calls in series' do
      it 'makes an rpc for both calls and return different response objects' do
        result = subject.call(method_name, params, metadata, opts)
        result2 = subject.call(method_name, params, metadata, opts)
        expect(result.message).to be_truthy
        expect(result2.message).to be_truthy
        expect(result).not_to eq(result2)
      end
    end

    context 'when an exception occurs' do
      it 'releases the lock, not stall future requests, and return the same exception' do
        values = Concurrent::Map.new
        threads = []
        0.upto(10) do |i|
          threads << Thread.new do
            value = begin
              subject.call(:GetFail, params, {}, {})
            rescue StandardError => e
              e
            end
            values.put("result#{i}", value)
          end
        end
        ThreadsWait.all_waits(*threads)

        ex = values.get('result0')
        expect(ex).to be_a(Gruf::Client::Error)
        1.upto(10) do |i|
          expect(values.get("result#{i}")).to eq(ex)
        end
      end
    end
  end
end

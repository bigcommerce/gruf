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

describe Gruf::SynchronizedClient do
  let(:options) { {} }
  subject { build_sync_client(options) }

  around do |t|
    @server = build_server
    run_server(@server) { t.run }
  end

  describe '#initialize' do
    context 'when no exclusion list is provided' do
      it 'should default to an empty list' do
        expect(subject).to be_a(described_class)
        expect(subject.unsynchronized_methods).to eq []
      end
    end

    context 'if exclusion list is passed' do
      let(:excluded) { [:foo] }
      let(:options) { { unsynchronized_methods: excluded } }

      it 'should remember them' do
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

    context 'multiple calls in parallel' do
      it 'should make only one rpc and return the same response object' do
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

    context 'multiple calls in series' do
      it 'should make an rpc for both calls and return different response objects' do
        result = subject.call(method_name, params, metadata, opts)
        result2 = subject.call(method_name, params, metadata, opts)
        expect(result.message).to be_truthy
        expect(result2.message).to be_truthy
        expect(result).to_not eq(result2)
      end
    end

    context 'when an exception occurs' do
      it 'should release the lock, not stall future requests, and return the same exception' do
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

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

class FakeRequestLogFormatter; end
describe Gruf::Interceptors::Instrumentation::RequestLogging::Interceptor do
  let(:options) { { } }
  let(:service) { Rpc::ThingService.new }
  let(:id) { rand(1..1000) }
  let(:request) { Rpc::GetThingRequest.new(id: id) }
  let(:response) { Rpc::GetThingResponse.new(id: id) }
  let(:execution_time) { rand(0.001..10.000).to_f }
  let(:call_signature) { :get_thing_without_intercept }

  let(:controller_request) { build :controller_request, method_key: :get_thing }
  let(:errors) { build :error }
  let(:interceptor) { described_class.new(controller_request, errors, options) }
  let(:call) { interceptor.call { true } }
  let(:logger) { ::Logger.new('/dev/null') }

  before do
    allow(interceptor).to receive(:logger).and_return(logger)
  end

  describe '.call' do
    subject { call }

    context 'and the request was an invalid argument that was not overwritten' do
      let(:call) do
        interceptor.call do
          raise GRPC::InvalidArgument, 'invalid argument'
        end
      end

      it 'should log the call properly as a DEBUG' do
        expect(logger).to receive(:debug).once
        expect { subject }.to raise_error(GRPC::InvalidArgument) do |e|
          expect(e.details).to eq 'invalid argument'
        end
      end
    end

    context 'and the request was an invalid argument that was overwritten' do
      let(:options) { { log_levels: { 'GRPC::InvalidArgument' => :warn } } }

      let(:call) do
        interceptor.call do
          raise GRPC::InvalidArgument, 'invalid argument'
        end
      end

      it 'should log the call properly as an WARN' do
        expect(logger).to receive(:warn).once
        expect { subject }.to raise_error(GRPC::InvalidArgument) do |e|
          expect(e.details).to eq 'invalid argument'
        end
      end
    end

    context 'and the request was successful' do
      it 'should log the call properly as a DEBUG' do
        expect(logger).to receive(:debug).once
        subject
      end

      context 'with ignore_methods set' do
        let(:options) { { ignore_methods: %w[rpc.thing_service.get_thing] } }

        it 'shouldn\'t log the call' do
          expect(logger).not_to receive(:debug)
          subject
        end
      end
    end

    context 'and the request was a failure' do
      let(:call) do
        interceptor.call do
          raise GRPC::NotFound, 'thing not found'
        end
      end

      it 'should log the call properly as a DEBUG' do
        expect(logger).to receive(:debug).once
        expect { subject }.to raise_error(GRPC::NotFound) do |e|
          expect(e.details).to eq 'thing not found'
        end
      end
    end
  end

  describe '.sanitize' do
    let(:params) { { foo: 'bar', one: 'two', data: { hello: 'world', array: [] }, hello: { one: 'one', two: 'two' } } }
    subject { interceptor.send(:sanitize, params) }

    context 'vanilla' do
      it 'should return all params' do
        expect(subject).to eq params
      end
    end

    context 'with a blacklist' do
      let(:blacklist) { [:foo] }
      let(:options) { { blacklist: blacklist } }

      it 'should return all params that are not filtered by the blacklist' do
        expected = params.dup
        expected[:foo] = 'REDACTED'
        expect(subject).to eq expected
      end

      context 'with a custom redacted string' do
        let(:str) { 'goodbye' }
        let(:options) { { blacklist: blacklist, redacted_string: str } }

        it 'should return all params that are not filtered by the blacklist' do
          expected = params.dup
          expected[:foo] = str
          expect(subject).to eq expected
        end
      end

      context 'with nested blacklist' do
        let(:blacklist) { %w[data.array hello] }
        let(:options) { { blacklist: blacklist } }

        it 'should support nested filtering' do
          expected = Marshal.load(Marshal.dump(params))
          expected[:data][:array] = 'REDACTED'
          expected[:hello].each do |key, _val|
            expected[:hello][key] = 'REDACTED'
          end
          expect(subject).to eq expected
        end
      end

      context 'when params is nil' do
        let(:params) { nil }
        it 'should return normally' do
          expect { subject }.to_not raise_error
        end
      end
    end
  end

  describe '.formatter' do
    subject { interceptor.send(:formatter) }

    context 'when the formatter is a symbol' do
      let(:options) { { formatter: :logstash } }

      context 'and exists' do
        it 'should return the formatter' do
          expect(subject).to be_a(Gruf::Interceptors::Instrumentation::RequestLogging::Formatters::Logstash)
        end
      end

      context 'and has multiple words name' do
        before do 
          module Gruf::Interceptors::Instrumentation::RequestLogging::Formatters
            class MultipleWord < Base; end
          end
        end

        let(:options) { { formatter: :multiple_word } }

        it 'should return the formatter' do
          expect(subject).to be_a(Gruf::Interceptors::Instrumentation::RequestLogging::Formatters::MultipleWord)
        end
      end

      context 'and is invalid' do
        let(:options) { { formatter: :bar } }

        it 'should raise a NameError' do
          expect { subject }.to raise_error(NameError)
        end
      end
    end

    context 'when the formatter is a class' do
      let(:options) { { formatter: Gruf::Interceptors::Instrumentation::RequestLogging::Formatters::Logstash } }

      context 'and extends the base class' do
        it 'should return the formatter' do
          expect(subject).to be_a(Gruf::Interceptors::Instrumentation::RequestLogging::Formatters::Logstash)
        end
      end

      context 'and does not extend the base class' do
        let(:options) { { formatter: FakeRequestLogFormatter } }

        it 'should raise a InvalidFormatterError' do
          expect { subject }.to raise_error(Gruf::Interceptors::Instrumentation::RequestLogging::InvalidFormatterError)
        end
      end
    end

    context 'when the formatter is an instance' do
      let(:options) { { formatter: Gruf::Interceptors::Instrumentation::RequestLogging::Formatters::Logstash.new } }

      context 'and extends the base class' do
        it 'should return the formatter' do
          expect(subject).to be_a(Gruf::Interceptors::Instrumentation::RequestLogging::Formatters::Logstash)
        end
      end

      context 'and does not extend the base class' do
        let(:options) { { formatter: FakeRequestLogFormatter.new } }

        it 'should raise a InvalidFormatterError' do
          expect { subject }.to raise_error(Gruf::Interceptors::Instrumentation::RequestLogging::InvalidFormatterError)
        end
      end
    end
  end
end

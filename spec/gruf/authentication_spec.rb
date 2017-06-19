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
require 'base64'

describe Gruf::Authentication do

  describe '#verify' do
    let(:username) { 'grpc' }
    let(:password) { 'magic' }
    let(:md) { { 'authorization' => "Basic #{Base64.encode64("#{username}:#{password}")}" } }
    let(:call) { Rpc::Test::Call.new(md) }

    subject { described_class.verify(call) }

    before do
      Gruf.configure do |c|
        c.authentication_options = {
          credentials: [{ username: 'grpc', password: 'magic' }]
        }
      end
    end

    context 'with no strategies' do
      it 'should execute no strategies and return true' do
        expect(Gruf::Authentication::Basic).to_not receive(:verify)
        expect(Gruf::Authentication::None).to_not receive(:verify)
        expect(subject).to be_truthy
      end
    end

    context 'with the none strategy' do
      before do
        Gruf::Authentication::Strategies.add(:none, Gruf::Authentication::None)
      end

      it 'should execute the None strategy and return true' do
        expect(Gruf::Authentication::Basic).to_not receive(:verify)
        expect(Gruf::Authentication::None).to receive(:verify).and_return(true)
        expect(subject).to be_truthy
      end
    end

    context 'with basic auth strategy' do
      before do
        Gruf::Authentication::Strategies.add(:basic, Gruf::Authentication::Basic)
      end

      context 'when with good credentials' do
        it 'should execute the basic strategy and return true' do
          expect(Gruf::Authentication::Basic).to receive(:verify).and_call_original
          expect(Gruf::Authentication::None).to_not receive(:verify)
          expect(subject).to be_truthy
        end
      end

      context 'when with bad credentials' do
        let(:password) { 'bad' }

        it 'should execute the basic strategy and return false' do
          expect(Gruf::Authentication::Basic).to receive(:verify).and_call_original
          expect(Gruf::Authentication::None).to_not receive(:verify)
          expect(subject).to be_falsey
        end
      end
    end

    context 'with a strategy that throws an exception' do
      before do
        Gruf::Authentication::Strategies.add(:exception, TestExceptionAuthenticationHook)
        Gruf::Authentication::Strategies.add(:basic, Gruf::Authentication::Basic)
      end

      it 'should log an error and noop' do
        expect(Gruf.logger).to receive(:error)
        expect(subject).to be_truthy
      end
    end
  end
end

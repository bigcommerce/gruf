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

describe Gruf::Serializers::Errors::Base do
  let(:error) { Gruf::Error.new }
  let(:serializer) { Serializers::Proto.new(error) }

  describe '.initialize' do
    subject { serializer }

    it 'should set the error on the object' do
      expect(subject.error).to eq error
    end
  end

  describe 'base methods' do
    let(:serializer) { described_class.new(error) }

    describe '.serialize' do
      subject { serializer.serialize }

      it 'should raise NotImplementedError' do
        expect { subject }.to raise_error NotImplementedError
      end
    end

    describe '.deserialize' do
      subject { serializer.deserialize }

      it 'should raise NotImplementedError' do
        expect { subject }.to raise_error NotImplementedError
      end
    end
  end
end

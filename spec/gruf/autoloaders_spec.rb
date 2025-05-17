# frozen_string_literal: true

# Copyright (c) 2022-present, BigCommerce Pty. Ltd. All rights reserved
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

describe Gruf::Autoloaders do
  let(:autoloaders) { ::Gruf.autoloaders }
  let(:controllers_path) { 'spec/pb' }

  describe '#load!' do
    subject { autoloaders.load!(controllers_paths: [controllers_path]) }

    it 'creates a controller autoloader for the passed path' do
      subject
      expect(autoloaders.controllers).to be_a(::Gruf::Controllers::Autoloader)
      expect(autoloaders.controllers.paths).to eq [controllers_path]
    end

    context 'when deprecated controllers_path is passed' do
      subject { autoloaders.load!(controllers_path: controllers_path) }

      it 'creates a controller autoloader for the passed path' do
        subject
        expect(autoloaders.controllers).to be_a(::Gruf::Controllers::Autoloader)
        expect(autoloaders.controllers.paths).to eq [controllers_path]
      end

      it 'logs a deprecation warning' do
        expect(::Gruf.logger)
          .to receive(:warn).with('controllers_path is deprecated. Please use controllers_paths instead.')
        subject
      end
    end
  end

  describe '#each' do
    it 'yields the configured autoloaders' do
      expect { |a| autoloaders.each(&a) }.to yield_control.once
    end
  end

  describe '#reload' do
    subject { autoloaders.reload }

    before do
      autoloaders.load!(controllers_paths: [controllers_path])
    end

    it 'runs reload on all autoloaders' do
      expect(autoloaders.controllers).to receive(:reload).once
      subject
    end
  end
end

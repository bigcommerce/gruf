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

describe ::Gruf::Controllers::Autoloader do
  let(:path) { 'spec/pb' }
  let(:reloading) { nil }
  let(:tag) { 'gruf-controllers' }
  let(:autoloader) { described_class.new(path: path, reloading: reloading) }
  let(:zeitwerk) do
    instance_spy(::Zeitwerk::Loader, setup: true, 'tag=': tag, tag: tag, ignore: true, push_dir: true, eager_load: true)
  end

  before do
    allow(::Zeitwerk::Loader).to receive(:new).and_return(zeitwerk)
  end

  describe '#initialize' do
    subject { autoloader }

    context 'when the path is valid' do
      it 'sets up the zeitwerk loader' do
        expect(zeitwerk).to receive(:ignore).with("#{path}/**/*_pb.rb").once
        expect(zeitwerk).to receive(:push_dir).with(path).once
        expect(zeitwerk).to receive(:eager_load).once
        expect(zeitwerk).to receive(:setup).once
        subject
        expect(zeitwerk.tag).to eq tag
      end

      context 'when reloading is enabled' do
        let(:reloading) { true }

        it 'enables reloading in zeitwerk' do
          expect(zeitwerk).to receive(:enable_reloading).once
          subject
        end
      end

      context 'when reloading is enabled via current environment' do
        let(:in_dev) { true }
        let(:reloading) { nil }

        before do
          allow(Gruf).to receive(:development?).and_return(in_dev)
        end

        context 'when the environment is development' do
          let(:in_dev) { true }

          it 'enables reloading in zeitwerk' do
            expect(zeitwerk).to receive(:enable_reloading).once
            subject
          end
        end

        context 'when the environment is not development' do
          let(:in_dev) { false }

          it 'does not enable reloading in zeitwerk' do
            expect(zeitwerk).not_to receive(:enable_reloading)
            subject
          end
        end
      end
    end

    context 'when the path is invalid' do
      let(:path) { 'fake/path/this/does/not/exist' }

      it 'does not setup the zeitwerk loader' do
        expect(zeitwerk).not_to receive(:ignore)
        expect(zeitwerk).not_to receive(:setup)
        subject
      end
    end
  end

  describe '#reload' do
    subject { autoloader.reload }

    context 'when code reloading is enabled' do
      let(:reloading) { true }

      it 'reloads zeitwerk' do
        expect(zeitwerk).to receive(:reload).once
        subject
      end

      it 'accesses the loader in a thread-safe manner' do
        autoloader.send(:reload_lock)
        expect(autoloader.instance_variable_get(:@reload_lock)).to receive(:with_write_lock).and_yield.twice
        threads = []
        threads << Thread.new { autoloader.reload }
        threads << Thread.new { autoloader.reload }
        threads.each(&:join)
      end
    end

    context 'when code reloading is disabled' do
      let(:reloading) { false }

      it 'does not reload zeitwerk' do
        expect(zeitwerk).not_to receive(:reload)
        subject
      end
    end
  end
end

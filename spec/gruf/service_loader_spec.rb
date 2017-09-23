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

describe Gruf::ServiceLoader do
  describe '.new' do
    context 'when passed no services' do
      subject(:loader) { described_class.new }

      context 'but some are configured in initializer' do
        before do
          Gruf.configure do |c|
            c.services << ThingService
            c.services << ThingService
          end
        end

        it 'should return all services loaded in configuration uniquely' do
          expect(loader.services).to eq [ThingService]
        end
      end

      context 'and none are configured in initializer' do
        before do
          Gruf.configure do |c|
            c.services = []
          end
        end

        it 'should return an empty array' do
          expect(loader.services).to eq []
        end
      end
    end

    context 'when passed a service' do
      let(:services) { [ThingService] }
      subject(:loader) { described_class.new(services: services) }

      context 'and some are configured in an initializer' do
        before do
          Gruf.configure do |c|
            c.services << ThingService
            c.services << ThingService
          end
        end

        it 'should return all services loaded in configuration uniquely' do
          expect(loader.services).to eq [ThingService]
        end
      end

      context 'and none are configured in initializer' do
        before do
          Gruf.configure do |c|
            c.services = []
          end
        end

        it 'should return all services loaded in configuration uniquely' do
          expect(loader.services).to eq services
        end
      end
    end
  end

  describe '#require_services' do
    let(:fake_app_root) { File.join(File.expand_path('../../', __FILE__), 'demo_app_root') }
    let(:loader) { described_class.new(load_path: fake_app_root) }
    subject(:require_services) { loader.require_services }

    before do
      Gruf.configure do |c|
        c.servers_path = fake_app_root
      end
    end

    context 'when files include the Gruf::Service module' do
      let(:service_file) { Pathname.new(fake_app_root).join('fake_demo_service.rb') }

      before do
        allow(loader).to receive(:require)
        allow(loader.logger).to receive(:info)
      end

      it 'the file is required' do
        require_services
        expect(loader).to have_received(:require).with(service_file.to_s)
      end

      it 'logs the files was required' do
        expect_log_message = "- Loading gRPC service file: #{service_file}"
        require_services
        expect(loader.logger).to have_received(:info).with(expect_log_message)
      end
    end

    context 'when files do not include the Gruf::Service module' do
      let(:non_required_file) { Pathname.new(fake_app_root).join('non_service.rb') }

      before do
        allow(loader).to receive(:require)
      end

      it 'is not required' do
        require_services
        expect(loader).not_to have_received(:require).with(non_required_file.to_s)
      end
    end
  end
end

# Copyright (c) 2017, BigCommerce Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 3. All advertising materials mentioning features or use of this software
# must display the following acknowledgement:
# This product includes software developed by BigCommerce Inc.
# 4. Neither the name of BigCommerce Inc. nor the
# names of its contributors may be used to endorse or promote products
# derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY BIGCOMMERCE INC ''AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL BIGCOMMERCE INC BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
require 'spec_helper'

class TestConfiguration
  include Gruf::Configuration
end
describe Gruf::Configuration do
  let(:obj) { TestConfiguration.new }

  describe '.reset' do
    subject { obj.server_binding_url }

    it 'should reset config vars to default' do
      obj.configure do |c|
        c.server_binding_url = 'test.dev'
      end
      obj.reset
      expect(subject).to_not eq 'test.dev'
    end
  end

  describe '.environment' do
    subject { obj.send(:environment) }

    context 'ENV RAILS_ENV' do
      before do
        allow(ENV).to receive(:[]).with('RACK_ENV').and_return nil
        allow(ENV).to receive(:[]).with('RAILS_ENV').and_return 'production'
      end
      it 'should return the proper environment' do
        expect(subject).to eq 'production'
      end
    end

    context 'ENV RACK_ENV' do
      before do
        allow(ENV).to receive(:[]).with('RACK_ENV').and_return 'production'
        allow(ENV).to receive(:[]).with('RAILS_ENV').and_return nil
      end
      it 'should return the proper environment' do
        expect(subject).to eq 'production'
      end
    end
  end

  describe '.options' do
    subject { obj.options }
    before do
      obj.reset
    end

    it 'should return the options hash' do
      expect(obj.options).to be_a(Hash)
      expect(obj.options[:server_binding_url]).to eq '0.0.0.0:9001'
    end
  end
end

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

module ActiveRecord
  class Base
  end
end

describe Gruf::Hooks::ActiveRecord::ConnectionReset do
  let(:service) { ThingService.new }
  let(:hook) { described_class.new(service) }

  subject { hook.after(true, nil, :get_thing, nil, nil) }

  context 'if ActiveRecord is loaded' do
    it 'should try to clear any active connections' do
      expect(::ActiveRecord::Base).to receive(:clear_active_connections!)
      subject
    end
  end

  context 'if ActiveRecord is not loaded' do
    before do
      allow(hook).to receive(:enabled?).and_return(false)
    end

    it 'should not try to clear any active connections' do
      expect(::ActiveRecord::Base).to_not receive(:clear_active_connections!)
      subject
    end
  end
end

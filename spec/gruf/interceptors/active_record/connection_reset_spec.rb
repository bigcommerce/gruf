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

describe Gruf::Interceptors::ActiveRecord::ConnectionReset do
  let(:request) { build(:controller_request) }
  let(:errors) { build(:error) }
  let(:interceptor) { described_class.new(request, errors) }

  describe '#call' do
    subject { interceptor.call { true } }

    context 'when ActiveRecord is loaded' do
      before do
        allow(interceptor).to receive(:enabled?).and_return(true)
      end

      it 'tries to clear any active connections' do
        expect(::ActiveRecord::Base).to receive(:establish_connection).and_call_original
        expect(::ActiveRecord::Base).to receive(:clear_active_connections!).and_call_original
        subject
      end
    end

    context 'when ActiveRecord is not loaded' do
      before do
        allow(interceptor).to receive(:enabled?).and_return(false)
      end

      it 'does not try to clear any active connections' do
        expect(::ActiveRecord::Base).not_to receive(:establish_connection)
        expect(::ActiveRecord::Base).not_to receive(:clear_active_connections!)
        subject
      end
    end
  end
end

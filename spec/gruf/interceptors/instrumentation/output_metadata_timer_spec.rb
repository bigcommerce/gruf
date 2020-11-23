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

describe Gruf::Interceptors::Instrumentation::OutputMetadataTimer do
  let(:options) { { metadata_key: :timer } }
  let(:request) { build :controller_request, method_key: :get_thing }
  let(:errors) { build :error }
  let(:interceptor) { described_class.new(request, errors, options) }

  describe '#call' do
    subject { interceptor.call { true } }

    it 'sets the execution time to the output metadata' do
      expect { subject }.not_to raise_error
      expect(request.active_call.output_metadata[:timer]).not_to be_nil
    end

    context 'with a custom key' do
      let(:options) { { metadata_key: :foo } }

      it 'sets the execution time to the output metadata with the new key' do
        expect { subject }.not_to raise_error
        expect(request.active_call.output_metadata[:foo]).not_to be_nil
      end
    end
  end
end

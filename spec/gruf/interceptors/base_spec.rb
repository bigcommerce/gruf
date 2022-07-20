# frozen_string_literal: true

# Copyright (c) 2017-present, BigCommerce Pty. Ltd. All rights reserved
#
# Permission isr hereby granted, free of charge, to any person obtaining a copy of this software and associated
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

describe Gruf::Interceptors::Base do
  let(:interceptor) { TestBaseInterceptor }
  let(:error_message) { 'Internal error occurred' }
  let(:error_code) { :intrnal }
  let(:err_obj) { Gruf::Error.new(code: error_code, message: error_message) }
  let(:metadata_response) { { Gruf.error_metadata_key.to_s => err_obj.serialize } }
  let(:grpc_error) { GRPC::Internal.new(error_message, metadata_response) }
  let(:options) { {} }

  describe '#failure?' do
    subject { interceptor.new(request, grpc_error, options).failure? }

    let(:request) { build :controller_request }

    context 'when the result is a failure' do
      it { is_expected.to be_truthy }
    end

    context 'when the error is not in the default failure classes' do
      let(:error_message) { 'Not found' }
      let(:error_code) { :not_found }
      let(:err_obj) { Gruf::Error.new(code: error_code, message: error_message) }
      let(:metadata_response) { { Gruf.error_metadata_key.to_s => err_obj.serialize } }
      let(:grpc_error) { GRPC::NotFound.new(error_message, metadata_response) }

      it { is_expected.to be_falsey }

      context 'when error is defined as a failure class by the user' do
        let(:options) { { failure_classes: ['GRPC::NotFound'] } }

        it { is_expected.to be_truthy }
      end
    end
  end
end

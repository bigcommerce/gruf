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

describe Gruf::Error do
  let(:code) { :not_found }
  let(:app_code) { :thing_not_found }
  let(:message) { '' }
  let(:metadata) { {} }
  let(:error) { described_class.new(code: code, app_code: app_code, message: message, metadata: metadata) }
  let(:call) { double(:call, output_metadata: {}) }

  describe '.serialize' do
    subject { error.serialize }

    context 'with the JSON serializer' do
      it 'should return the serialized error in JSON' do
        expected_json = {
          code: code,
          app_code: app_code,
          message: message,
          field_errors: [],
          debug_info: {},
        }.to_json
        expect(subject).to be_a(String)
        expect(subject).to eq expected_json
      end
    end
  end

  describe '.attach_to_call' do
    subject { error.attach_to_call(call) }

    context 'with a provided serializer' do
      context 'with no metadata on the error' do
        it 'should attach the proto metadata' do
          expect(call.output_metadata).to receive(:update)
          expect(subject).to be_a(described_class)
        end
      end

      context 'with metadata on the error' do
        let(:metadata) { { foo: :bar } }
        it 'should attach the proto metadata and custom metadata, and strings for values' do
          expect(call.output_metadata).to receive(:update).with({ foo: 'bar' }.merge(:'error-internal-bin' => error.serialize))
          expect(subject).to be_a(described_class)
        end
      end
    end
  end

  describe '.fail!' do
    let(:subject) { error.fail!(call) }

    it 'should fail with the proper grpc error code' do
      expect { subject }.to raise_error(GRPC::NotFound)
    end
  end
end

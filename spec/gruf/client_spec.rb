# Copyright 2017, Bigcommerce Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
# 1. Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
# 3. Neither the name of BigCommerce Inc. nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
require 'spec_helper'

describe Gruf::Client do
  let(:options) { {} }
  let(:client) { described_class.new(service: Rpc::ThingService, options: options) }

  describe '#initialize' do
    subject { client }

    it 'should initialize a new client for the given service' do
      expect(subject).to be_a(Gruf::Client)
    end

    it 'should have the handlers' do
      expect(subject.respond_to?(:get_thing)).to be_truthy
      expect(subject.respond_to?(:get_fail)).to be_truthy
    end

    context 'when no hostname is provided' do
      it 'should default to the default client host' do
        Gruf.configure do |c|
          c.default_client_host = 'test.dev'
        end
        expect(subject).to be_a(Gruf::Client)
        expect(subject.opts[:hostname]).to eq 'test.dev'
      end
    end
  end

  describe '.call' do
    let(:metadata) { { foo: 'bar' } }
    let(:params) { { id: 1 } }
    let(:op) { build_operation(metadata: metadata) }
    subject { client.call(method_name, params, metadata) }

    context 'if the call is successful' do
      let(:req) { Rpc::GetThingRequest.new(params) }
      let(:method_name) { :GetThing }

      it 'should call the appropriate method with the right signature' do
        expect(client).to receive(:get_thing).with(req, return_op: true, metadata: metadata).and_return(op)
        expect(subject).to be_truthy
      end
    end

    context 'if a GRPC::BadStatus is raised' do
      let(:req) { Rpc::GetFailRequest.new(params) }
      let(:method_name) { :GetFail }
      let(:error_message) { 'Thing with ID 1 not found!' }
      let(:error_code) { :not_found }
      let(:app_error_code) { :thing_not_found }
      let(:err_obj) { Gruf::Error.new(code: error_code, app_code: app_error_code, message: error_message) }
      let(:metadata_response) { { Gruf.error_metadata_key.to_s => err_obj.serialize } }
      let(:grpc_error) { GRPC::NotFound.new(error_message, metadata_response) }

      before do
        expect(client).to receive(:execute).and_raise(grpc_error)
      end

      it 'should raise the error' do
        expect {
          subject
        }.to raise_error(Gruf::Client::Error)
      end

      context 'and has a serialized error payload' do
        it 'should pass it through deserialized' do
          expect {
            subject
          }.to raise_error(Gruf::Client::Error) do |e|
            expect(e.error['code']).to eq error_code.to_s
            expect(e.error['app_code']).to eq app_error_code.to_s
            expect(e.error['message']).to eq error_message
          end
        end
      end

      context 'and has no serialized error payload' do
        let(:metadata_response) { {} }

        it 'should just passthrough the error object as-is' do
          expect {
            subject
          }.to raise_error(GRPC::NotFound)
        end
      end
    end

    context 'if the method does not exist' do
      let(:req) { Rpc::GetThingRequest.new(params) }
      let(:method_name) { :GetNonExistentMethodOnTheService }

      it 'should raise a NotImplementedError' do
        expect{ subject }.to raise_error(NotImplementedError)
      end
    end
  end

  describe '.build_metadata' do
    let(:metadata) { { foo: 'bar' } }
    subject { client.send(:build_metadata, metadata) }

    context 'with a password' do
      let(:options) { { username: 'grpc', password: 'abcd' } }
      let(:auth_string_encoded) { "Basic #{Base64.encode64("#{options[:username]}:#{options[:password]}")}".strip }

      context 'and a passed metadata hash' do
        it 'should return the merged hash with the authorization data' do
          expect(subject).to eq metadata.merge(authorization: auth_string_encoded)
        end
      end

      context 'and no passed metadata hash' do
        let(:metadata) { {} }
        it 'should return a hash with only the authorization data' do
          expect(subject).to eq({ authorization: auth_string_encoded })
        end
      end
    end

    context 'without a password' do
      context 'and a passed hash' do
        it 'should return the hash untouched' do
          expect(subject).to eq metadata
        end
      end

      context 'and nothing passed' do
        let(:options) { { username: '', password: '' } }
        let(:metadata) { {} }
        it 'should return an empty hash' do
          expect(subject).to be_empty
        end
      end
    end
  end
end

describe Gruf::Client::Error do
  let(:err_obj) { Object.new }
  let(:error) { described_class.new(err_obj) }
  subject { error }

  context '.initialize' do
    it 'should set the error object on the class' do
      expect(subject.error).to eq err_obj
    end
  end
end

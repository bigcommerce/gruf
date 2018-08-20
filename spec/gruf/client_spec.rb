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

describe Gruf::Client do
  let(:options) { {} }
  let(:client_options) { {} }
  let(:client) { described_class.new(service: Rpc::ThingService, options: options, client_options: client_options) }

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

    context 'if client options are passed' do
      let(:timeout) { 30 }
      let(:client_options) { { timeout: timeout } }

      it 'they should pass through to the client stub' do
        expect(subject).to be_a(Gruf::Client)
        expect(subject.timeout).to eq timeout
      end
    end
  end

  describe '.call' do
    let(:metadata) { { foo: 'bar' } }
    let(:params) { { id: 1 } }
    let(:opts) { {} }
    let(:op) { build_operation(metadata: metadata) }
    subject { client.call(method_name, params, metadata, opts) }

    context 'if the call is successful' do
      let(:req) { Rpc::GetThingRequest.new(params) }
      let(:method_name) { :GetThing }

      it 'should call the appropriate method with the right signature' do
        expect(client).to receive(:get_thing).with(req, return_op: true, metadata: metadata).and_return(op)
        expect(subject).to be_truthy
      end

      context 'with a deadline' do
        let(:deadline) { Time.now + 42 }
        let(:opts) { { deadline: deadline } }

        it 'should pass the deadline into the call' do
          expect(client).to receive(:get_thing).with(req, return_op: true, metadata: metadata, deadline: deadline).and_return(op)
          expect(subject).to be_truthy
        end
      end
    end

    context 'if a GRPC::BadStatus is raised' do
      let(:req) { Rpc::GetThingRequest.new(params) }
      let(:method_name) { :GetThing }
      let(:error_message) { 'Thing with ID 1 not found!' }
      let(:error_code) { :not_found }
      let(:app_error_code) { :thing_not_found }
      let(:err_obj) { Gruf::Error.new(code: error_code, app_code: app_error_code, message: error_message) }
      let(:metadata_response) { { Gruf.error_metadata_key.to_s => err_obj.serialize } }
      let(:grpc_error) { GRPC::NotFound.new(error_message, metadata_response) }

      context 'if the serializer is the default' do
        before do
          expect(client).to receive(:get_thing).and_raise(grpc_error)
        end

        it 'should raise the error' do
          expect {
            subject
          }.to raise_error(Gruf::Client::Errors::NotFound)
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
            }.to raise_error(Gruf::Client::Errors::NotFound)
          end
        end
      end


      context 'if the serializer is the proto serializer' do
        before do
          Gruf.error_serializer = Serializers::Proto
          expect(client).to receive(:get_thing).and_raise(grpc_error)
        end

        after do
          Gruf.error_serializer = nil
        end

        it 'should pass it through deserialized' do
          expect {
            subject
          }.to raise_error(Gruf::Client::Errors::NotFound) do |e|
            expect(e.error.error_code).to eq app_error_code.to_s
            expect(e.error.error_message).to eq error_message.to_s
          end
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

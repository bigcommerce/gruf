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

describe Gruf::Client do
  let(:options) { { hostname: 'test.dev' } } # must set at least a hostname otherwise grpc hangs
  let(:client_options) { {} }
  let(:client) { described_class.new(service: Rpc::ThingService, options: options, client_options: client_options) }

  describe '#initialize' do
    subject { client }

    it 'initializes a new client for the given service' do
      expect(subject).to be_a(described_class)
    end

    it 'has the RPC desc handlers' do
      expect(subject).to respond_to(:get_thing)
      expect(subject).to respond_to(:get_fail)
    end

    context 'when no hostname is provided' do
      let(:host) { 'test.dev' }

      before do
        Gruf.configure do |c|
          c.default_client_host = host
        end
      end

      it 'defaults to the default client host' do
        expect(subject).to be_a(described_class)
        expect(subject.opts[:hostname]).to eq host
      end
    end

    context 'when no channel credentials options are passed' do
      let(:channel_credentials) { GRPC::Core::ChannelCredentials.new }

      after do
        Gruf.configure do |config|
          config.default_channel_credentials = nil
        end
      end

      it 'returns nil' do
        expect(subject).to be_a(described_class)
        expect(subject.opts[:channel_credentials]).to be_nil
      end

      it 'uses default channel credentials' do
        Gruf.configure do |config|
          config.default_channel_credentials = channel_credentials
        end

        expect(subject).to be_a(described_class)
        expect(subject.opts[:channel_credentials]).to eq(channel_credentials)
      end
    end

    context 'when channel credentials options are passed' do
      let(:channel_credentials) { GRPC::Core::ChannelCredentials.new }
      let(:options) { { channel_credentials: channel_credentials } }

      after do
        subject.opts[:channel_credentials] = nil
      end

      it 'sets channel credentials' do
        expect(subject).to be_a(described_class)
        expect(subject.opts[:channel_credentials]).to eq(channel_credentials)
      end
    end

    context 'when client options are passed' do
      let(:timeout) { 30 }
      let(:client_options) { { timeout: timeout } }

      it 'passes through to the client stub' do
        expect(subject).to be_a(described_class)
        expect(subject.timeout).to eq timeout
      end

      context 'when the timeout is passed as a string' do
        let(:timeout) { '30' }

        it 'is cast as a float' do
          expect(subject).to be_a(described_class)
          expect(subject.timeout).to eq 30.0
        end
      end

      context 'when the timeout is nil' do
        let(:timeout) { nil }

        it 'is reset as a GRPC::Core::TimeConsts::ZERO' do
          expect(subject.timeout).to eq ::GRPC::Core::TimeConsts::ZERO
        end
      end

      context 'when the timeout is a GRPC::Core::TimeSpec' do
        let(:timeout) { GRPC::Core::TimeConsts::INFINITE_FUTURE }

        it 'preserves the value' do
          expect(subject.timeout).to be_a(GRPC::Core::TimeSpec)
          expect(subject.timeout).to eq timeout
        end
      end

      context 'when the timeout is an invalid value that is not castable to a float' do
        let(:timeout) { Object.new }

        it 'raises an ArgumentError' do
          expect { subject }.to raise_error(ArgumentError, 'timeout is not a valid value: does not respond to to_f')
        end
      end
    end
  end

  describe '#call' do
    subject { client.call(method_name, params, metadata, opts) }

    let(:metadata) { { foo: 'bar' } }
    let(:params) { { id: 1 } }
    let(:opts) { {} }
    let(:op) { build_operation(metadata: metadata) }

    context 'when the call is successful' do
      let(:req) { Rpc::GetThingRequest.new(params) }
      let(:method_name) { :GetThing }

      it 'calls the appropriate method with the right signature' do
        expect(client).to receive(:get_thing).with(req, return_op: true, metadata: metadata).and_return(op)
        expect(subject).to be_truthy
      end

      context 'with a deadline' do
        let(:deadline) { Time.now + 42 }
        let(:opts) { { deadline: deadline } }

        it 'passes the deadline into the call' do
          expect(client).to receive(:get_thing)
            .with(req, return_op: true, metadata: metadata, deadline: deadline).and_return(op)
          expect(subject).to be_truthy
        end
      end
    end

    context 'when a GRPC::BadStatus is raised' do
      let(:req) { Rpc::GetThingRequest.new(params) }
      let(:method_name) { :GetThing }
      let(:error_message) { 'Thing with ID 1 not found!' }
      let(:error_code) { :not_found }
      let(:app_error_code) { :thing_not_found }
      let(:err_obj) { Gruf::Error.new(code: error_code, app_code: app_error_code, message: error_message) }
      let(:metadata_response) { { Gruf.error_metadata_key.to_s => err_obj.serialize } }
      let(:grpc_error) { GRPC::NotFound.new(error_message, metadata_response) }

      context 'when the serializer is the default' do
        before do
          allow(client).to receive(:get_thing).and_raise(grpc_error)
        end

        it 'raises the error' do
          expect { subject }.to raise_error(Gruf::Client::Errors::NotFound)
        end

        context 'when it has a serialized error payload' do
          it 'passes it through deserialized' do
            expect { subject }.to raise_error(Gruf::Client::Error) do |e|
              expect(e.error['code']).to eq error_code.to_s
              expect(e.error['app_code']).to eq app_error_code.to_s
              expect(e.error['message']).to eq error_message
            end
          end
        end

        context 'when it has no serialized error payload' do
          let(:metadata_response) { {} }

          it 'just passes through the error object as-is' do
            expect { subject }.to raise_error(Gruf::Client::Errors::NotFound)
          end
        end
      end

      context 'when the serializer is the proto serializer' do
        before do
          Gruf.error_serializer = Serializers::Proto
          allow(client).to receive(:get_thing).and_raise(grpc_error)
        end

        after do
          Gruf.error_serializer = nil
        end

        it 'passes it through deserialized' do
          expect { subject }.to raise_error(Gruf::Client::Errors::NotFound) do |e|
            expect(e.error.error_code).to eq app_error_code.to_s
            expect(e.error.error_message).to eq error_message.to_s
          end
        end
      end
    end

    context 'when the method does not exist' do
      let(:req) { Rpc::GetThingRequest.new(params) }
      let(:method_name) { :GetNonExistentMethodOnTheService }

      it 'raises a NotImplementedError' do
        expect { subject }.to raise_error(NotImplementedError)
      end
    end
  end

  describe '#build_metadata' do
    subject { client.send(:build_metadata, metadata) }

    let(:metadata) { { foo: 'bar' } }

    context 'with a password' do
      let(:options) { { username: 'grpc', password: 'abcd' } }
      let(:auth_string_encoded) { "Basic #{Base64.encode64("#{options[:username]}:#{options[:password]}")}".strip }

      context 'when it has a passed metadata hash' do
        it 'returns the merged hash with the authorization data' do
          expect(subject).to eq metadata.merge(authorization: auth_string_encoded)
        end
      end

      context 'when no passed metadata hash' do
        let(:metadata) { {} }

        it 'returns a hash with only the authorization data' do
          expect(subject).to eq(authorization: auth_string_encoded)
        end
      end
    end

    context 'without a password' do
      context 'when there is a a passed hash' do
        it 'returns the hash untouched' do
          expect(subject).to eq metadata
        end
      end

      context 'when there is nothing passed' do
        let(:options) { { username: '', password: '' } }
        let(:metadata) { {} }

        it 'returns an empty hash' do
          expect(subject).to be_empty
        end
      end
    end
  end

  describe Gruf::Client::Error do
    subject { error }

    let(:err_obj) { Object.new }
    let(:error) { described_class.new(err_obj) }

    describe '#initialize' do
      it 'sets the error object on the class' do
        expect(subject.error).to eq err_obj
      end
    end
  end
end

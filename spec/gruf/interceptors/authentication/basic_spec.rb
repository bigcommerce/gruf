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

describe Gruf::Interceptors::Authentication::Basic do
  let(:request_username) { 'grpc' }
  let(:request_password) { 'magic' }
  let(:server_username) { 'grpc' }
  let(:server_password) { 'magic' }
  let(:prefixed_req_username) { (request_username.empty? ? '' : "#{request_username}:") }

  let(:server_credentials1) do
    {
      username: server_username,
      password: server_password
    }
  end
  let(:server_credentials2) do
    {
      username: '',
      password: server_password
    }
  end
  let(:accepted_credentials) { [server_credentials1, server_credentials2] }
  let(:request_credentials) { "Basic #{Base64.encode64(prefixed_req_username + request_password)}" }

  let(:excluded_methods) { [] }

  let(:metadata) { { :authorization.to_s => request_credentials } }
  let(:active_call) { double(:active_call, metadata: metadata) }
  let(:request) { build :controller_request, active_call: active_call }
  let(:errors) { build :error }
  let(:interceptor) do
    described_class.new(
      request,
      errors,
      credentials: accepted_credentials,
      excluded_methods: excluded_methods
    )
  end

  describe '.valid?' do
    subject { interceptor.call { true } }

    context 'with a server username and password only' do
      let(:accepted_credentials) { [server_credentials1] }

      context 'when the credentials are correct' do
        it 'does not raise an error' do
          expect { subject }.not_to raise_error
        end

        context 'when excluded_methods is specified' do
          context 'when the call is in the list' do
            let(:excluded_methods) { ['rpc.thing_service.get_thing'] }

            it 'allows the request to go through' do
              expect { subject }.not_to raise_error
            end
          end

          context 'when the call is not in the list' do
            let(:excluded_methods) { ['rpc.thing_service.create_things'] }

            it 'allows the request to go through' do
              expect { subject }.not_to raise_error
            end
          end
        end
      end

      context 'when the credentials are incorrect' do
        context 'when the sent user is incorrect' do
          let(:request_username) { 'foo' }

          it 'raises a GRPC::Unauthenticated error' do
            expect { subject }.to raise_error GRPC::Unauthenticated
          end
        end

        context 'when the sent password is incorrect' do
          let(:request_password) { 'foo' }

          it 'raises a GRPC::Unauthenticated error' do
            expect { subject }.to raise_error GRPC::Unauthenticated
          end
        end

        context 'when neither are sent' do
          let(:metadata) { {} }

          it 'raises a GRPC::Unauthenticated error' do
            expect { subject }.to raise_error GRPC::Unauthenticated
          end
        end

        context 'when excluded_methods is specified' do
          let(:request_password) { 'wrong' }

          context 'when the call is in the list' do
            let(:excluded_methods) { ['rpc.thing_service.get_thing'] }

            it 'allows the request to go through' do
              expect { subject }.not_to raise_error
            end
          end

          context 'when the call is not in the list' do
            let(:excluded_methods) { ['rpc.thing_service.create_things'] }

            it 'raises a GRPC::Unauthenticated error' do
              expect { subject }.to raise_error GRPC::Unauthenticated
            end
          end
        end
      end
    end

    context 'with only a server password' do
      let(:accepted_credentials) { [server_credentials2] }
      let(:request_username) { '' }
      let(:server_username) { '' }

      context 'when the password is correct' do
        it 'does not raise an error' do
          expect { subject }.not_to raise_error
        end
      end

      context 'when the password is invalid' do
        let(:request_password) { 'foo' }

        it 'raises a GRPC::Unauthenticated error' do
          expect { subject }.to raise_error GRPC::Unauthenticated
        end
      end
    end

    context 'with a server username and password _or_ only a password' do
      context 'when the credentials are correct' do
        it 'does not raise an error' do
          expect { subject }.not_to raise_error
        end
      end

      context 'when the credentials are incorrect' do
        context 'when the sent user is incorrect' do
          let(:request_username) { 'foo' }

          it 'passes on the accepted password' do
            expect { subject }.not_to raise_error
          end
        end

        context 'when the sent password is incorrect' do
          let(:request_password) { 'foo' }

          it 'raises a GRPC::Unauthenticated error' do
            expect { subject }.to raise_error GRPC::Unauthenticated
          end
        end

        context 'when both the username and password are incorrect' do
          let(:request_username) { 'foo' }
          let(:request_password) { 'bar' }

          it 'raises a GRPC::Unauthenticated error' do
            expect { subject }.to raise_error GRPC::Unauthenticated
          end
        end
      end
    end
  end
end

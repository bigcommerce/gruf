require 'spec_helper'
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
describe Gruf::Authentication::Basic do
  let(:request_username) { 'grpc' }
  let(:request_password) { 'magic' }
  let(:server_username) { 'grpc' }
  let(:server_password) { 'magic' }
  let(:prefixed_req_username) { (request_username.empty? ? '' : "#{request_username}:") }

  let(:server_credentials1) { {
    username: server_username,
    password: server_password
  } }
  let(:server_credentials2) { {
    username: '',
    password: server_password
  } }
  let(:accepted_credentials) { [server_credentials1, server_credentials2] }

  let(:request_credentials) { "Basic #{Base64.encode64(prefixed_req_username + request_password)}"}
  let(:strategy) { described_class.new(request_credentials, credentials: accepted_credentials) }
  let(:call) { double(:call, metadata: {}) }

  describe '.valid?' do
    subject { strategy.valid?(call) }

    context 'with a server username and password only' do
      let(:accepted_credentials) { [server_credentials1] }

      context 'if the credentials are correct' do
        it 'should return true' do
          expect(subject).to be_truthy
        end
      end

      context 'if the credentials are incorrect' do
        context 'where the sent user is incorrect' do
          let(:request_username) { 'foo' }
          it 'should return false' do
            expect(subject).to be_falsey
          end
        end

        context 'where the sent password is incorrect' do
          let(:request_password) { 'foo' }
          it 'should return false' do
            expect(subject).to be_falsey
          end
        end
      end
    end

    context 'with only a server password' do
      let(:accepted_credentials) { [server_credentials2] }
      let(:request_username) { '' }
      let(:server_username) { '' }

      context 'if the password is correct' do
        it 'should return true' do
          expect(subject).to be_truthy
        end
      end

      context 'if the password is invalid' do
        let(:request_password) { 'foo' }
        it 'should return false' do
          expect(subject).to be_falsey
        end
      end
    end

    context 'with a server username and password _or_ only a password' do
      context 'if the credentials are correct' do
        it 'should return true' do
          expect(subject).to be_truthy
        end
      end

      context 'if the credentials are incorrect' do
        context 'where the sent user is incorrect' do
          let(:request_username) { 'foo' }
          it 'should pass on the accepted password' do
            expect(subject).to be_truthy
          end
        end

        context 'where the sent password is incorrect' do
          let(:request_password) { 'foo' }
          it 'should return false' do
            expect(subject).to be_falsey
          end
        end

        context 'where both the username and password are incorrect' do
          let(:request_username) { 'foo' }
          let(:request_password) { 'bar' }
          it 'should return false' do
            expect(subject).to be_falsey
          end

        end
      end
    end
  end
end

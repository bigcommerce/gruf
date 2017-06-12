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

describe Gruf::Server do
  let(:services) { [] }
  let(:gruf_server) { described_class.new(services: services) }
  subject { gruf_server }

  describe '.load_services' do
    context 'when passed no services' do
      context 'but some are configured in initializer' do
        before do
          Gruf.configure do |c|
            c.services << ThingService
            c.services << ThingService
          end
        end

        it 'should return all services loaded in configuration uniquely' do
          expect(subject.services).to eq [ThingService]
        end
      end

      context 'and none are configured in initializer' do
        before do
          Gruf.configure do |c|
            c.services = []
          end
        end

        it 'should return an empty array' do
          expect(subject.services).to eq []
        end
      end
    end

    context 'when passed a service' do
      let(:services) { [ThingService] }

      context 'and some are configured in an initializer' do
        before do
          Gruf.configure do |c|
            c.services << ThingService
            c.services << ThingService
          end
        end

        it 'should return all services loaded in configuration uniquely' do
          expect(subject.services).to eq [ThingService]
        end
      end

      context 'and none are configured in initializer' do
        before do
          Gruf.configure do |c|
            c.services = []
          end
        end

        it 'should return all services loaded in configuration uniquely' do
          expect(subject.services).to eq services
        end
      end
    end
  end
end

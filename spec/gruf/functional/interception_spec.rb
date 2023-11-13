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

describe 'Functional interceptors test' do
  let(:interceptor_class) { TestServerInterceptor }
  let(:interceptors) do
    {
      interceptor_class => {}
    }
  end

  context 'when there is an interceptor added' do
    context 'with a request/response call' do
      it 'intercepts the call', :run_thing_server do
        expect_any_instance_of(interceptor_class).to receive(:call).once.and_call_original
        client = build_client
        resp = client.call(:GetThing)
        expect(resp.message).to be_a(Rpc::GetThingResponse)
      end
    end

    context 'with a server streamer call' do
      it 'intercepts the call', :run_thing_server do
        expect_any_instance_of(interceptor_class).to receive(:call).and_call_original
        client = build_client
        resp = client.call(:GetThings)
        expect(resp.message).to be_a(Enumerator)
        resp.message.each do |m|
          expect(m).to be_a(Rpc::Thing)
        end
      end
    end

    context 'with a client streamer call' do
      it 'intercepts the call', :run_thing_server do
        expect_any_instance_of(interceptor_class).to receive(:call).and_call_original

        things = []
        5.times do
          things << Rpc::Thing.new(id: rand(1..1_000), name: FFaker::Lorem.word)
        end

        client = build_client
        resp = client.call(:CreateThings, things)
        expect(resp.message).to be_a(Rpc::CreateThingsResponse)
        expect(resp.message.things.count).to eq 5
        resp.message.things do |m|
          expect(m).to be_a(Rpc::Thing)
        end
      end
    end

    context 'with a bidi streamer call' do
      it 'intercepts the call', :run_thing_server do
        expect_any_instance_of(interceptor_class).to receive(:call).and_call_original
        things = []
        5.times do
          things << Rpc::Thing.new(id: rand(1..1_000), name: FFaker::Lorem.word)
        end

        client = build_client
        resp = client.call(:CreateThingsInStream, things)
        expect(resp.message.count).to eq 5
        resp.message do |m|
          expect(m).to be_a(Rpc::Thing)
        end
      end
    end
  end
end

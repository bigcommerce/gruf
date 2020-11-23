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

describe 'Functional server test' do
  let(:endpoint) { Rpc::ThingService.new }
  let(:id) { 1 }
  let(:req) { ::Rpc::GetThingRequest.new(id: id) }
  let(:resp) { ::Rpc::GetThingResponse.new(id: id) }
  let(:call_signature) { :get_thing }
  let(:metadata) { {} }
  let(:active_call) { double(:active_call, output_metadata: {}, metadata: metadata) }

  describe 'request types' do
    let(:client) { TestClient.new }

    context 'when it is a request/response call' do
      let(:id) { 1 }

      it 'returns the thing', run_thing_server: true do
        client = build_client
        resp = client.call(:GetThing, id: id)
        expect(resp.message).to be_a(Rpc::GetThingResponse)
        expect(resp.message.thing).to be_a(Rpc::Thing)
        expect(resp.message.thing.id).to eq id
      end
    end

    context 'when it is a server streaming call' do
      it 'returns the things in a stream from the server', run_thing_server: true do
        client = build_client
        resp = client.call(:GetThings)
        resp.message do |m|
          expect(m).to be_a(Rpc::Thing)
        end
      end
    end

    context 'when it is a client streaming call' do
      it 'returns the things from the server', run_thing_server: true do
        things = []
        5.times do
          things << Rpc::Thing.new(
            id: rand(1..1000).to_i,
            name: FFaker::Lorem.word.to_s
          )
        end
        client = build_client
        resp = client.call(:CreateThings, things)
        expect(resp.message).to be_a(Rpc::CreateThingsResponse)
        expect(resp.message.things.first).to be_a(Rpc::Thing)
      end
    end

    context 'when it is a bidi streaming call' do
      it 'returns the things from the server', run_thing_server: true do
        things = []
        5.times do
          things << Rpc::Thing.new(
            id: rand(1..1000).to_i,
            name: FFaker::Lorem.word.to_s
          )
        end
        client = build_client
        client.call(:CreateThingsInStream, things) do |r|
          expect(r).to be_a(Rpc::Thing)
        end
      end
    end
  end
end

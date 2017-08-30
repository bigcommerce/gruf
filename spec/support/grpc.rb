# coding: utf-8
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
require 'grpc'
require 'thing_service'

module Rpc
  module Test
    class Call
      attr_reader :metadata

      def initialize(md = nil)
        @metadata = md || { 'authorization' => "Basic #{Base64.encode64('grpc:magic')}" }
      end

      def output_metadata
        @output_metadata ||= {}
      end
    end
  end
end

class TestClient
  def get_thing(id: 1)
    request = ::Rpc::GetThingRequest.new(id: id)
    rpc_client = ::ThingService.new

    c = Rpc::Test::Call.new('authorization' => "Basic #{Base64.encode64('grpc:magic')}")
    begin
      thing = rpc_client.get_thing(request, c)
    rescue Gruf::Client::Error => e
      puts e.error.inspect
    end
    thing
  end
end

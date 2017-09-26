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
require 'rpc/ThingService_services_pb'
require 'ffaker'

class ThingService < ::Rpc::ThingService::Service
  include Gruf::Service

  def get_thing(req, _call)
    Math.sqrt(4) # used for testing
    Rpc::GetThingResponse.new(thing: Rpc::Thing.new(id: req.id, name: 'Foo'))
  end

  def get_things(_req, _call)
    things = []
    5.times do
      things << Rpc::Thing.new(id: rand(1..1000).to_i, name: FFaker::Lorem.word.to_s)
    end
    things
  end

  def create_things(call)
    things = []
    call.each_remote_read do |req|
      things << Rpc::Thing.new(id: req.id.to_i, name: FFaker::Lorem.word.to_s)
    end
    Rpc::CreateThingsResponse.new(things: things)
  end

  def create_things_in_stream(requests, _call)
    things = []
    requests.each do |req|
      things << Rpc::Thing.new(id: req.id.to_i, name: req.name.to_s)
    end
    things
  end

  # Error calls

  def get_fail(req, c)
    fail!(req, c, :not_found, :thing_not_found, "#{req.id} not found!", foo: :bar)
  end

  def get_field_error_fail(req, c)
    add_field_error(:name, :no_name, 'Please specify a name.')
    fail!(req, c, :invalid_argument, :no_thing_name, 'Please correct your errors.', my: :sharona)
  end

  def get_contextual_field_error_fail(req, c)
    add_field_error(:name, :triggered, 'Triggered field error.') if req.id == 1
    fail!(req, c, :invalid_argument, :invalid, 'Please correct your errors.') if has_field_errors?
    Rpc::GetThingResponse.new(thing: Rpc::Thing.new(id: req.id, name: 'Foo'))
  end

  def get_exception(req, c)
    raise 'oh noes'
  rescue => e
    set_debug_info(e.message, e.backtrace)
    fail!(req, c, :internal, :oh_noes, 'We done failed', oops: :man)
  end

  def get_uncaught_exception(_, _)
    raise 'epic fail'
  end

  def not_an_endpoint
    'i like turtles'
  end
end

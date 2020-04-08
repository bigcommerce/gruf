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
require 'rpc/Error_pb'
require 'ffaker'

class ThingController < ::Gruf::Controllers::Base
  bind ::Rpc::ThingService::Service

  def get_thing
    sleep_value = request.message.sleep.to_i
    sleep(sleep_value) unless sleep_value.zero?
    Rpc::GetThingResponse.new(thing: Rpc::Thing.new(id: request.message.id, name: FFaker::Name.first_name))
  end

  def get_things
    return enum_for(:get_things) unless block_given?

    5.times do
      yield Rpc::Thing.new(id: rand(1..1000).to_i, name: FFaker::Lorem.word.to_s)
      sleep rand(0..1)
    end
  end

  def create_things
    things = []
    request.messages do |msg|
      things << Rpc::Thing.new(id: msg.id.to_i, name: FFaker::Lorem.word.to_s)
    end
    Rpc::CreateThingsResponse.new(things: things)
  end

  def create_things_in_stream
    return enum_for(:create_things_in_stream) unless block_given?

    request.messages.each do |msg|
      yield Rpc::Thing.new(id: msg.id.to_i, name: msg.name.to_s)
      sleep rand(0..1)
    end
  end

  # Error calls

  def get_fail
    fail!(:not_found, :thing_not_found, "#{request.message.id} not found!", foo: :bar)
  end

  def get_field_error_fail
    add_field_error(:name, :no_name, 'Please specify a name.')
    fail!(:invalid_argument, :no_thing_name, 'Please correct your errors.', my: :sharona)
  end

  def get_contextual_field_error_fail
    if request.message.id == 1
      add_field_error(FFaker::Lorem.word.to_sym, :triggered, 'Triggered field error.')
      sleep(0.1)
    end
    fail!(:invalid_argument, :invalid, 'Please correct your errors.') if has_field_errors?
    Rpc::GetThingResponse.new(thing: Rpc::Thing.new(id: request.message.id, name: 'Foo'))
  end

  def get_exception
    raise 'oh noes'
  rescue => e
    set_debug_info(e.message, e.backtrace)
    fail!(:internal, :oh_noes, 'We done failed', oops: :man)
  end

  def get_uncaught_exception
    raise 'epic fail'
  end

  def not_an_endpoint
    'i like turtles'
  end
end

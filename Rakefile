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
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'ffaker'
RSpec::Core::RakeTask.new(:spec)
task default: :spec
require 'gruf'

def gruf_rake_configure_rpc!
  require 'pry'
  $LOAD_PATH.unshift File.expand_path('spec/pb', __dir__)
  root = File.dirname(__FILE__)
  require File.realpath("#{root}/spec/support/grpc.rb")
  require File.realpath("#{root}/spec/support/serializers/proto.rb")
  require File.realpath("#{root}/spec/support/interceptors.rb")

  Gruf.configure do |c|
    c.error_serializer = Serializers::Proto
    c.health_check_enabled = true
  end
end

# Test enumerator
class ThingCreatorEnumerator
  def initialize(num: 10)
    @num = num.to_i
  end

  def each
    return enum_for(:each) unless block_given?

    @num.times do
      sleep rand(0..1)
      item = Rpc::Thing.new(id: rand(1..1000), name: FFaker::Lorem.word)
      Gruf.logger.info "Sending: #{item.inspect}"
      yield item
    end
  end
end

# demo server tests
namespace :gruf do
  namespace :demo do
    desc 'Get a single Thing to illustrate a unary gRPC call'
    task :get_thing do
      gruf_rake_configure_rpc!
      begin
        rpc_client = gruf_demo_build_client
        op = rpc_client.call(:GetThing, id: rand(100_000))
        Gruf.logger.info op.message.inspect
      rescue Gruf::Client::Error => e
        Gruf.logger.info e.error.to_h
      end
    end

    desc 'Get a bunch of Things to illustrate a server streamer call'
    task :get_things do
      gruf_rake_configure_rpc!
      begin
        rpc_client = gruf_demo_build_client
        resp = rpc_client.call(:GetThings)
        resp.message.each do |thing|
          Gruf.logger.info thing.inspect
        end
      rescue Gruf::Client::Error => e
        Gruf.logger.error e.error.to_h
      end
    end

    desc 'Create Things using a client streamer call'
    task :create_things do
      gruf_rake_configure_rpc!
      begin
        rpc_client = gruf_demo_build_client
        enumerator = ThingCreatorEnumerator.new
        resp = rpc_client.call(:CreateThings, enumerator.each)
        Gruf.logger.info resp.message.inspect
      rescue Gruf::Client::Error => e
        Gruf.logger.error e.error.to_h
      end
    end

    desc 'Create Things in a bidi stream'
    task :create_things_in_stream do
      gruf_rake_configure_rpc!
      begin
        rpc_client = gruf_demo_build_client
        enumerator = ThingCreatorEnumerator.new
        resp = rpc_client.call(:CreateThingsInStream, enumerator.each)
        resp.message.each do |thing|
          Gruf.logger.info "Received: #{thing.inspect}"
        end
      rescue Gruf::Client::Error => e
        Gruf.logger.error e.error.to_h
      end
    end

    desc 'Demonstrate a failure response'
    task :get_fail do
      gruf_rake_configure_rpc!
      begin
        rpc_client = gruf_demo_build_client
        op = rpc_client.call(:GetFail, id: rand(100_000))
        Gruf.logger.info op.message.inspect
      rescue Gruf::Client::Errors::NotFound => e
        Gruf.logger.error "Client got a not found error: #{e.error.to_h}"
      rescue Gruf::Client::Errors::Validation => e
        Gruf.logger.error "Client got a validation error: #{e.error.to_h}"
      rescue Gruf::Client::Error => e
        Gruf.logger.error "Unknown error: #{e.error.to_h}"
      end
    end

    desc 'Demonstrate a field error in a failure response'
    task :get_field_error_fail do
      gruf_rake_configure_rpc!
      begin
        rpc_client = gruf_demo_build_client
        op = rpc_client.call(:GetFieldErrorFail, id: rand(100_000))
        Gruf.logger.info op.message.inspect
      rescue Gruf::Client::Error => e
        Gruf.logger.error e.error.to_h
      end
    end

    desc 'Demonstrate an exception in a failure response'
    task :get_exception do
      gruf_rake_configure_rpc!
      begin
        rpc_client = gruf_demo_build_client
        op = rpc_client.call(:GetException, id: rand(100_000))
        Gruf.logger.info op.message.inspect
      rescue Gruf::Client::Error => e
        Gruf.logger.error e.error.to_h
      end
    end

    desc 'Show an GRPC::Unauthorized response for a unary call'
    task :get_unauthorized do
      gruf_rake_configure_rpc!
      begin
        rpc_client = gruf_demo_build_client(options: { password: 'no' })
        op = rpc_client.call(:GetThing, id: rand(100_000))
        Gruf.logger.info op.message.inspect
      rescue Gruf::Client::Error => e
        Gruf.logger.error e.error.to_h
      end
    end

    desc 'Perform a performance test against a unary endpoint'
    task :performance, [:times, :sleep] do |_t, args|
      args.with_defaults(
        times: 3000,
        sleep: ENV.fetch('SERVER_SLEEP_TIME', 1).to_i
      )
      gruf_rake_configure_rpc!
      Gruf.logger.level = Logger::Severity::INFO

      Gruf.logger.info "Running GetThing #{args[:times]} times"

      threads = []
      call_divisor = ENV.fetch('CLIENT_CALL_SLEEP_DIVISOR', 1000).to_i
      args[:times].to_i.times do |idx|
        threads << Thread.new do
          sleep((idx / call_divisor).ceil)
          rpc_client = gruf_demo_build_client
          Gruf.logger.info "- #{idx}: Making call"
          op = rpc_client.call(:GetThing, id: idx, sleep: args[:sleep].to_i)
          Gruf.logger.info "-- #{idx}: #{op.message.inspect}"
        rescue Gruf::Client::Error => e
          Gruf.logger.error e.error.to_h
        end
      end
      threads.each(&:join)
      Gruf.logger.info 'Done.'
    end

    desc 'Call the health check'
    task :health_check do
      require 'gruf/controllers/health_controller'
      gruf_rake_configure_rpc!
      begin
        rpc_client = gruf_demo_build_client(service: ::Grpc::Health::V1::Health)
        op = rpc_client.call(:Check)
        Gruf.logger.info op.message.inspect
      rescue Gruf::Client::Error => e
        Gruf.logger.info e.error.to_h
      end
    end

    ##
    # @return [Gruf::Client]
    #
    def gruf_demo_build_client(service: nil, options: {}, client_options: {})
      service ||= Rpc::ThingService
      Gruf::Client.new(
        service: service,
        options: {
          hostname: ENV.fetch('HOST', 'localhost:8001'),
          username: ENV.fetch('USERNAME', 'grpc'),
          password: ENV.fetch('PASSWORD', 'magic')
        }.merge(options),
        client_options: {
          timeout: ENV.fetch('CLIENT_TIMEOUT', 30).to_i,
          interceptors: [TestClientInterceptor.new]
        }.merge(client_options)
      )
    end
  end
end

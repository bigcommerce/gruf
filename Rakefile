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
RSpec::Core::RakeTask.new(:spec)
task default: :spec

def gruf_rake_configure_rpc!
  require 'pry'
  require 'gruf'
  require File.realpath("#{File.dirname(__FILE__)}/spec/support/grpc_server.rb")
  require File.realpath("#{File.dirname(__FILE__)}/spec/support/error.rb")
  require File.realpath("#{File.dirname(__FILE__)}/spec/support/serializers/proto.rb")

  Gruf.configure do |c|
    c.error_serializer = Serializers::Proto
  end
end

# demo server tests
namespace :gruf do
  namespace :demo do
    task :get_thing do
      gruf_rake_configure_rpc!
      begin
        rpc_client = ::Gruf::Client.new(
          service: Rpc::ThingService,
          options: {
            hostname: ENV.fetch('HOST', '0.0.0.0:9001'),
            username: ENV.fetch('USERNAME', 'grpc'),
            password: ENV.fetch('PASSWORD', 'magic')
          }
        )
        op = rpc_client.call(:GetThing, id: rand(100_000))
        puts "#{op.message.inspect} in #{op.execution_time}ms"
      rescue Gruf::Client::Error => e
        puts e.error.to_h
      end
    end

    task :get_fail do
      gruf_rake_configure_rpc!
      begin
        rpc_client = ::Gruf::Client.new(
          service: Rpc::ThingService,
          options: {
            hostname: ENV.fetch('HOST', '0.0.0.0:9001'),
            username: ENV.fetch('USERNAME', 'grpc'),
            password: ENV.fetch('PASSWORD', 'magic')
          }
        )
        op = rpc_client.call(:GetFail, id: rand(100_000))
        puts op.message.inspect
      rescue Gruf::Client::Error => e
        puts e.error.to_h
      end
    end

    task :get_field_error_fail do
      gruf_rake_configure_rpc!
      begin
        rpc_client = ::Gruf::Client.new(
          service: Rpc::ThingService,
          options: {
            hostname: ENV.fetch('HOST', '0.0.0.0:9001'),
            username: ENV.fetch('USERNAME', 'grpc'),
            password: ENV.fetch('PASSWORD', 'magic')
          }
        )
        op = rpc_client.call(:GetFieldErrorFail, id: rand(100_000))
        puts op.message.inspect
      rescue Gruf::Client::Error => e
        puts e.error.to_h
      end
    end

    task :get_exception do
      gruf_rake_configure_rpc!
      begin
        rpc_client = ::Gruf::Client.new(
          service: Rpc::ThingService,
          options: {
            hostname: ENV.fetch('HOST', '0.0.0.0:9001'),
            username: ENV.fetch('USERNAME', 'grpc'),
            password: ENV.fetch('PASSWORD', 'magic')
          }
        )
        op = rpc_client.call(:GetException, id: rand(100_000))
        puts op.message.inspect
      rescue Gruf::Client::Error => e
        puts e.error.to_h
      end
    end

    task :get_unauthorized do
      gruf_rake_configure_rpc!
      begin
        rpc_client = ::Gruf::Client.new(
          service: Rpc::ThingService,
          options: {
            hostname: ENV.fetch('HOST', '0.0.0.0:9001'),
            username: ENV.fetch('USERNAME', 'grpc')
          }
        )
        op = rpc_client.call(:GetThing, id: rand(100_000))
        puts op.message.inspect
      rescue Gruf::Client::Error => e
        puts e.error.to_h
      end
    end
  end
end

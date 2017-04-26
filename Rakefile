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

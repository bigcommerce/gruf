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
$LOAD_PATH.unshift File.expand_path('pb', __dir__)
ENV['RACK_ENV'] ||= 'test'
require_relative 'simplecov_helper'
require 'gruf'
require 'ffaker'
require 'pry'

Dir["#{File.join(File.dirname(__FILE__), 'support')}/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.allow_message_expectations_on_nil = true
  end
  config.color = true

  config.before do
    if ENV.fetch('GRUF_DEBUG', 0).to_i.positive?
      logger = ::Logger.new($stdout)
      logger.level = ::Logger::Severity::DEBUG
      Gruf.logger = logger
      Gruf.grpc_logger = logger
    else
      Gruf.logger = Logger.new(File::NULL)
      Gruf.grpc_logger = Logger.new(File::NULL)
    end
  end
  config.around(:example, :run_thing_server) do |t|
    @server = build_server
    run_server(@server) do
      t.run
    end
  end

  include Gruf::Helpers
end

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
require 'grpc'
require 'active_support/core_ext/module/delegation'
require 'active_support/hash_with_indifferent_access'
require 'active_support/concern'
require 'active_support/inflector'
require 'base64'

# defining this module before the loader setup fixes double loading of this
# entrypoint file if this is a symlink
module Gruf
end

# use Zeitwerk to lazily autoload all the files in the lib directory
require 'zeitwerk'
loader = ::Zeitwerk::Loader.new
loader.tag = File.basename(__FILE__, '.rb')
# __FILE__ returns symlink path if the file is a symlink but __dir__ returns realpath
# so without realpath of the file, Zeitwerk custom rule for version file
# will fail in case of symlink
loader.inflector = ::Zeitwerk::GemInflector.new(File.realpath(__FILE__))
loader.ignore("#{__dir__}/gruf/integrations/rails/railtie.rb")
loader.ignore("#{__dir__}/gruf/controllers/health_controller.rb")
loader.push_dir(__dir__)
loader.setup

require_relative 'gruf/integrations/rails/railtie' if defined?(::Rails)

##
# Initializes configuration of gruf core module
#
module Gruf
  extend Configuration

  class << self
    def autoloaders
      Autoloaders
    end
  end
end

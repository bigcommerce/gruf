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
require 'active_support/concern'
require 'active_support/inflector'
require 'base64'
require_relative 'gruf/version'
require_relative 'gruf/logging'
require_relative 'gruf/loggable'
require_relative 'gruf/configuration'
require_relative 'gruf/errors/helpers'
require_relative 'gruf/controllers/base'
require_relative 'gruf/interceptors/registry'
require_relative 'gruf/interceptors/base'
require_relative 'gruf/timer'
require_relative 'gruf/response'
require_relative 'gruf/error'
require_relative 'gruf/client'
require_relative 'gruf/server'

##
# Initializes configuration of gruf core module
#
module Gruf
  extend Configuration
end

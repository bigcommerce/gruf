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
module Gruf
  module Integrations
    module Rails
      ##
      # Rails integration for Gruf, that currently only manages code autoloading in a Rails context
      #
      class Railtie < ::Rails::Railtie
        initializer 'gruf.initializer' do |app|
          config.after_initialize do
            # Remove autoloading of the controllers path from Rails' zeitwerk, so that we ensure Gruf's zeitwerk
            # properly manages them itself. This allows us to manage code reloading and logging in Gruf specifically
            app.config.eager_load_paths -= [Gruf.controllers_path] if app.config.respond_to?(:eager_load_paths)
            if ::Rails.respond_to?(:autoloaders) # if we're on a late enough version of rails
              ::Rails.autoloaders.each do |autoloader|
                autoloader.ignore(Gruf.controllers_path)
              end
            end
          end
        end
      end
    end
  end
end

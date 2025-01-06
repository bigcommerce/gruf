# frozen_string_literal: true

# Copyright (c) 2022-present, BigCommerce Pty. Ltd. All rights reserved
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
  ##
  # Module for accessing Gruf zeitwerk-based autoloaders
  #
  module Autoloaders
    class << self
      include Enumerable

      ##
      # Initialize the autoloaders with a given controllers path
      #
      # @param [String] controllers_path The path to Gruf Controllers
      #
      def load!(controllers_path:)
        controllers(controllers_path: controllers_path)
      end

      ##
      # Enumerate across the managed set of autoloaders
      #
      def each
        yield controllers
      end

      ##
      # Reload all files managed by the autoloader
      #
      def reload
        each(&:reload)
      end

      ##
      # Lazily instantiate and memoize the Gruf Controllers autoloader in a thread-safe manner
      #
      # @return [::Gruf::Controllers::Autoloader]
      #
      # rubocop:disable ThreadSafety/ClassInstanceVariable
      def controllers(controllers_path: nil)
        controllers_mutex do
          @controllers ||= ::Gruf::Controllers::Autoloader.new(path: controllers_path || ::Gruf.controllers_path)
        end
      end
      # rubocop:enable ThreadSafety/ClassInstanceVariable

      ##
      # Handle mutations to the controllers autoloader in a thread-safe manner
      #
      # rubocop:disable ThreadSafety/ClassInstanceVariable
      def controllers_mutex(&block)
        @controllers_mutex ||= begin
          require 'monitor'
          Monitor.new
        end
        @controllers_mutex.synchronize(&block)
      end
      # rubocop:enable ThreadSafety/ClassInstanceVariable
    end
  end
end

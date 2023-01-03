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
require 'concurrent/atomic/read_write_lock'

module Gruf
  module Controllers
    ##
    # Handles autoloading of Gruf controllers in the application path. This allows for code reloading on Gruf
    # controllers.
    #
    class Autoloader
      include ::Gruf::Loggable

      # @!attribute [r] path
      #   @return [String] The path for this autoloader
      attr_reader :path

      ##
      # @param [String] path
      # @param [Boolean] reloading
      # @param [String] tag
      #
      def initialize(path:, reloading: nil, tag: nil)
        super()
        @path = path
        @loader = ::Zeitwerk::Loader.new
        @loader.tag = tag || 'gruf-controllers'
        @setup = false
        @reloading_enabled = reloading || ::Gruf.development?
        setup!
      end

      ##
      # Reload all files managed by the autoloader, if reloading is enabled
      #
      def reload
        return unless @reloading_enabled

        reload_lock.with_write_lock do
          @loader.reload
        end
      end

      def with_fresh_controller(controller_name)
        return yield(controller_name.constantize) unless @reloading_enabled

        ::Gruf::Autoloaders.reload
        reload_lock.with_read_lock do
          yield(controller_name.constantize)
        end
      end

      private

      ##
      # @return [Boolean]
      #
      def setup!
        return true if @setup

        return false unless File.directory?(@path)

        @loader.enable_reloading if @reloading_enabled
        @loader.ignore("#{@path}/**/*_pb.rb")
        @loader.push_dir(@path)
        @loader.setup
        # always eager load RPC files, so that the service binder can bind the Gruf::Controller instantiation
        # to the gRPC Service classes
        @loader.eager_load
        @setup = true
      end

      ##
      # Handle thread-safe access to the loader
      #
      def reload_lock
        @reload_lock ||= Concurrent::ReadWriteLock.new
      end
    end
  end
end

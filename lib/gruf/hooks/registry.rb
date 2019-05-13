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
  module Hooks
    ##
    # Handles registration of hooks
    #
    class Registry
      class HookNotFoundError < StandardError; end

      def initialize
        @registry = []
      end

      ##
      # Add a hook to the registry
      #
      # @param [Class] hook_class The class of the hook to add
      # @param [Hash] options A hash of options to pass into the hook during initialization
      #
      def use(hook_class, options = {})
        hooks_mutex do
          @registry << {
            klass: hook_class,
            options: options
          }
        end
      end

      ##
      # Remove a hook from the registry
      #
      # @param [Class] hook_class The hook class to remove
      # @raise [HookNotFoundError] if the hook is not found
      #
      def remove(hook_class)
        pos = @registry.find_index { |opts| opts.fetch(:klass, '') == hook_class }
        raise HookNotFoundError if pos.nil?

        @registry.delete_at(pos)
      end

      ##
      # Insert a hook before another specified hook
      #
      # @param [Class] before_class The hook to insert before
      # @param [Class] hook_class The class of the hook to add
      # @param [Hash] options A hash of options to pass into the hook during initialization
      # @raise [HookNotFoundError] if the before hook is not found
      #
      def insert_before(before_class, hook_class, options = {})
        hooks_mutex do
          pos = @registry.find_index { |opts| opts.fetch(:klass, '') == before_class }
          raise HookNotFoundError if pos.nil?

          @registry.insert(
            pos,
            klass: hook_class,
            options: options
          )
        end
      end

      ##
      # Insert a hook after another specified hook
      #
      # @param [Class] after_class The hook to insert after
      # @param [Class] hook_class The class of the hook to add
      # @param [Hash] options A hash of options to pass into the hook during initialization
      # @raise [HookNotFoundError] if the after hook is not found
      #
      def insert_after(after_class, hook_class, options = {})
        hooks_mutex do
          pos = @registry.find_index { |opts| opts.fetch(:klass, '') == after_class }
          raise HookNotFoundError if pos.nil?

          @registry.insert(
            (pos + 1),
            klass: hook_class,
            options: options
          )
        end
      end

      ##
      # Return a list of the hook classes in the registry in their execution order
      #
      # @return [Array<Class>]
      #
      def list
        hooks_mutex do
          @registry.map { |h| h[:klass] }
        end
      end

      ##
      # Lazily load and return all hooks for the given request
      #
      # @return [Array<Gruf::Hooks::Base>]
      #
      def prepare
        is = []
        hooks_mutex do
          @registry.each do |o|
            is << o[:klass].new(options: o[:options])
          end
        end
        is
      end

      ##
      # Clear the registry
      #
      def clear
        hooks_mutex do
          @registry = []
        end
      end

      ##
      # @return [Integer] The number of hooks currently loaded
      #
      def count
        hooks_mutex do
          @registry ||= []
          @registry.count
        end
      end

      private

      ##
      # Handle mutations to the hook registry in a thread-safe manner
      #
      def hooks_mutex(&block)
        @hooks_mutex ||= begin
          require 'monitor'
          Monitor.new
        end
        @hooks_mutex.synchronize(&block)
      end
    end
  end
end

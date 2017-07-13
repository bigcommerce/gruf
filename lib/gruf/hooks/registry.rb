# coding: utf-8
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
require_relative 'base'
require_relative 'active_record/connection_reset'

module Gruf
  module Hooks
    ##
    # Registry of all hooks added
    #
    class Registry
      ##
      # Error class that represents when a gruf hook does not extend the base class
      #
      class HookDescendantError < StandardError; end

      class << self
        ##
        # Add an authentication strategy, either through a class or a block
        #
        # @param [String] name The name to represent the hook as
        # @param [Gruf::Hooks::Base|NilClass] hook The strategy class to add. If nil, will expect
        # a block that can be built as a hook instead
        # @return [Class] The hook that was added
        #
        def add(name, hook = nil, &block)
          base = Gruf::Hooks::Base
          hook ||= Class.new(base)
          hook.class_eval(&block) if block_given?

          # all hooks require either the before, after, or around method
          raise NoMethodError unless hook.method_defined?(:before) || hook.method_defined?(:after) || hook.method_defined?(:around) || hook.method_defined?(:outer_around)

          raise HookDescendantError, "Hooks must descend from #{base}" unless hook.ancestors.include?(base)

          _registry[name.to_sym] = hook
        end

        ##
        # Return a hook via a hash accessor syntax
        #
        # @return [Gruf::Instrumentation::Base|NilClass] The requested hook, if exists
        #
        def [](name)
          _registry[name.to_sym]
        end

        ##
        # Iterate over each hook in the registry
        #
        def each
          _registry.each do |name, s|
            yield name, s
          end
        end

        ##
        # @return [Hash<Class>] Return the registry represented as a Hash object
        #
        def to_h
          _registry
        end

        ##
        # @return [Boolean] Return true if there are any registered hooks
        #
        def any?
          count > 0
        end

        ##
        # @return [Integer] Return the number of registered hooks
        #
        def count
          to_h.keys.count
        end

        ##
        # @return [Hash] Clear all existing hooks from the registry
        #
        def clear
          @_registry = {}
        end

        private

        ##
        # @return [Hash<Class>] Return the current registry
        #
        def _registry
          @_registry ||= {}
        end
      end
    end
  end
end

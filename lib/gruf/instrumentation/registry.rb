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
require_relative 'statsd'
require_relative 'output_metadata_timer'

module Gruf
  module Instrumentation
    ##
    # Registry of all hooks added
    #
    class Registry
      class HookDescendantError < StandardError; end

      class << self
        ##
        # Add an authentication strategy, either through a class or a block
        #
        # @param [String] name
        # @param [Gruf::Hooks::Base|NilClass] hook
        # @return [Class]
        #
        def add(name, hook = nil, &block)
          base = Gruf::Instrumentation::Base
          hook ||= Class.new(base)
          hook.class_eval(&block) if block_given?

          # all hooks require either the before, after, or around method
          raise NoMethodError unless hook.method_defined?(:call)

          raise HookDescendantError, "Hooks must descend from #{base}" unless hook.ancestors.include?(base)

          _registry[name.to_sym] = hook
        end

        ##
        # Return a strategy type registry via a hash accessor syntax
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
        # @return [Hash<Class>]
        #
        def to_h
          _registry
        end

        ##
        # @return [Boolean]
        #
        def any?
          to_h.keys.count > 0
        end

        ##
        # @return [Hash]
        #
        def clear
          @_registry = {}
        end

        private

        ##
        # @return [Hash<Class>]
        #
        def _registry
          @_registry ||= {}
        end
      end
    end
  end
end

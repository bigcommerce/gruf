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
module Gruf
  module Authentication
    ##
    # Provides a modifiable repository of strategies for authentication
    #
    class Strategies
      ##
      # Error class that represents when a strategy does not extend the base class
      #
      class StrategyDescendantError < StandardError; end

      class << self
        ##
        # Add an authentication strategy, either through a class or a block
        #
        # @param [String] name The vanity name of the strategy being loaded
        # @param [Class|NilClass] strategy (Optional) The class that represents the strategy
        # @param [Proc] &block If given, will attempt to build a strategy class from the base class with this block
        # @return [Class] The loaded strategy
        #
        def add(name, strategy = nil, &block)
          base = Gruf::Authentication::Base
          strategy ||= Class.new(base)
          strategy.class_eval(&block) if block_given?

          # all strategies require the valid? method
          raise NoMethodError unless strategy.method_defined?(:valid?)

          raise StrategyDescendantError, "Strategies must descend from #{base}" unless strategy.ancestors.include?(base)

          _strategies[name.to_sym] = strategy
        end

        ##
        # Return a strategy via a hash accessor syntax
        #
        # @param [Symbol] label The name of the strategy
        # @return [Gruf::Authentication::Base] The requested strategy
        #
        def [](label)
          _strategies[label.to_sym]
        end

        ##
        # Iterate over each strategy and yield it to the caller
        #
        def each
          _strategies.each do |s|
            yield s
          end
        end

        ##
        # Return the loaded strategies as a hash
        #
        # @return [Hash<Class>] A name/strategy pair of loaded strategies
        #
        def to_h
          _strategies
        end

        ##
        # Return if there are any loaded strategies
        #
        # @return [Boolean] True if there are loaded strategies
        #
        def any?
          to_h.keys.count > 0
        end

        ##
        # Clear all given strategies
        #
        # @return [Hash] The newly empty hash
        #
        def clear
          @strategies = {}
        end

        private

        ##
        # @return [Hash<Class>]
        #
        def _strategies
          @strategies ||= {}
        end
      end
    end
  end
end

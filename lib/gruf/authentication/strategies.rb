# Copyright 2017, Bigcommerce Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
# 1. Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
# 3. Neither the name of BigCommerce Inc. nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
module Gruf
  module Authentication
    ##
    # Provides a modifiable repository of strategies for authentication
    #
    class Strategies
      class StrategyDescendantError; end

      class << self
        ##
        # Add an authentication strategy, either through a class or a block
        #
        # @param [String] name
        # @param [Class|NilClass] strategy
        # @return [Class]
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
        def [](label)
          _strategies[label.to_sym]
        end

        ##
        # Iterate over each
        #
        def each
          _strategies.each do |s|
            yield s
          end
        end

        ##
        # @return [Hash<Class>]
        #
        def to_h
          _strategies
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

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
  module Interceptors
    ##
    # Handles registration of interceptors
    #
    class Registry
      class InterceptorNotFoundError < StandardError; end

      def initialize
        @registry = []
      end

      ##
      # Add an interceptor to the registry
      #
      # @param [Class] interceptor_class The class of the interceptor to add
      # @param [Hash] options A hash of options to pass into the interceptor during initialization
      #
      def use(interceptor_class, options = {})
        interceptors_mutex do
          @registry << {
            klass: interceptor_class,
            options: options
          }
        end
      end

      ##
      # Remove an interceptor from the registry
      #
      # @param [Class] interceptor_class The interceptor class to remove
      # @raise [InterceptorNotFoundError] if the interceptor is not found
      #
      def remove(interceptor_class)
        pos = @registry.find_index { |opts| opts.fetch(:klass, '') == interceptor_class }
        raise InterceptorNotFoundError if pos.nil?

        @registry.delete_at(pos)
      end

      ##
      # Insert an interceptor before another specified interceptor
      #
      # @param [Class] before_class The interceptor to insert before
      # @param [Class] interceptor_class The class of the interceptor to add
      # @param [Hash] options A hash of options to pass into the interceptor during initialization
      # @raise [InterceptorNotFoundError] if the before interceptor is not found
      #
      def insert_before(before_class, interceptor_class, options = {})
        interceptors_mutex do
          pos = @registry.find_index { |opts| opts.fetch(:klass, '') == before_class }
          raise InterceptorNotFoundError if pos.nil?

          @registry.insert(
            pos,
            klass: interceptor_class,
            options: options
          )
        end
      end

      ##
      # Insert an interceptor after another specified interceptor
      #
      # @param [Class] after_class The interceptor to insert after
      # @param [Class] interceptor_class The class of the interceptor to add
      # @param [Hash] options A hash of options to pass into the interceptor during initialization
      # @raise [InterceptorNotFoundError] if the after interceptor is not found
      #
      def insert_after(after_class, interceptor_class, options = {})
        interceptors_mutex do
          pos = @registry.find_index { |opts| opts.fetch(:klass, '') == after_class }
          raise InterceptorNotFoundError if pos.nil?

          @registry.insert(
            (pos + 1),
            klass: interceptor_class,
            options: options
          )
        end
      end

      ##
      # Return a list of the interceptor classes in the registry in their execution order
      #
      # @return [Array<Class>]
      #
      def list
        interceptors_mutex do
          @registry.map { |h| h[:klass] }
        end
      end

      ##
      # Load and return all interceptors for the given request
      #
      # @param [Gruf::Controllers::Request] request
      # @param [Gruf::Error] error
      # @return [Array<Gruf::Interceptors::Base>]
      #
      def prepare(request, error)
        is = []
        interceptors_mutex do
          @registry.each do |o|
            is << o[:klass].new(request, error, o[:options])
          end
        end
        is
      end

      ##
      # Clear the registry
      #
      def clear
        interceptors_mutex do
          @registry = []
        end
      end

      ##
      # @return [Integer] The number of interceptors currently loaded
      #
      def count
        interceptors_mutex do
          @registry ||= []
          @registry.count
        end
      end

      private

      ##
      # Handle mutations to the interceptor registry in a thread-safe manner
      #
      def interceptors_mutex(&block)
        @interceptors_mutex ||= begin
          require 'monitor'
          Monitor.new
        end
        @interceptors_mutex.synchronize(&block)
      end
    end
  end
end

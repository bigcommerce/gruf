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
  module Hooks
    ##
    # Base class for a hook. Define before, around, outer_around, or after methods to utilize functionality.
    #
    class Base
      include Gruf::Loggable

      # @return [Gruf::Service] service The service to perform the hook against
      attr_reader :service
      # @return [Hash] options Options to use for the hook
      attr_reader :options

      ##
      # Initialize the hook and run setup
      #
      # @param [Gruf::Service] service The gruf service that the hook will perform against
      # @param [Hash] options (Optional) A hash of options for this hook
      #
      def initialize(service, options = {})
        @service = service
        @options = options
        setup
      end

      ##
      # Method that can be used to setup the hook prior to running it
      #
      def setup
        # noop
      end

      ##
      # @return [String] Returns the service name as a translated name separated by periods
      #
      def service_key
        service.class.name.underscore.tr('/', '.')
      end

      ##
      # Parse the method signature into a service.method name format
      #
      # @return [String] The parsed service method name
      #
      def method_key(call_signature)
        "#{service_key}.#{call_signature.to_s.gsub('_without_intercept', '')}"
      end
    end
  end
end

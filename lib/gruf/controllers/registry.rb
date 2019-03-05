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
  module Controllers
    ##
    # A controller registry to record controllers bound to services
    #
    class Registry
      def initialize
        @registry = {}
      end

      ##
      # Register a controller with a service bound to the controller.
      #
      # @param [Class] controller
      # @param [GRPC::GenericService] service
      def add(controller, service)
        @registry[controller] = service
      end

      ##
      # Return a service class by a controller class
      #
      # @param [Class] controller
      # @return [GRPC::GenericService]
      def [](controller)
        @registry[controller]
      end

      ##
      # Iterate each controller with bound service
      #
      # @yieldparam [Class] controller
      # @yieldparam [GRPC::GenericService] service
      def each
        @registry.each { |controller, service| yield controller, service }
      end
    end
  end
end

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
  ##
  # Register and require Gruf services so they can be served.
  #
  class ServiceLoader
    include Gruf::Loggable

    SERVICE_IDENTIFIER = 'include Gruf::Service'.freeze

    attr_accessor :services, :load_path

    ##
    # @param [Array<Class>] services The services that should be served
    # @param [String] load_path The directory the Gruf::Service files reside
    #
    def initialize(services: [], load_path: Gruf.servers_path)
      @load_path = load_path
      register_services(services)
    end

    ##
    # Require all Gruf::Service's in the load_path. Files in the load_path that aren't
    # identified as Gruf::Service's will not be required explicitly.
    #
    def require_services
      files_in_load_path = Dir["#{load_path}/**/*.rb"]
      files_in_load_path.each do |f|
        file_text = File.read(f)

        if file_text.include?(SERVICE_IDENTIFIER)
          logger.info "- Loading gRPC service file: #{f}"
          require f
        end
      end
    end

    private

    ##
    # Register services with the loader
    #
    # :nocov:
    def register_services(svcs)
      self.services = Array(svcs).concat(Gruf.services).compact.uniq
    end
    # :nocov:

  end
end

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
require 'grpc/health/v1/health_services_pb'

module Gruf
  module Controllers
    ##
    # Dynamic standard grpc health check controller. Can be used as-is, or can use ::Gruf.health_check_hook to
    # provide custom responses.
    #
    class HealthController < Gruf::Controllers::Base
      bind ::Grpc::Health::V1::Health::Service

      def check
        health_proc = ::Gruf.health_check_hook
        return health_proc.call(request, error) if !health_proc.nil? && health_proc.respond_to?(:call)

        ::Grpc::Health::V1::HealthCheckResponse.new(
          status: ::Grpc::Health::V1::HealthCheckResponse::ServingStatus::SERVING
        )
      end
    end
  end
end

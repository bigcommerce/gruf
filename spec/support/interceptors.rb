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

##########################################################################################
# Server Interceptors
##########################################################################################
class TestServerInterceptor < ::Gruf::Interceptors::ServerInterceptor
  def call
    Math.sqrt(4)
    yield
  end
end

class TestServerInterceptor2 < ::Gruf::Interceptors::ServerInterceptor
  def call
    Math.sqrt(16)
    yield
  end
end

class TestServerInterceptor3 < ::Gruf::Interceptors::ServerInterceptor
  def call
    Math.sqrt(256)
    yield
  end
end

class TestServerInterceptor4 < ::Gruf::Interceptors::ServerInterceptor
  def call
    Math.sqrt(65_536)
    yield
  end
end

class TestServerInterceptorInstanceVar < ::Gruf::Interceptors::ServerInterceptor
  def call
    @count ||= 0
    @count += 1
    Gruf.logger.info "COUNT: #{@count}"
    yield
  end
end

##########################################################################################
# Client Interceptors
##########################################################################################

class TestClientInterceptor < Gruf::Interceptors::ClientInterceptor
  def call(request_context:)
    timed = Gruf::Timer.time do
      yield
    end
    logger.info "Got response from server in client interceptor #{request_context.route_key} of type #{request_context.type}: #{timed.time.to_f.round(2)}ms"
    timed.result
  end
end

##########################################################################################
# Base Interceptors
##########################################################################################

class TestBaseInterceptor < ::Gruf::Interceptors::Base
  def call
    Math.sqrt(4)
    yield
  end
end

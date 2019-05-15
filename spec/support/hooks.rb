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

##########################################################################################
# Hooks
##########################################################################################
class TestHook1 < ::Gruf::Hooks::Base
  def before_server_start(server:)
    logger.info "Got before_server_start in TestHook1: #{server.class}"
    Math.sqrt(4)
  end

  def after_server_stop(server:)
    logger.info "Got after_server_stop in TestHook1: #{server.class}"
    Math.sqrt(16)
  end
end

class TestHook2 < ::Gruf::Hooks::Base
  def before_server_start(server:)
    logger.info "Got before_server_start in TestHook2: #{server.class}"
    Math.sqrt(4)
  end

  def after_server_stop(server:)
    logger.info "Got after_server_stop in TestHook2: #{server.class}"
    Math.sqrt(16)
  end
end

class TestHook3 < ::Gruf::Hooks::Base
  def before_server_start(server:)
    logger.info "Got before_server_start in TestHook3: #{server.class}"
    Math.sqrt(4)
  end
end

class TestHook4 < ::Gruf::Hooks::Base

end

class TestFailHook1 < ::Gruf::Hooks::Base
  def before_server_start(server:)
    logger.info "Got before_server_start in TestFailHook1: #{server.class}"
    raise StandardError, 'Failure'
  end

  def after_server_stop(server:)
    logger.info "Got after_server_stop in TestFailHook1: #{server.class}"
    raise StandardError, 'Failure'
  end
end

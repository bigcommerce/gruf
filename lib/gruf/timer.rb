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
  class Timer

    class Result
      attr_reader :result
      attr_reader :time

      ##
      # @param [Object] result
      # @param [Float] time
      #
      def initialize(result, time)
        @result = result
        @time = time.to_f
      end

      ##
      # @return [Boolean]
      #
      def success?
        !result.is_a?(GRPC::BadStatus)
      end
    end

    ##
    # @return [Timer::Result]
    #
    def self.time
      start_time = Time.now
      begin
        result = yield
      rescue GRPC::BadStatus => e
        result = e
      end
      end_time = Time.now
      elapsed = (end_time - start_time) * 1000.0
      Result.new(result, elapsed)
    end
  end
end

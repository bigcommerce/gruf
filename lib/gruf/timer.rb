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
  # Times a given block and returns the result and the elapsed time as a Float
  #
  #   result = Timer.time { do_my_thing }
  #
  class Timer
    ##
    # Represents a timer result that contains both the elapsed time and the result of the block
    #
    #   result = Timer.time { do_my_thing }
    #   result.time # => 1.10123
    #   result.result # => 'my_thing_is_done'
    #
    class Result
      # @return [Object] result The result of the block that was called
      attr_reader :result
      # @return [Float] time The time, in ms, of the block execution
      attr_reader :time

      ##
      # Initialize the result object
      #
      # @param [Object] result The result of the block that was called
      # @param [Float] time The time, in ms, of the block execution
      #
      def initialize(result, time)
        @result = result
        @time = time.to_f
      end

      ##
      # Was this result a successful result?
      #
      # @return [Boolean] Whether or not this result was a success
      #
      def success?
        !result.is_a?(GRPC::BadStatus) && !result.is_a?(StandardError) && !result.is_a?(GRPC::Core::CallError)
      end
    end

    ##
    # Times a given block by recording start and end times
    #
    #  result = Timer.time { do_my_thing }
    #
    # @return [Timer::Result] Returns the timed result of the block
    #
    def self.time
      start_time = Time.now
      begin
        result = yield
      rescue GRPC::BadStatus, StandardError, GRPC::Core::CallError => e
        result = e
      end
      end_time = Time.now
      elapsed = (end_time - start_time) * 1000.0
      Result.new(result, elapsed)
    end
  end
end

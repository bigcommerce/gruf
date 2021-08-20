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
module Gruf
  module Interceptors
    ##
    # Utility class that can be used by interceptors to time requests
    #
    class Timer
      ##
      # Represents a timed result for an interceptor
      #
      class Result
        # @!attribute [r] message
        #   @return [Object] The returned protobuf message
        attr_reader :message
        # @return [r] elapsed
        #   @return [Float] The time elapsed for this interceptor to execute
        attr_reader :elapsed

        ##
        # @param [Object] message The protobuf message
        # @param [Float] elapsed The elapsed time of the request
        # @param [Boolean] successful If the request was successful
        #
        def initialize(message, elapsed, successful)
          @message = message
          @elapsed = elapsed.to_f
          @successful = successful ? true : false
        end

        ##
        # @return [Boolean] True if this was a successful request
        #
        def successful?
          @successful
        end

        ##
        # @return [String] The name of the message class
        #
        def message_class_name
          @message.class.name.to_s
        end

        ##
        # Return the execution time rounded to a specified precision
        #
        # @param [Integer] precision The amount of decimal places to round to
        # @return [Float] The execution time rounded to the appropriate decimal point
        #
        def elapsed_rounded(precision: 2)
          @elapsed.to_f.round(precision)
        end
      end

      ##
      # Time a given code block and return a Timer::Result object
      #
      # @return [Gruf::Interceptors::Timer::Result]
      #
      def self.time
        start_time = Time.now
        message = yield
        end_time = Time.now
        elapsed = (end_time - start_time) * 1000.0
        Result.new(message, elapsed, true)
      rescue GRPC::BadStatus => e
        end_time = Time.now
        elapsed = (end_time - start_time) * 1000.0
        Result.new(e, elapsed, false)
      end
    end
  end
end

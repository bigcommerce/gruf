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
    module Instrumentation
      ##
      # Appends the timer metadata to the active call output metadata
      #
      class OutputMetadataTimer < ::Gruf::Interceptors::ServerInterceptor
        delegate :active_call, to: :request

        ##
        # Handle the instrumented response. Note: this will only instrument timings of _successful_ responses.
        #
        def call
          return unless active_call.respond_to?(:output_metadata)

          result = Gruf::Interceptors::Timer.time do
            yield
          end
          output_metadata.update(metadata_key => result.elapsed.to_s)

          raise result.message unless result.successful?

          result.message
        end

        private

        ##
        # @return [Symbol] The metadata key that the time result should be set to
        #
        def metadata_key
          options.fetch(:metadata_key, :timer).to_sym
        end

        ##
        # @return [Hash]
        #
        def output_metadata
          active_call.output_metadata
        end
      end
    end
  end
end

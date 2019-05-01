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
require 'concurrent'

module Gruf
  ##
  # Ensures that we only have one active call to a given endpoint with a given set of params. This can be useful
  # to mitigate thundering herds.
  #
  class SynchronizedClient < Gruf::Client
    attr_reader :unsynchronized_methods

    ##
    # Initialize the client and setup the stub
    #
    # @param [Module] service The namespace of the client Stub that is desired to load
    # @param [Hash] options A hash of options for the client
    # @option options [Array] :unsynchronized_methods A list of methods (as symbols) that
    #   should be excluded from synchronization
    # @option options [Integer] :internal_cache_expiry The length of time to keep results
    #   around for other threads to fetch (in seconds)
    # @param [Hash] client_options A hash of options to pass to the gRPC client stub
    #
    def initialize(service:, options: {}, client_options: {})
      @unsynchronized_methods = options.delete(:unsynchronized_methods) { [] }
      @expiry = options.delete(:internal_cache_expiry) { Gruf.synchronized_client_internal_cache_expiry }
      @locks = Concurrent::Map.new
      @results = Concurrent::Map.new
      super
    end

    ##
    # Call the client's method with given params. If another call is already active for the same endpoint and the same
    # params, block until the active call is complete. When unblocked, callers will get a copy of the original result.
    #
    # @param [String|Symbol] request_method The method that is being requested on the service
    # @param [Hash] params (Optional) A hash of parameters that will be inserted into the gRPC request
    #   message that is required for the given above call
    # @param [Hash] metadata (Optional) A hash of metadata key/values that are transported with the client request
    # @param [Hash] opts (Optional) A hash of options to send to the gRPC request_response method
    # @return [Gruf::Response] The response from the server
    # @raise [Gruf::Client::Error|GRPC::BadStatus] If an error occurs, an exception will be raised according to the
    # error type that was returned
    #
    def call(request_method, params = {}, metadata = {}, opts = {}, &block)
      # Allow for bypassing extra behavior for selected methods
      return super if unsynchronized_methods.include?(request_method.to_sym)

      # Generate a unique key based on the method and params
      key = "#{request_method}.#{params.hash}"

      # Create a lock for this call if we haven't seen it already, then acquire it
      lock = @locks.compute_if_absent(key) { Mutex.new }
      lock.synchronize do
        # Return value from results cache if it exists. This occurs for callers that were
        # waiting on the lock while the first caller was making the actual grpc call.
        response = @results.get(lock)
        if response
          Gruf.logger.debug "Returning cached result for #{key}:#{lock.inspect}"
          next response
        end

        # Make the grpc call and record response for other callers that are blocked
        # on the same lock
        response = super
        @results.put(lock, response)

        # Schedule a task to come in later and clean out result to prevent memory bloat
        Concurrent::ScheduledTask.new(@expiry, args: [@results, lock]) { |h, k| h.delete(k) }.execute

        # Remove the lock from the map. The next caller to come through with the
        # same params will create a new lock and start the process over again.
        # Anyone who was waiting on this call will be using a local reference
        # to the same lock as us, and will fetch the result from the cache.
        @locks.delete(key)

        # Return response
        response
      end
    end
  end
end

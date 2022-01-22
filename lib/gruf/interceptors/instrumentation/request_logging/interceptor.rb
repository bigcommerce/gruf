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
require 'socket'
require_relative 'formatters/base'
require_relative 'formatters/logstash'
require_relative 'formatters/plain'

module Gruf
  module Interceptors
    module Instrumentation
      module RequestLogging
        ##
        # Represents an error if the formatter does not extend the base formatter
        #
        class InvalidFormatterError < StandardError; end

        ##
        # Handles Rails-style request logging for gruf services.
        #
        # This is added by default to gruf servers; if you have `Gruf.use_default_hooks = false`, you can add it back
        # manually by doing:
        #
        #   Gruf::Instrumentation::Registry.add(:request_logging, Gruf::Instrumentation::RequestLogging::Hook)
        #
        class Interceptor < ::Gruf::Interceptors::ServerInterceptor
          # Default mappings of codes to log levels...
          LOG_LEVEL_MAP = {
            'GRPC::Ok' => :debug,
            'GRPC::InvalidArgument' => :debug,
            'GRPC::NotFound' => :debug,
            'GRPC::AlreadyExists' => :debug,
            'GRPC::OutOfRange' => :debug,
            'GRPC::Unauthenticated' => :warn,
            'GRPC::PermissionDenied' => :warn,
            'GRPC::Unknown' => :error,
            'GRPC::Internal' => :error,
            'GRPC::DataLoss' => :error,
            'GRPC::FailedPrecondition' => :error,
            'GRPC::Unavailable' => :error,
            'GRPC::DeadlineExceeded' => :error,
            'GRPC::Cancelled' => :error
          }.freeze

          ###
          # Log the request, sending it to the appropriate formatter
          #
          # @return [::Object]
          #
          def call(&block)
            return yield if options.fetch(:ignore_methods, [])&.include?(request.method_name)

            result = Gruf::Interceptors::Timer.time(&block)

            # Fetch log level options and merge with default...
            log_level_map = LOG_LEVEL_MAP.merge(options.fetch(:log_levels, {}))

            # A result is either successful, or, some level of feedback handled in the else block...
            if result.successful?
              type = log_level_map['GRPC::Ok'] || :debug
              status_name = 'GRPC::Ok'
            else
              type = log_level_map[result.message_class_name] || :error
              status_name = result.message_class_name
            end

            payload = {}
            if !request.client_streamer? && !request.bidi_streamer?
              payload[:params] = sanitize(request.message.to_h) if options.fetch(:log_parameters, false)
              payload[:message] = message(request, result)
              payload[:status] = status(result.message, result.successful?)
            else
              payload[:params] = {}
              payload[:message] = ''
              payload[:status] = GRPC::Core::StatusCodes::OK
            end

            payload[:service] = request.service_key
            payload[:method] = request.method_key
            payload[:action] = request.method_key
            payload[:grpc_status] = status_name
            payload[:duration] = result.elapsed_rounded
            payload[:thread_id] = Thread.current.object_id
            payload[:time] = Time.now.to_s
            payload[:host] = Socket.gethostname

            logger.send(type, formatter.format(payload, request: request, result: result))

            raise result.message unless result.successful?

            result.message
          end

          private

          ##
          # @return [::Gruf::Logger]
          #
          def logger
            @logger ||= (options.fetch(:logger, nil) || Gruf.logger)
          end

          ##
          # Return an appropriate log message dependent on the status
          #
          # @param [Gruf::Controllers::Request] request
          # @param [Gruf::Interceptors::Timer::Result] result
          # @return [String] The appropriate message body
          #
          def message(request, result)
            return "[GRPC::Ok] (#{request.method_name})" if result.successful?

            "[#{result.message_class_name}] (#{request.method_name}) #{result.message.message}"
          end

          ##
          # Return the proper status code for the response
          #
          # @param [Object] response The response object
          # @param [Boolean] successful If the response was successful
          # @return [Integer] The proper status code
          #
          def status(response, successful)
            successful ? GRPC::Core::StatusCodes::OK : response.code
          end

          ##
          # Determine the appropriate formatter for the request logging
          #
          # @return [Gruf::Instrumentation::RequestLogging::Formatters::Base]
          #
          def formatter
            unless @formatter
              fmt = options.fetch(:formatter, :plain)
              @formatter = case fmt
                           when Symbol
                             prefix = 'Gruf::Interceptors::Instrumentation::RequestLogging::Formatters::'
                             klass = "#{prefix}#{fmt.to_s.capitalize}"
                             fmt = klass.constantize.new
                           when Class
                             fmt = fmt.new
                           else
                             fmt
                           end
              raise InvalidFormatterError unless fmt.is_a?(Formatters::Base)
            end
            @formatter
          end

          ##
          # Redact any blocklisted params and return an updated hash
          #
          # @param [Hash] params The hash of parameters to sanitize
          # @return [Hash] The sanitized params in hash form
          #
          def sanitize(params = {})
            blocklists = (options.fetch(:blocklist, []) || []).map(&:to_s)
            redacted_string = options.fetch(:redacted_string, nil) || 'REDACTED'
            blocklists.each do |blocklist|
              parts = blocklist.split('.').map(&:to_sym)
              redact!(parts, 0, params, redacted_string)
            end
            params
          end

          ##
          # Helper method to recursively redact based on the blocklist
          #
          # @param [Array] parts The blocklist. ex. 'data.schema' -> [:data, :schema]
          # @param [Integer] idx The current index of the blocklist
          # @param [Hash] params The hash of parameters to sanitize
          # @param [String] redacted_string The custom redact string
          #
          def redact!(parts = [], idx = 0, params = {}, redacted_string = 'REDACTED')
            return unless parts.is_a?(Array) && params.is_a?(Hash)

            return if idx >= parts.size || !params.key?(parts[idx])

            if idx == parts.size - 1
              if params[parts[idx]].is_a? Hash
                hash_deep_redact!(params[parts[idx]], redacted_string)
              else
                params[parts[idx]] = redacted_string
              end
              return
            end
            redact!(parts, idx + 1, params[parts[idx]], redacted_string)
          end

          ##
          # Helper method to recursively redact the value of all hash keys
          #
          # @param [Hash] hash Part of the hash of parameters to sanitize
          # @param [String] redacted_string The custom redact string
          #
          def hash_deep_redact!(hash, redacted_string)
            hash.each_key do |key|
              if hash[key].is_a? Hash
                hash_deep_redact!(hash[key], redacted_string)
              else
                hash[key] = redacted_string
              end
            end
          end
        end
      end
    end
  end
end

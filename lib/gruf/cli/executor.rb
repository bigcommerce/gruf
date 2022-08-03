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
require 'slop'

module Gruf
  module Cli
    ##
    # Handles execution of the gruf binstub, along with command-line arguments
    #
    class Executor
      class NoServicesBoundError < StandardError; end

      ##
      # @param [Hash|ARGV]
      # @param [::Gruf::Server|NilClass] server
      # @param [Array<Class>|NilClass] services
      # @param [Gruf::Hooks::Executor|NilClass] hook_executor
      # @param [Logger|NilClass] logger
      #
      def initialize(
        args = ARGV,
        server: nil,
        services: nil,
        hook_executor: nil,
        logger: nil
      )
        @args = args
        setup! # ensure we set some defaults from CLI here so we can allow configuration
        @services = services.is_a?(Array) ? services : []
        @hook_executor = hook_executor || Gruf::Hooks::Executor.new(hooks: Gruf.hooks&.prepare)
        @server = server || Gruf::Server.new(Gruf.server_options)
        @logger = logger || Gruf.logger || ::Logger.new($stderr)
      end

      ##
      # Run the server
      #
      def run
        exception = nil

        # allow lazy registering globally as late as possible, this allows more flexible binstub injections
        register_services!

        begin
          @hook_executor.call(:before_server_start, server: @server)
          @server.start!
        rescue StandardError => e
          exception = e
          # Catch the exception here so that we always ensure the post hook runs
          # This allows systems wanting to provide external server instrumentation
          # the ability to properly handle server failures
          @logger.fatal("FATAL ERROR: #{e.message} #{e.backtrace.join("\n")}")
        end
        @hook_executor.call(:after_server_stop, server: @server)
        raise exception if exception
      end

      private

      ##
      # Setup options for CLI execution and configure Gruf based on inputs
      #
      def setup!
        @options = parse_options

        Gruf.server_binding_url = @options[:host] if @options[:host]
        if @options.suppress_default_interceptors?
          Gruf.interceptors.remove(Gruf::Interceptors::ActiveRecord::ConnectionReset)
          Gruf.interceptors.remove(Gruf::Interceptors::Instrumentation::OutputMetadataTimer)
        end
        Gruf.backtrace_on_error = true if @options.backtrace_on_error?
      end

      ##
      # Parse all CLI arguments into an options result
      #
      # @return [Slop::Result]
      #
      def parse_options
        ::Slop.parse(@args) do |o|
          o.null '-h', '--help', 'Display help message' do
            puts o
            exit(0)
          end
          o.string '--host', 'Specify the binding url for the gRPC service'
          o.string '--services', 'Optional. Run gruf with only the passed gRPC service classes (comma-separated)'
          o.bool '--suppress-default-interceptors', 'Do not use the default interceptors'
          o.bool '--backtrace-on-error', 'Push backtraces on exceptions to the error serializer'
          o.null '-v', '--version', 'print gruf version' do
            puts Gruf::VERSION
            exit(0)
          end
        end
      end

      ##
      # Register services; note that this happens after gruf is initialized, and right before the server is run.
      # This will interpret the services to run in the following precedence:
      # 1. initializer arguments to the executor
      # 2. ARGV options (the --services option)
      # 3. services set to the global gruf configuration (Gruf.services)
      #
      def register_services!
        # wait to load controllers until last possible second to allow late configuration
        ::Gruf.autoloaders.load!(controllers_path: Gruf.controllers_path)

        # first check initializer arguments
        unless @services.any?
          # next check CLI arguments
          @services = @options[:services].to_s.split(',').map(&:strip).uniq
          # finally, if none, use global gruf autoloaded services
          @services = ::Gruf.services unless @services.any?
        end

        @services.map! { |s| s.is_a?(Class) ? s : s.constantize }

        if @services.any?
          @services.each { |s| @server.add_service(s) }
          return
        end

        raise NoServicesBoundError
      rescue NoServicesBoundError
        @logger.fatal 'FATAL ERROR: No services bound to this gruf process; please bind a service to a Gruf ' \
                      'controller to start the server successfully'
        exit(1)
      rescue NameError => e
        @logger.fatal 'FATAL ERROR: Could not start server; passed services to run are not loaded or valid ' \
                      "constants: #{e.message}"
        exit(1)
      rescue StandardError => e
        @logger.fatal "FATAL ERROR: Could not start server: #{e.message}"
        exit(1)
      end
    end
  end
end

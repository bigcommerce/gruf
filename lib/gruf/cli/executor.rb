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
      include Gruf::Loggable

      class NoServicesBoundError < StandardError; end

      KILL_SIGNALS = %w[INT TERM QUIT].freeze

      # Run CLI inside the current process and shutdown at exit
      def self.embed!(args = [])
        new(embedded: true).tap do |cli|
          cli.run(args)
          at_exit { cli.shutdown }
        end
      end

      attr_reader :server, :embedded
      alias embedded? embedded

      ##
      # @param [Boolean] embedded
      # @param [::Gruf::Server|NilClass] server
      # @param [Array<Class>|NilClass] services
      # @param [Gruf::Hooks::Executor|NilClass] hook_executor
      #
      def initialize(
        embedded: false,
        server: nil,
        services: nil,
        hook_executor: nil
      )
        @embedded = embedded
        @services = services.is_a?(Array) ? services : []
        @hook_executor = hook_executor
        @server = server
      end

      ##
      # Run the server
      # @param [Hash|ARGV] args
      #
      def run(args = [])
        @args = args
        setup_options! # ensure we set some defaults from CLI here so we can allow configuration
        setup!

        exception = nil

        update_proc_title(:starting)
        begin
          @services.each { |s| @server.add_service(s) }
          @hook_executor.call(:before_server_start, server: @server)
          @server.start
        rescue StandardError => e
          exception = e
          # Catch the exception here so that we always ensure the post hook runs
          # This allows systems wanting to provide external server instrumentation
          # the ability to properly handle server failures
          logger.fatal "FATAL ERROR: #{e.message} #{e.backtrace.join("\n")}"
        end
        update_proc_title(:serving)

        if exception
          shutdown
          raise exception
        end

        shutdown_when_terminated unless embedded?
      end

      def shutdown
        server&.stop
        @hook_executor.call(:after_server_stop, server: @server)
        update_proc_title(:stopped)
      end

      private

      def shutdown_when_terminated
        wait_till_terminated
      rescue Interrupt => e
        logger.info "[gruf] Stopping... #{e.message}"
        shutdown
        logger.info '[gruf] Stopped. Good-bye!'
      end

      ##
      # Setup options for CLI execution and configure Gruf based on inputs
      #
      def setup_options!
        opts = parse_options

        Gruf.server_binding_url = opts[:host] if opts[:host]
        if opts.suppress_default_interceptors?
          Gruf.interceptors.remove(Gruf::Interceptors::ActiveRecord::ConnectionReset)
          Gruf.interceptors.remove(Gruf::Interceptors::Instrumentation::OutputMetadataTimer)
        end
        Gruf.backtrace_on_error = true if opts.backtrace_on_error?
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
          o.bool '--suppress-default-interceptors', 'Do not use the default interceptors'
          o.bool '--backtrace-on-error', 'Push backtraces on exceptions to the error serializer'
          o.null '-v', '--version', 'print gruf version' do
            puts Gruf::VERSION
            exit(0)
          end
        end
      end

      ##
      # Setup Gruf
      #
      def setup!
        @server ||= Gruf::Server.new(Gruf.server_options)
        @hook_executor ||= Gruf::Hooks::Executor.new(hooks: Gruf.hooks&.prepare)

        # wait to load controllers until last possible second to allow late configuration
        ::Gruf.autoloaders.load!(controllers_path: Gruf.controllers_path)

        setup_services
      end

      def setup_services
        # allow lazy registering globally as late as possible, this allows more flexible binstub injections
        @services = ::Gruf.services unless @services&.any?
        unless @services.any? # rubocop:disable Lint/GuardClause
          raise NoServicesBoundError,
                'No services bound to this gruf process; please bind a service to a Gruf controller ' \
                'to start the server successfully'
        end
      end

      def wait_till_terminated
        self_read = setup_signals

        readable_io = IO.select([self_read]) # rubocop:disable Lint/IncompatibleIoSelectWithFiberScheduler
        signal = readable_io.first[0].gets.strip
        raise Interrupt, "SIG#{signal} received"
      end

      def setup_signals
        self_read, self_write = IO.pipe

        KILL_SIGNALS.each do |signal|
          trap signal do
            self_write.puts signal
          end
        end

        self_read
      end

      ##
      # Updates proc name/title
      #
      # @param [Symbol] state
      #
      # :nocov:
      def update_proc_title(state)
        Process.setproctitle("gruf #{Gruf::VERSION} -- #{state}")
      end

      # :nocov:
    end
  end
end

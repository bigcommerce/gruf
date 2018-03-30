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
      attr_reader :opts

      ##
      # @param [Hash|ARGV]
      #
      def initialize(args = ARGV)
        @args = args
        setup!
      end

      ##
      # Run the server
      #
      def run
        daemonize
        write_pid

        server = Gruf::Server.new(Gruf.server_options)
        Gruf.services.each { |s| server.add_service(s) }
        server.start!

        exit(0)
      rescue StandardError => e
        msg = "FATAL ERROR: #{e.message} #{e.backtrace.join("\n")}"
        logger = Gruf.logger ? Gruf.logger : Logger.new(STDERR)
        logger.fatal msg
        exit(0)
      end

      private

      ##
      # Setup options for CLI execution and configure Gruf based on inputs
      #
      def setup!
        @opts = Slop.parse(@args) do |o|
          o.null '-h', '--help', 'Display help message' do
            puts o
            exit(0)
          end
          o.string '--host', 'Specify the binding url for the gRPC service'
          o.bool '-d', '--daemon', 'Daemonize process'
          o.string '-P', '--pidfile', 'Path to pidfile'
          o.bool '--suppress-default-interceptors', 'Do not use the default interceptors'
          o.bool '--backtrace-on-error', 'Push backtraces on exceptions to the error serializer'
          o.null '-v', '--version', 'print gruf version' do
            puts Gruf::VERSION
            exit(0)
          end
        end

        Gruf.server_binding_url = @opts[:host] if @opts[:host]
        Gruf.use_default_interceptors = false if @opts.suppress_default_interceptors?
        Gruf.backtrace_on_error = true if @opts.backtrace_on_error?
      end

      def daemonize
        return if !@opts.daemon?

        files_to_reopen = []
        ObjectSpace.each_object(File) do |file|
          files_to_reopen << file unless file.closed?
        end

        ::Process.daemon

        files_to_reopen.each do |file|
          begin
            file.reopen file.path, "a+"
            file.sync = true
          rescue ::Exception
          end
        end

        Gruf.logger.reopen
        $stdin.reopen('/dev/null')
      end

      def write_pid
        if path = @opts[:pidfile]
          pidfile = File.expand_path(path)
          File.open(pidfile, 'w') do |f|
            f.puts ::Process.pid
          end
        end
      end
    end
  end
end

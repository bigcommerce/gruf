$stdout.sync = true

require 'singleton'
require 'optparse'

module Gruf
  class CLI
    include Singleton

    attr_accessor :options

    def run(args=ARGV)
      @options = parse_options(args)

      daemonize
      write_pid

      if !options[:daemon]
        Gruf.logger.info 'Starting processing, hit Ctrl-C to stop'
      end

      begin
        server = Gruf::Server.new(Gruf.server_options)
        Gruf.services.each { |s| server.add_service(s) }
        server.start!
        exit 0
      rescue Interrupt
        Gruf.logger.info 'Shutting down'
        exit 0
      end
    end

    private

    def daemonize
      return if !options[:daemon]

      files_to_reopen = []
      ObjectSpace.each_object(File) do |file|
        files_to_reopen << file unless file.closed?
      end

      ::Process.daemon(true, true)

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

    def parse_options(argv)
      opts = {}

      @parser = OptionParser.new do |o|
        o.banner = "Usage: bundle exec gruf [options]"

        o.on '-d', '--daemon', "Daemonize process" do |arg|
          opts[:daemon] = arg
        end

        o.on '-P', '--pidfile PATH', "path to pidfile" do |arg|
          opts[:pidfile] = arg
        end

        o.on '-V', '--version', "Print version and exit" do |arg|
          puts "Gruf #{Gruf::VERSION}"
          exit(0)
        end
      end

      @parser.parse!(argv)
      opts
    end

    def write_pid
      if path = options[:pidfile]
        pidfile = File.expand_path(path)
        File.open(pidfile, 'w') do |f|
          f.puts ::Process.pid
        end
      end
    end

  end
end

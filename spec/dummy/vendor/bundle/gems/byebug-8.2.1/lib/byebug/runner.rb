require 'optparse'
require 'English'
require 'byebug/core'
require 'byebug/version'
require 'byebug/helpers/parse'
require 'byebug/option_setter'
require 'byebug/processors/control_processor'

module Byebug
  #
  # Responsible for starting the debugger when started from the command line.
  #
  class Runner
    include Helpers::ParseHelper

    #
    # Error class signaling absence of a script to debug.
    #
    class NoScript < StandardError; end

    #
    # Error class signaling a non existent script to debug.
    #
    class NonExistentScript < StandardError; end

    #
    # Error class signaling a script with invalid Ruby syntax.
    #
    class InvalidScript < StandardError; end

    #
    # Special working modes that don't actually start the debugger.
    #
    attr_reader :help, :version, :remote

    #
    # Signals that we should exit after the debugged program is finished.
    #
    attr_accessor :quit

    #
    # Signals that we should stop before program starts
    #
    attr_accessor :stop

    #
    # @param stop [Boolean] Whether the runner should stop right before
    # starting the program.
    #
    # @param quit [Boolean] Whether the runner should quit right after
    # finishing the program.
    #
    def initialize(stop = true, quit = true)
      @stop = stop
      @quit = quit
    end

    def help=(text)
      @help ||= text

      interface.puts("\n#{text}\n")
    end

    def version=(number)
      @version ||= number

      interface.puts("\n  Running byebug #{number}\n")
    end

    def remote=(host_and_port)
      @remote ||= Byebug.parse_host_and_port(host_and_port)
    end

    #
    # Usage banner.
    #
    def banner
      <<-EOB.gsub(/^ {8}/, '')

          byebug #{Byebug::VERSION}

          Usage: byebug [options] <script.rb> -- <script.rb parameters>

      EOB
    end

    #
    # Starts byebug to debug a program.
    #
    def run
      prepare_options.order!($ARGV)
      return if version || help

      if remote
        Byebug.start_client(*remote)
        return
      end

      setup_cmd_line_args

      loop do
        debug_program

        break if quit

        ControlProcessor.new.process_commands
      end
    end

    attr_writer :interface

    def interface
      @interface ||= LocalInterface.new
    end

    #
    # Processes options passed from the command line.
    #
    def prepare_options
      OptionParser.new(banner, 25) do |opts|
        opts.banner = banner

        OptionSetter.new(self, opts).setup
      end
    end

    #
    # Extracts debugged program from command line args.
    #
    def setup_cmd_line_args
      Byebug.mode = :standalone

      fail(NoScript, 'You must specify a program to debug...') if $ARGV.empty?

      program = which($ARGV.shift)
      program = which($ARGV.shift) if program == which('ruby')
      fail(NonExistentScript, "The script doesn't exist") unless program

      $PROGRAM_NAME = program
    end

    #
    # Debugs a script only if syntax checks okay.
    #
    def debug_program
      ok = syntax_valid?(File.read($PROGRAM_NAME))
      fail(InvalidScript, 'The script has incorrect syntax') unless ok

      error = Byebug.debug_load($PROGRAM_NAME, stop)
      puts "#{error}\n#{error.backtrace}" if error
    end

    #
    # Cross-platform way of finding an executable in the $PATH.
    # Borrowed from: http://stackoverflow.com/questions/2108727
    #
    def which(cmd)
      return File.expand_path(cmd) if File.exist?(cmd)

      exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each do |ext|
          exe = File.join(path, "#{cmd}#{ext}")
          return exe if File.executable?(exe) && !File.directory?(exe)
        end
      end

      nil
    end
  end
end

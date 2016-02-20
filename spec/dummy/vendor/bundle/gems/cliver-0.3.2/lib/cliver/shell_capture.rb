require 'open3'

module Cliver
  class ShellCapture
    attr_reader :stdout, :stderr, :command_found

    # @overlaod initialize(command)
    #   @param command [String] the command to run
    # @overload initialize(command)
    #   @param command [Array<String>] the command to run; elements in
    #     the supplied array will be shelljoined.
    # @return [void]
    def initialize(command)
      command = command.shelljoin if command.kind_of?(Array)
      @stdout = @stderr = ''
      begin
        Open3.popen3(command) do |i, o, e|
          @stdout = o.read.chomp
          @stderr = e.read.chomp
        end
        # Fix for ruby 1.8.7 (and probably earlier):
        # Open3.popen3 does not raise anything there, but the error goes to STDERR.
        if @stderr =~ /open3.rb:\d+:in `exec': No such file or directory -.*\(Errno::ENOENT\)/ or
           @stderr =~ /An exception occurred in a forked block\W+No such file or directory.*\(Errno::ENOENT\)/
          @stderr = ''
          @command_found = false
        else
          @command_found = true
        end
      rescue Errno::ENOENT, IOError
        @command_found = false
      end
    end
  end
end

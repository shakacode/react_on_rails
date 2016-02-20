require 'byebug/command'

module Byebug
  #
  # Execute a file containing byebug commands.
  #
  # It can be used to restore a previously saved debugging session.
  #
  class SourceCommand < Command
    self.allow_in_control = true
    self.allow_in_post_mortem = true

    def self.regexp
      /^\s* so(?:urce)? (?:\s+(\S+))? \s*$/x
    end

    def self.description
      <<-EOD
        source <file>

        #{short_description}
      EOD
    end

    def self.short_description
      'Restores a previously saved byebug session'
    end

    def execute
      return puts(help) unless @match[1]

      file = File.expand_path(@match[1]).strip
      unless File.exist?(file)
        return errmsg(pr('source.errors.not_found', file: file))
      end

      processor.interface.read_file(file)
    end
  end
end

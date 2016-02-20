require 'byebug/command'
require 'byebug/helpers/eval'

module Byebug
  #
  # Enter Pry from byebug's prompt
  #
  class PryCommand < Command
    self.allow_in_post_mortem = true

    def self.regexp
      /^\s* pry \s*$/x
    end

    def self.description
      <<-EOD
        pry

        #{short_description}
      EOD
    end

    def self.short_description
      'Starts a Pry session'
    end

    def execute
      unless processor.interface.is_a?(LocalInterface)
        return errmsg(pr('base.errors.only_local'))
      end

      begin
        require 'pry'
      rescue LoadError
        errmsg(pr('pry.errors.not_installed'))
      end

      context.binding.pry
    end
  end
end

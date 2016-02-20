require 'byebug/command'
require 'irb'

module Byebug
  #
  # Enter IRB from byebug's prompt
  #
  class IrbCommand < Command
    self.allow_in_post_mortem = true

    def self.regexp
      /^\s* irb \s*$/x
    end

    def self.description
      <<-EOD
        irb

        #{short_description}
      EOD
    end

    def self.short_description
      'Starts an IRB session'
    end

    def execute
      unless processor.interface.is_a?(LocalInterface)
        return errmsg(pr('base.errors.only_local'))
      end

      IRB.start(__FILE__)
    end
  end
end

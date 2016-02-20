require 'byebug/setting'
require 'byebug/commands/pry'

module Byebug
  #
  # Setting for automatically invoking Pry on every stop.
  #
  class AutoprySetting < Setting
    DEFAULT = 0

    def initialize
      PryCommand.always_run = DEFAULT
    end

    def banner
      'Invoke Pry on every stop'
    end

    def value=(v)
      PryCommand.always_run = v ? 1 : 0
    end

    def value
      PryCommand.always_run == 1
    end
  end
end

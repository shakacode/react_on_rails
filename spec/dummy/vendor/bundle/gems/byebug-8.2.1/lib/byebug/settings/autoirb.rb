require 'byebug/setting'
require 'byebug/commands/irb'

module Byebug
  #
  # Setting for automatically invoking IRB on every stop.
  #
  class AutoirbSetting < Setting
    DEFAULT = 0

    def initialize
      IrbCommand.always_run = DEFAULT
    end

    def banner
      'Invoke IRB on every stop'
    end

    def value=(v)
      IrbCommand.always_run = v ? 1 : 0
    end

    def value
      IrbCommand.always_run == 1
    end
  end
end

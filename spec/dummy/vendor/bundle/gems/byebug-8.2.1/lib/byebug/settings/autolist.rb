require 'byebug/setting'
require 'byebug/commands/list'

module Byebug
  #
  # Setting for automatically listing source code on every stop.
  #
  class AutolistSetting < Setting
    DEFAULT = 1

    def initialize
      ListCommand.always_run = DEFAULT
    end

    def banner
      'Invoke list command on every stop'
    end

    def value=(v)
      ListCommand.always_run = v ? 1 : 0
    end

    def value
      ListCommand.always_run == 1
    end
  end
end

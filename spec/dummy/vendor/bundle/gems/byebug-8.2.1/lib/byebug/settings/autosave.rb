require 'byebug/setting'

module Byebug
  #
  # Setting for automatically saving previously entered commands to history
  # when exiting the debugger.
  #
  class AutosaveSetting < Setting
    DEFAULT = true

    def banner
      'Automatically save command history record on exit'
    end
  end
end

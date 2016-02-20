require 'byebug/setting'

module Byebug
  #
  # Setting to customize the maximum width of byebug's output.
  #
  class WidthSetting < Setting
    DEFAULT = 160

    def banner
      "Number of characters per line in byebug's output"
    end

    def to_s
      "Maximum width of byebug's output is #{value}"
    end
  end
end

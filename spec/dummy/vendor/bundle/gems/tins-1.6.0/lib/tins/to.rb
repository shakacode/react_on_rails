module Tins
  module To
    def to(string)
      shift_width = (string[/\A\s*/]).size
      string.gsub(/^[^\S\n]{0,#{shift_width}}/, '')
    end
  end
end

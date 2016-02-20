class CapybaraScreenshot
  module Helpers
    extend self

    COLORS =
      {
        "black"   => 0,
        "red"     => 1,
        "green"   => 2,
        "yellow"  => 3,
        "blue"    => 4,
        "purple"  => 5,
        "magenta" => 5,
        "cyan"    => 6,
        "white"   => 7
      }

      COLORS.each_pair do |color, value|
        define_method color do |text|
          "\033[0;#{30+value}m#{text}\033[0m"
        end

        define_method "bright_#{color}" do |text|
          "\033[1;#{30+value}m#{text}\033[0m"
        end
      end
  end
end

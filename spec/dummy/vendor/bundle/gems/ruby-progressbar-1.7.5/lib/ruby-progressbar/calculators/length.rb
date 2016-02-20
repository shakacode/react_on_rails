class   ProgressBar
module  Calculators
class   Length
  attr_reader   :length_override
  attr_accessor :current_length

  def initialize(options)
    self.length_override = options[:length]
    self.current_length  = nil
  end

  def length
    current_length || reset_length
  end

  def length_changed?
    previous_length     = current_length
    self.current_length = calculate_length

    previous_length != current_length
  end

  def calculate_length
    length_override || terminal_width || 80
  end

  def reset_length
    self.current_length = calculate_length
  end

  def length_override=(other)
    @length_override ||= ENV['RUBY_PROGRESS_BAR_LENGTH'] || other
    @length_override = @length_override.to_i if @length_override
  end

  private

  # This code was copied and modified from Rake, available under MIT-LICENSE
  # Copyright (c) 2003, 2004 Jim Weirich
  def terminal_width
    return 80 unless unix?

    result = dynamic_width
    (result < 20) ? 80 : result
  rescue
    80
  end

  begin
    require 'io/console'

    def dynamic_width
      _rows, columns = IO.console.winsize
      columns
    end
  rescue LoadError
    def dynamic_width
      dynamic_width_stty.nonzero? || dynamic_width_tput
    end

    def dynamic_width_stty
      `stty size 2>/dev/null`.split[1].to_i
    end

    def dynamic_width_tput
      `tput cols 2>/dev/null`.to_i
    end
  end

  def unix?
    RUBY_PLATFORM =~ /(aix|darwin|linux|(net|free|open)bsd|cygwin|solaris|irix|hpux)/i
  end
end
end
end

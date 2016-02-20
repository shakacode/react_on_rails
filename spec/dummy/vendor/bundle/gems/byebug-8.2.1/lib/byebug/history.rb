begin
  require 'readline'
rescue LoadError
  warn <<-EOW
    Sorry, you can't use byebug without Readline. To solve this, you need to
    rebuild Ruby with Readline support. If using Ubuntu, try `sudo apt-get
    install libreadline-dev` and then reinstall your Ruby.
  EOW

  raise
end

module Byebug
  #
  # Handles byebug's history of commands.
  #
  class History
    attr_accessor :size

    def initialize
      self.size = 0
    end

    #
    # Restores history from disk.
    #
    def restore
      return unless File.exist?(Setting[:histfile])

      File.readlines(Setting[:histfile]).reverse_each { |l| push(l.chomp) }
    end

    #
    # Saves history to disk.
    #
    def save
      n_cmds = Setting[:histsize] > size ? size : Setting[:histsize]

      open(Setting[:histfile], 'w') do |file|
        n_cmds.times { file.puts(pop) }
      end

      clear
    end

    #
    # Discards history.
    #
    def clear
      size.times { pop }
    end

    #
    # Adds a new command to Readline's history.
    #
    def push(cmd)
      return if ignore?(cmd)

      self.size += 1
      Readline::HISTORY.push(cmd)
    end

    #
    # Removes a command from Readline's history.
    #
    def pop
      self.size -= 1
      Readline::HISTORY.pop
    end

    #
    # Prints the requested numbers of history entries.
    #
    def to_s(n_cmds)
      show_size = n_cmds ? specific_max_size(n_cmds) : default_max_size

      commands = Readline::HISTORY.to_a.last(show_size)

      last_ids(show_size).zip(commands).map do |l|
        format('%5d  %s', l[0], l[1])
      end.join("\n") + "\n"
    end

    #
    # Array of ids of the last n commands.
    #
    def last_ids(n)
      (1 + size - n..size).to_a
    end

    #
    # Max number of commands to be displayed when no size has been specified.
    #
    # Never more than Setting[:histsize].
    #
    def default_max_size
      [Setting[:histsize], self.size].min
    end

    #
    # Max number of commands to be displayed when a size has been specified.
    #
    # The only bound here is not showing more items than available.
    #
    def specific_max_size(number)
      [self.size, number].min
    end

    #
    # Whether a specific command should not be stored in history.
    #
    # For now, empty lines and consecutive duplicates.
    #
    def ignore?(buf)
      return true if /^\s*$/ =~ buf
      return false if Readline::HISTORY.length == 0

      Readline::HISTORY[Readline::HISTORY.length - 1] == buf
    end
  end
end

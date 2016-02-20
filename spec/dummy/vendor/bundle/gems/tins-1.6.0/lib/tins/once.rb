module Tins
  module Once
    include File::Constants

    module_function

    def only_once(lock_filename = nil, locking_constant = nil)
      lock_filename ||= $0
      locking_constant ||= LOCK_EX
      f = File.new(lock_filename, RDONLY)
      f.flock(locking_constant) and yield
    ensure
      if f
        f.flock LOCK_UN
        f.close
      end
    end

    def try_only_once(lock_filename = nil, locking_constant = nil, &block)
      only_once(lock_filename, locking_constant || LOCK_EX | LOCK_NB, &block)
    end
  end
end

require 'tins/alias'

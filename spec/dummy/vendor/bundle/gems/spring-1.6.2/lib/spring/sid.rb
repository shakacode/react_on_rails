begin
  # If rubygems is present, keep it out of the way when loading fiddle,
  # otherwise if fiddle is not installed then rubygems will load all
  # gemspecs in its (futile) search for fiddle, which is slow.
  if respond_to?(:gem_original_require, true)
    gem_original_require 'fiddle'
  else
    require 'fiddle'
  end
rescue LoadError
end

module Spring
  module SID
    def self.fiddle_func
      @fiddle_func ||= Fiddle::Function.new(
        DL::Handle::DEFAULT['getsid'],
        [Fiddle::TYPE_INT],
        Fiddle::TYPE_INT
      )
    end

    def self.sid
      @sid ||= begin
        if Process.respond_to?(:getsid)
          # Ruby 2
          Process.getsid
        elsif defined?(Fiddle) and defined?(DL)
          # Ruby 1.9.3 compiled with libffi support
          fiddle_func.call(0)
        else
          # last resort: shell out
          `ps -p #{Process.pid} -o sess=`.to_i
        end
      end
    end

    def self.pgid
      Process.getpgid(sid)
    end
  end
end

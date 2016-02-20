# encoding: utf-8

class ExecutableMock
  def initialize(path)
    @path = _to_platform_abs_path(path)
  end
  attr_reader :path
  attr_reader :version

  def == (other_path)
    other_path = _to_platform_abs_path(other_path)
    if other_path[/[A-Z]:/i] # windows
      pattern = /\A#{self.path}(#{(ENV['PATHEXT']||'').split(';').map(&Regexp::method(:escape)).join('|')})?\Z/i
      pattern =~ other_path
    else # posix
      self.path == other_path
    end
  end

  private

  def _to_platform_abs_path(source)
    (File::absolute_path?(source, :windows) && !File::absolute_path?(source, :posix)) ?
      source.tr('\\','/') :
      File.expand_path(source)
  end

  class Registry
    def initialize(version_map)
      @registry = {}
      version_map.each do |path,version|
        @registry[ExecutableMock.new(path)] = version
      end
    end

    def executable?(path)
      false | version(path)
    end

    def version(path)
      key = @registry.keys.find {|exe| exe == path }
      key && @registry[key]
    end
  end
end

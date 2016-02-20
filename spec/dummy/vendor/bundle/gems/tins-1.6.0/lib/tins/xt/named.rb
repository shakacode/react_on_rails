require 'tins/xt/string_version'

class Object
  def named(name, method, *args, &named_block)
    extend Module.new {
      define_method(name) do |*rest, &block|
        block = named_block if named_block
        __send__(method, *(args + rest), &block)
      end
    }
  end
end

class Module
  def named(name, method, *args, &named_block)
    include Module.new {
      define_method(name) do |*rest, &block|
        block = named_block if named_block
        __send__(method, *(args + rest), &block)
      end
    }
  end
end

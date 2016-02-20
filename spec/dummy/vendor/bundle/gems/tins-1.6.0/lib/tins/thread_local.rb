module Tins
  module ThreadLocal
    @@mutex = Mutex.new

    @@cleanup = lambda do |my_object_id|
      my_id = "__thread_local_#{my_object_id}__"
      @@mutex.synchronize do
        for t in Thread.list
          t[my_id] = nil if t[my_id]
        end
      end
    end

    # Define a thread local variable named _name_ in this module/class. If the
    # value _value_ is given, it is used to initialize the variable.
    def thread_local(name, default_value = nil)
      is_a?(Module) or raise TypeError, "receiver has to be a Module"

      name = name.to_s
      my_id = "__thread_local_#{__id__}__"

      ObjectSpace.define_finalizer(self, @@cleanup)

      define_method(name) do
        Thread.current[my_id] ||= {}
        Thread.current[my_id][name]
      end

      define_method("#{name}=") do |value|
        Thread.current[my_id] ||= {}
        Thread.current[my_id][name] = value
      end

      if default_value
        Thread.current[my_id] = {}
        Thread.current[my_id][name] = default_value
      end
      self
    end

    # Define a thread local variable for the current instance with name _name_.
    # If the value _value_ is given, it is used to initialize the variable.
    def instance_thread_local(name, value = nil)
      class << self
        extend Tins::ThreadLocal
        self
      end.thread_local name, value
      self
    end
  end
end

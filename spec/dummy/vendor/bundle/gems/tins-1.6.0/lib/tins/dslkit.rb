require 'tins'
require 'thread'
require 'sync'

require 'tins/thread_local'

module Tins
  # This module contains some handy methods to deal with eigenclasses. Those
  # are also known as virtual classes, singleton classes, metaclasses, plus all
  # the other names Matz doesn't like enough to actually accept one of the
  # names.
  #
  # The module can be included into other modules/classes to make the methods available.
  module Eigenclass
    # Returns the eigenclass of this object.
    def eigenclass
    end
    alias eigenclass singleton_class

    # Evaluates the _block_ in context of the eigenclass of this object.
    def eigenclass_eval(&block)
      eigenclass.instance_eval(&block)
    end
  end

  module ClassMethod
    include Eigenclass

    # Define a class method named _name_ using _block_.
    def class_define_method(name, &block)
      eigenclass_eval { define_method(name, &block) }
    end

    # Define reader and writer attribute methods for all <i>*ids</i>.
    def class_attr_accessor(*ids)
      eigenclass_eval { attr_accessor(*ids) }
    end

    # Define reader attribute methods for all <i>*ids</i>.
    def class_attr_reader(*ids)
      eigenclass_eval { attr_reader(*ids) }
    end

    # Define writer attribute methods for all <i>*ids</i>.
    def class_attr_writer(*ids)
      eigenclass_eval { attr_writer(*ids) }
    end

    # I boycott attr!
  end

  module ThreadGlobal
    # Define a thread global variable named _name_ in this module/class. If the
    # value _value_ is given, it is used to initialize the variable.
    def thread_global(name, default_value = nil)
      is_a?(Module) or raise TypeError, "receiver has to be a Module"

      name = name.to_s
      var_name = "@__#{name}_#{__id__.abs}__"

      lock = Mutex.new
      modul = self

      define_method(name) do
        lock.synchronize { modul.instance_variable_get var_name }
      end

      define_method(name + "=") do |value|
        lock.synchronize { modul.instance_variable_set var_name, value }
      end

      modul.instance_variable_set var_name, default_value if default_value
      self
    end

    # Define a thread global variable for the current instance with name
    # _name_. If the value _value_ is given, it is used to initialize the
    # variable.
    def instance_thread_global(name, value = nil)
      sc = class << self
        extend Tins::ThreadGlobal
        self
      end
      sc.thread_global name, value
      self
    end
  end

  module InstanceExec
    def self.included(*)
      super
      warn "#{self} is deprecated, but included at #{caller.first[/(.*):/, 1]}"
    end
  end

  module Interpreter
    # Interpret the string _source_ as a body of a block, while passing
    # <i>*args</i> into the block.
    #
    # A small example explains how the method is supposed to be used and how
    # the <i>*args</i> can be fetched:
    #
    #  class A
    #    include Tins::Interpreter
    #    def c
    #      3
    #    end
    #  end
    #
    #  A.new.interpret('|a,b| a + b + c', 1, 2) # => 6
    #
    # To use a specified binding see #interpret_with_binding.
    def interpret(source, *args)
      interpret_with_binding(source, binding, *args)
    end

    # Interpret the string _source_ as a body of a block, while passing
    # <i>*args</i> into the block and using _my_binding_ for evaluation.
    #
    # A small example:
    #
    #  class A
    #    include Tins::Interpreter
    #    def c
    #      3
    #    end
    #    def foo
    #      b = 2
    #      interpret_with_binding('|a| a + b + c', binding, 1) # => 6
    #    end
    #  end
    #  A.new.foo # => 6
    #
    # See also #interpret.
    def interpret_with_binding(source, my_binding, *args)
      path = '(interpret)'
      if source.respond_to? :to_io
        path = source.path if source.respond_to? :path
        source = source.to_io.read
      end
      block = lambda { |*a| eval("lambda { #{source} }", my_binding, path).call(*a) }
      instance_exec(*args, &block)
    end
  end

  # This module contains the _constant_ method. For small example of its usage
  # see the documentation of the DSLAccessor module.
  module Constant
    # Create a constant named _name_, that refers to value _value_. _value is
    # frozen, if this is possible. If you want to modify/exchange a value use
    # DSLAccessor#dsl_reader/DSLAccessor#dsl_accessor instead.
    def constant(name, value = name)
      value = value.freeze rescue value
      define_method(name) { value }
    end
  end

  # The DSLAccessor module contains some methods, that can be used to make
  # simple accessors for a DSL.
  #
  #
  #  class CoffeeMaker
  #    extend Tins::Constant
  #
  #    constant :on
  #    constant :off
  #
  #    extend Tins::DSLAccessor
  #
  #    dsl_accessor(:state) { off } # Note: the off constant from above is used
  #
  #    dsl_accessor :allowed_states, :on, :off
  #
  #    def process
  #      allowed_states.include?(state) or fail "Explode!!!"
  #      if state == on
  #        puts "Make coffee."
  #      else
  #        puts "Idle..."
  #      end
  #    end
  #  end
  #
  #  cm = CoffeeMaker.new
  #  cm.instance_eval do
  #    state      # => :off
  #    state on
  #    state      # => :on
  #    process    # => outputs "Make coffee."
  #  end
  #
  # Note that Tins::SymbolMaker is an alternative for Tins::Constant in
  # this example. On the other hand SymbolMaker can make debugging more
  # difficult.
  module DSLAccessor
    # This method creates a dsl accessor named _name_. If nothing else is given
    # as argument it defaults to nil. If <i>*default</i> is given as a single
    # value it is used as a default value, if more than one value is given the
    # _default_ array is used as the default value. If no default value but a
    # block _block_ is given as an argument, the block is executed everytime
    # the accessor is read <b>in the context of the current instance</b>.
    #
    # After setting up the accessor, the set or default value can be retrieved
    # by calling the method +name+. To set a value one can call <code>name
    # :foo</code> to set the attribute value to <code>:foo</code> or
    # <code>name(:foo, :bar)</code> to set it to <code>[ :foo, :bar ]</code>.
    def dsl_accessor(name, *default, &block)
      variable = "@#{name}"
      define_method(name) do |*args|
        if args.empty?
          result = instance_variable_get(variable)
          if result.nil?
            result = if default.empty?
              block && instance_eval(&block)
            elsif default.size == 1
              default.first
            else
              default
            end
            instance_variable_set(variable, result)
            result
          else
            result
          end
        else
          instance_variable_set(variable, args.size == 1 ? args.first : args)
        end
      end
    end

    # This method creates a dsl reader accessor, that behaves exactly like a
    # #dsl_accessor but can only be read not set.
    def dsl_reader(name, *default, &block)
      variable = "@#{name}"
      define_method(name) do |*args|
        if args.empty?
          result = instance_variable_get(variable)
          if result.nil?
            if default.empty?
              block && instance_eval(&block)
            elsif default.size == 1
              default.first
            else
              default
            end
          else
            result
          end
        else
          raise ArgumentError, "wrong number of arguments (#{args.size} for 0)"
        end
      end
    end
  end

  # This module can be included in another module/class. It generates a symbol
  # for every missing method that was called in the context of this
  # module/class.
  module SymbolMaker
    # Returns a symbol (_id_) for every missing method named _id_.
    def method_missing(id, *args)
      if args.empty?
        id
      else
        super
      end
    end
  end

  # This module can be used to extend another module/class. It generates
  # symbols for every missing constant under the namespace of this
  # module/class.
  module ConstantMaker
    # Returns a symbol (_id_) for every missing constant named _id_.
    def const_missing(id)
      id
    end
  end

  module BlankSlate
    # Creates an anonymous blank slate class, that only responds to the methods
    # <i>*ids</i>. ids can be Symbols, Strings, and Regexps that have to match
    # the method name with #===.
    def self.with(*ids)
      opts = Hash === ids.last ? ids.pop : {}
      ids = ids.map { |id| Regexp === id ? id : id.to_s }
      klass = opts[:superclass] ? Class.new(opts[:superclass]) : Class.new
      klass.instance_eval do
        instance_methods.each do |m|
          m = m.to_s
          undef_method m unless m =~ /^(__|object_id)/ or ids.any? { |i| i === m }
        end
      end
      klass
    end
  end

  # See examples/recipe.rb and examples/recipe2.rb how this works at the
  # moment.
  module Deflect
    # The basic Deflect exception
    class DeflectError < StandardError; end

    class << self
      extend Tins::ThreadLocal

      # A thread local variable, that holds a DeflectorCollection instance for
      # the current thread.
      thread_local :deflecting
    end

    # A deflector is called with a _class_, a method _id_, and its
    # <i>*args</i>.
    class Deflector < Proc; end

    # This class implements a collection of deflectors, to make them available
    # by emulating Ruby's message dispatch.
    class DeflectorCollection
      def initialize
        @classes = {}
      end

      # Add a new deflector _deflector_ for class _klass_ and method name _id_,
      # and return self.
      #
      def add(klass, id, deflector)
        k = @classes[klass]
        k = @classes[klass] = {} unless k
        k[id.to_s] = deflector
        self
      end

      # Return true if messages are deflected for class _klass_ and method name
      # _id_, otherwise return false.
      def member?(klass, id)
        !!(k = @classes[klass] and k.key?(id.to_s))
      end

      # Delete the deflecotor class _klass_ and method name _id_. Returns the
      # deflector if any was found, otherwise returns true.
      def delete(klass, id)
        if k = @classes[klass]
          d = k.delete id.to_s
          @classes.delete klass if k.empty?
          d
        end
      end

      # Try to find a deflector for class _klass_ and method _id_ and return
      # it. If none was found, return nil instead.
      def find(klass, id)
        klass.ancestors.find do |k|
          if d = @classes[k] and d = d[id.to_s]
            return d
          end
        end
      end
    end

    @@sync = Sync.new

    # Start deflecting method calls named _id_ to the _from_ class using the
    # Deflector instance deflector.
    def deflect_start(from, id, deflector)
      @@sync.synchronize do
        Deflect.deflecting ||= DeflectorCollection.new
        Deflect.deflecting.member?(from, id) and
          raise DeflectError, "#{from}##{id} is already deflected"
        Deflect.deflecting.add(from, id, deflector)
        from.class_eval do
          define_method(id) do |*args|
            if Deflect.deflecting and d = Deflect.deflecting.find(self.class, id)
              d.call(self, id, *args)
            else
              super(*args)
            end
          end
        end
      end
    end

    # Return true if method _id_ is deflected from class _from_, otherwise
    # return false.
    def self.deflect?(from, id)
      Deflect.deflecting && Deflect.deflecting.member?(from, id)
    end

    # Return true if method _id_ is deflected from class _from_, otherwise
    # return false.
    def deflect?(from, id)
      Deflect.deflect?(from, id)
    end

    # Start deflecting method calls named _id_ to the _from_ class using the
    # Deflector instance deflector. After that yield to the given block and
    # stop deflecting again.
    def deflect(from, id, deflector)
      @@sync.synchronize do
        begin
          deflect_start(from, id, deflector)
          yield
        ensure
          deflect_stop(from, id)
        end
      end
    end

    # Stop deflection method calls named _id_ to class _from_.
    def deflect_stop(from, id)
      @@sync.synchronize do
        Deflect.deflecting.delete(from, id) or
          raise DeflectError, "#{from}##{id} is not deflected from"
        from.instance_eval { remove_method id }
      end
    end
  end

  # This module can be included into modules/classes to make the delegate
  # method available.
  module Delegate
    UNSET = Object.new

    # A method to easily delegate methods to an object, stored in an
    # instance variable or returned by a method call.
    #
    # It's used like this:
    #   class A
    #     delegate :method_here, :@obj, :method_there
    #   end
    # or:
    #   class A
    #     delegate :method_here, :method_call, :method_there
    #   end
    #
    # _other_method_name_ defaults to method_name, if it wasn't given.
    #def delegate(method_name, to: UNSET, as: method_name)
    def delegate(method_name, opts = {})
      to = opts[:to] || UNSET
      as = opts[:as] || method_name
      raise ArgumentError, "to argument wasn't defined" if to == UNSET
      to = to.to_s
      case
      when to[0, 2] == '@@'
        define_method(as) do |*args, &block|
          self.class.class_variable_get(to).__send__(method_name, *args, &block)
        end
      when to[0] == ?@
        define_method(as) do |*args, &block|
          instance_variable_get(to).__send__(method_name, *args, &block)
        end
      when (?A..?Z).include?(to[0])
        define_method(as) do |*args, &block|
          Tins::DeepConstGet.deep_const_get(to).__send__(method_name, *args, &block)
        end
      else
        define_method(as) do |*args, &block|
          __send__(to).__send__(method_name, *args, &block)
        end
      end
    end
  end

  # This module includes the block_self module_function.
  module BlockSelf
    module_function

    # This method returns the receiver _self_ of the context in which _block_
    # was created.
    def block_self(&block)
      eval 'self', block.__send__(:binding)
    end
  end

  # This module contains a configurable method missing delegator and can be
  # mixed into a module/class.
  module MethodMissingDelegator

    # Including this module in your classes makes an _initialize_ method
    # available, whose first argument is used as method_missing_delegator
    # attribute. If a superior _initialize_ method was defined it is called
    # with all arguments but the first.
    module DelegatorModule
      include Tins::MethodMissingDelegator

      def initialize(delegator, *a, &b)
        self.method_missing_delegator = delegator
        super(*a, &b) if defined? super
      end
    end

    # This class includes DelegatorModule and can be used as a superclass
    # instead of including DelegatorModule.
    class DelegatorClass
      include DelegatorModule
    end

    # This object will be the receiver of all missing method calls, if it has a
    # value other than nil.
    attr_accessor :method_missing_delegator

    # Delegates all missing method calls to _method_missing_delegator_ if this
    # attribute has been set. Otherwise it will call super.
    def method_missing(id, *a, &b)
      unless method_missing_delegator.nil?
        method_missing_delegator.__send__(id, *a, &b)
      else
        super
      end
    end
  end

  module ParameterizedModule
    # Pass _args_ and _block_ to configure the module and then return it after
    # calling the parameterize method has been called with these arguments. The
    # _parameterize_ method should return a configured module.
    def parameterize_for(*args, &block)
      respond_to?(:parameterize) ? parameterize(*args, &block) : self
    end
  end

  module FromModule
    include ParameterizedModule

    alias from parameterize_for

    def parameterize(opts = {})
      modul = opts[:module] or raise ArgumentError, 'option :module is required'
      import_methods = Array(opts[:methods])
      result = modul.dup
      remove_methods = modul.instance_methods.map(&:to_sym) - import_methods.map(&:to_sym)
      remove_methods.each do |m|
        begin
          result.__send__ :remove_method, m
        rescue NameError
        end
      end
      result
    end
  end

  module Scope
    def scope_push(scope_frame, name = :default)
      scope_get(name).push scope_frame
      self
    end

    def scope_pop(name = :default)
      scope_get(name).pop
      scope_get(name).empty? and Thread.current[name] = nil
      self
    end

    def scope_top(name = :default)
      scope_get(name).last
    end

    def scope_reverse(name = :default, &block)
      scope_get(name).reverse_each(&block)
    end

    def scope_block(scope_frame, name = :default)
      scope_push(scope_frame, name)
      yield
      self
    ensure
      scope_pop(name)
    end

    def scope_get(name = :default)
      Thread.current[name] ||= []
    end

    def scope(name = :default)
      scope_get(name).dup
    end
  end

  module DynamicScope
    class Context < Hash
      def [](name)
        super name.to_sym
      end

      def []=(name, value)
        super name.to_sym, value
      end
    end

    include Scope

    attr_accessor :dynamic_scope_name

    def dynamic_defined?(id)
      self.dynamic_scope_name ||= :variables
      scope_reverse(dynamic_scope_name) { |c| c.key?(id) and return true }
      false
    end

    def dynamic_scope(&block)
      self.dynamic_scope_name ||= :variables
      scope_block(Context.new, dynamic_scope_name, &block)
    end

    def method_missing(id, *args)
      self.dynamic_scope_name ||= :variables
      if args.empty? and scope_reverse(dynamic_scope_name) { |c| c.key?(id) and return c[id] }
        super
      elsif args.size == 1 and id.to_s =~ /(.*?)=\Z/
        c = scope_top(dynamic_scope_name) or super
        c[$1] = args.first
      else
        super
      end
    end
  end
end
DSLKit = Tins

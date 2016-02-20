module RubyLint
  module Definition
    ##
    # The RubyObject class is the base definition class of ruby-lint. These so
    # called definition classes are used for storing information about Ruby
    # classes and instances. At their most basic form they are a mix between
    # {RubyLint::Node} and a lookup table.
    #
    # ruby-lint currently provides the following two definition classes:
    #
    # * {RubyLint::Definition::RubyObject}: the base definition class, used for
    #   most Ruby types and values.
    # * {RubyLint::Definition::RubyMethod} definition class that is used for
    #   methods exclusively.
    #
    # Using the RubyObject class one could create a definition for the String
    # class as following:
    #
    #     string  = RubyObject.new(:name => 'String', :type => :const)
    #     newline = RubyObject.new(
    #       :name  => 'NEWLINE',
    #       :type  => :const,
    #       :value => "\n"
    #     )
    #
    #     string.add(:const, newline.name, newline)
    #
    # For more information see the documentation of the corresponding methods.
    #
    # @!attribute [r] name
    #  @return [String] The name of the object.
    #
    # @!attribute [rw] value
    #  @return [Mixed] The value of the object.
    #
    # @!attribute [r] type
    #  @return [Symbol] The type of object, e.g. `:const`.
    #
    # @!attribute [r] definitions
    #  @return [Hash] Hash containing all child the definitions.
    #
    # @!attribute [rw] parents
    #  @return [Array] Array containing the parent definitions.
    #
    # @!attribute [rw] reference_amount
    #  @return [Numeric] The amount of times an object was referenced.
    #   Currently this is only used for variables.
    #
    # @!attribute [rw] instance_type
    #  @return [Symbol] Indicates if the object represents a class or an
    #   instance.
    #
    # @!attribute [r] update_parents
    #  @return [Array] A list of data types to also add to the parent
    #   definitions when adding an object to the current one.
    #
    # @!attribute [r] members_as_value
    #  @return [TrueClass|FalseClass] When set to `true` the {#value} getter
    #   returns a collection of the members instead of the manually defined
    #   value.
    #
    # @!attribute [r] line
    #  @return [Numeric] The line number of the definition.
    #
    # @!attribute [r] column
    #  @return [Numeric] The column number of the definition.
    #
    # @!attribute [r] file
    #  @return [String] The file path of the definition.
    #
    # @!attribute [r] inherit_self
    #  @return [TrueClass|FalseClass] When set to `false` child definitions
    #   created using `define_constant` do not inherit the current definition.
    #
    class RubyObject
      include VariablePredicates

      ##
      # Array containing items that should be looked up in the parent
      # definition if they're not found in the current one.
      #
      # @return [Array]
      #
      LOOKUP_PARENT = [
        :const,
        :cvar,
        :gvar,
        :instance_method,
        :ivar,
        :method
      ].freeze

      ##
      # String used to separate segments in a constant path.
      #
      # @return [String]
      #
      PATH_SEPARATOR = '::'.freeze

      ##
      # Array containing the valid data types that can be stored.
      #
      # @return [Array<Symbol>]
      #
      VALID_TYPES = [
        :arg,
        :blockarg,
        :const,
        :cvar,
        :gvar,
        :instance_method,
        :ivar,
        :kwoptarg,
        :lvar,
        :member,
        :method,
        :optarg,
        :restarg,
        :unknown
      ].freeze

      attr_reader :update_parents,
        :column,
        :definitions,
        :file,
        :inherit_self,
        :line,
        :members_as_value,
        :name,
        :type

      attr_accessor :instance_type, :parents, :reference_amount

      ##
      # Creates an object that represents an unknown value.
      #
      # @return [RubyLint::Definition::RubyObject]
      #
      def self.create_unknown
        return new(:type => :unknown, :name => 'unknown')
      end

      ##
      # @example
      #  string = RubyObject.new(:name => 'String', :type => :const)
      #
      # @param [Hash] options Hash containing additional options such as the
      #  parent definitions. For a list of available options see the
      #  corresponding getter/setter methods of this class.
      #
      # @yieldparam [RubyLint::Definition::RubyObject]
      #
      def initialize(options = {})
        @inherit_self = true

        options.each do |key, value|
          instance_variable_set("@#{key}", value)
        end

        @update_parents   ||= []
        @instance_type    ||= :class
        @parents          ||= []
        @reference_amount ||= 0

        @definitions = Hash.new { |hash, key| hash[key] = {} }
        @value       = nil if members_as_value

        after_initialize if respond_to?(:after_initialize)

        yield self if block_given?
      end

      ##
      # Returns the value of the definition. If `members_as_value` is set to
      # `true` the return value is a Hash containing the names and values of
      # each member.
      #
      # @return [Hash|RubyLint::Definition::RubyObject]
      #
      def value
        return members_as_value ? list(:member) : @value
      end

      ##
      # Sets the value of the definition.
      #
      # @param [Mixed] value
      #
      def value=(value)
        @value = value
      end

      ##
      # Adds the definition object to the current one.
      #
      # @see #add
      # @param [RubyLint::Definition::RubyObject] definition
      #
      def add_definition(definition)
        add(definition.type, definition.name, definition)
      end

      ##
      # Adds a new definition to the definitions list.
      #
      # @example
      #  string  = RubyObject.new(:name => 'String', :type => :const)
      #  newline = RubyObject.new(
      #    :name  => 'NEWLINE',
      #    :type  => :const,
      #    :value => "\n"
      #  )
      #
      #  string.add(newline.type, newline.name, newline)
      #
      # @param [#to_sym] type The type of definition to add.
      # @param [String] name The name of the definition.
      # @param [RubyLint::Definition::RubyObject] value
      #
      # @raise [TypeError] Raised when a value that is not a RubyObject
      #  instance (or a subclass of this class) is given.
      #
      # @raise [ArgumentError] Raised when the specified type was invalid.
      #
      def add(type, name, value)
        type = type.to_sym

        unless value.is_a?(RubyObject)
          raise TypeError, "Expected RubyObject but got #{value.class}"
        end

        unless VALID_TYPES.include?(type)
          raise ArgumentError, ":#{type} is not a valid type of data to add"
        end

        definitions[type][name] = value

        if update_parents.include?(type)
          update_parent_definitions(type, name, value)
        end
      end

      ##
      # Looks up a definition by the given type and name. If no data was found
      # this method will try to look it up in any parent definitions.
      #
      # If no definition was found `nil` will be returned.
      #
      # @example
      #  string  = RubyObject.new(:name => 'String', :type => :const)
      #  newline = RubyObject.new(
      #    :name  => 'NEWLINE',
      #    :type  => :const,
      #    :value => "\n"
      #  )
      #
      #  string.add(newline.type, newline.name, newline)
      #
      #  string.lookup(:const, 'NEWLINE') # => #<RubyLint::Definition...>
      #
      # @param [#to_sym] type
      # @param [String] name
      #
      # @param [TrueClass|FalseClass] lookup_parent Whether definitions should
      #  be looked up from parent definitions.
      #
      # @param [Array] exclude A list of definitions to skip when looking up
      #  parents. This list is used to prevent stack errors when dealing with
      #  recursive definitions. A good example of this is `Logger` and
      #  `Logger::Severity` which both inherit from each other.
      #
      # @return [RubyLint::Definition::RubyObject|NilClass]
      #
      def lookup(type, name, lookup_parent = true, exclude = [])
        type, name = prepare_lookup(type, name)
        found      = nil

        if defines?(type, name)
          found = definitions[type][name]

        # Look up the definition in the parent scope(s) (if any are set). This
        # takes the parents themselves also into account.
        elsif lookup_parent?(type) and lookup_parent
          parents.each do |parent|
            # If we've already processed the parent we'll skip it.
            next if exclude.include?(parent)

            parent_definition = determine_parent(parent, type, name, exclude)

            if parent_definition
              found = parent_definition
              break
            end
          end
        end

        return found
      end

      ##
      # Returns the definition for the given constant path.
      #
      # @example
      #  example.lookup_constant_path('A::B') # => #<RubyLint::Definition...>
      #
      # @param [String|Array<String>] path
      # @return [RubyLint::Definition::RubyObject]
      #
      def lookup_constant_path(path)
        constant = self
        path     = path.split(PATH_SEPARATOR) if path.is_a?(String)

        path.each do |segment|
          found = constant.lookup(:const, segment)

          found ? constant = found : return
        end

        return constant
      end

      ##
      # Mimics a method call by executing the method for the given name. This
      # method should be defined in the current definition.
      #
      # @param [String] name The name of the method.
      # @return [Mixed]
      #
      def call_method(name)
        method = lookup(method_call_type, name)

        unless method
          raise NoMethodError, "Undefined method #{name} for #{self.inspect}"
        end

        return method.call(self)
      end

      ##
      # Returns `true` if a method is defined, similar to `respond_to?`.
      #
      # @return [TrueClass|FalseClass]
      #
      def method_defined?(name)
        return has_definition?(method_call_type, name)
      end

      ##
      # Performs a method call on the current definition.
      #
      # If the return value of a method definition is set to a Proc (or any
      # other object that responds to `:call`) it will be called and passed the
      # current instance as an argument.
      #
      # TODO: add support for specifying method arguments.
      #
      # @param [RubyLint::Definition::RubyObject] context The context in which
      #  the method was called.
      # @return [Mixed]
      #
      def call(context = self)
        retval = respond_to?(:return_value) ? return_value : nil
        retval = retval.call(context) if retval.is_a?(Proc)

        return retval
      end

      ##
      # Returns `true` if the current definition list or one of the parents has
      # the specified definition.
      #
      # @example
      #  string.has_definition?(:instance_method, 'downcase') # => true
      #
      # @param [#to_sym] type
      # @param [String] name
      # @param [Array] exclude Parent definitions to exclude.
      # @return [TrueClass|FalseClass]
      #
      def has_definition?(type, name, exclude = [])
        type, name = prepare_lookup(type, name)

        if definitions.key?(type) and definitions[type].key?(name)
          return true

        elsif lookup_parent?(type)
          parents.each do |parent|
            next if exclude.include?(parent)

            return true if parent.has_definition?(type, name, exclude | [self])
          end
        end

        return false
      end

      ##
      # Determines the call types for methods called on the current definition.
      #
      # @return [Symbol]
      #
      def method_call_type
        return class? ? :method : :instance_method
      end

      ##
      # @return [TrueClass|FalseClass]
      #
      def class?
        return instance_type == :class
      end

      ##
      # @return [TrueClass|FalseClass]
      #
      def instance?
        return instance_type == :instance
      end

      ##
      # Checks if the specified definition is defined in the current object,
      # ignoring data in any parent definitions.
      #
      # @see RubyLint::Definition::RubyObject#has_definition?
      # @return [TrueClass|FalseClass]
      #
      def defines?(type, name)
        type, name = prepare_lookup(type, name)

        return definitions.key?(type) && definitions[type].key?(name)
      end

      ##
      # Returns a list of all the definitions for the specific type.  This list
      # excludes anything defined in parent definitions.
      #
      # @example
      #  string.list(:instance_method) # => [..., ..., ...]
      #
      # @param [#to_sym] type
      # @return [Array]
      #
      def list(type)
        type = type.to_sym

        return definitions.key?(type) ? definitions[type].values : []
      end

      ##
      # Returns the amount of definitions stored for a given type.
      #
      # @param [#to_sym] type
      # @return [Numeric]
      #
      def amount(type)
        return list(type).length
      end

      ##
      # Merges the definitions object `other` into the current one.
      #
      # @param [RubyLint::Definition::RubyObject] other
      #
      def merge(other)
        other.definitions.each do |type, values|
          values.each do |name, definition|
            definitions[type][name] = definition
          end
        end
      end

      ##
      # Copies all the definitions in `source` of type `type` into the current
      # definitions object.
      #
      # @param [RubyLint::Definition::RubyObject] source
      # @param [Symbol] source_type The type of definitions to copy from the
      #  source.
      # @param [Symbol] target_type The type to store the definitions under,
      #  set to the `source_type` value by default.
      #
      def copy(source, source_type, target_type = source_type)
        return unless source.definitions.key?(source_type)

        source.list(source_type).each do |definition|
          unless defines?(target_type, definition.name)
            add(target_type, definition.name, definition)
          end
        end
      end

      ##
      # Creates a new definition object based on the current one that
      # represents an instance of a Ruby value (instead of a class).
      #
      # @param [Hash] options Attributes to override in the new definition.
      # @return [RubyLint::Definition::RubyObject]
      #
      def instance(options = {})
        return shim(:instance_type => :instance)
      end

      ##
      # Creates a new definition that inherits from the current one, acting as
      # sort of a shim around the original one.
      #
      # @param [Hash] options Attributes to set in the new definition.
      # @return [RubyLint::Definition::RubyObject]
      #
      def shim(options = {})
        options = {
          :name          => name,
          :type          => type,
          :instance_type => instance_type,
          :value         => value,
          :parents       => [self]
        }.merge(options)

        return self.class.new(options)
      end

      ##
      # Changes the instance type of the current definition to `:instance`. If
      # you want to return a new definition use {#instance} instead.
      #
      def instance!
        @instance_type = :instance
      end

      ##
      # Returns `true` if the object was referenced more than once.
      #
      # @return [TrueClass|FalseClass]
      #
      def used?
        return reference_amount > 0
      end

      ##
      # Defines a new child constant.
      #
      # @example
      #  string.define_constant('NEWLINE')
      #
      # @param [String] name
      # @return [RubyLint::Definition::RubyObject]
      #
      def define_constant(name, &block)
        if name.include?(PATH_SEPARATOR)
          path       = name.split(PATH_SEPARATOR)
          target     = lookup_constant_path(path[0..-2])
          definition = target.define_constant(path[-1], &block)
        else
          definition = add_child_definition(:const, name, &block)
        end

        definition.define_self

        return definition
      end

      ##
      # Defines a new global variable in the current definition.
      #
      # @example
      #  string.define_global_variable('$name', '...')
      #
      # @param [String] name
      # @param [Mixed] value
      #
      def define_global_variable(name, value = self.class.create_unknown)
        return add_child_definition(:gvar, name, value)
      end

      ##
      # Defines a new class method.
      #
      # @example
      #  string.define_method(:new)
      #
      # @param [String] name
      # @return [RubyLint::Definition::RubyMethod]
      #
      def define_method(name, &block)
        return add_child_method(:method, name, &block)
      end

      ##
      # Defines a new instance method.
      #
      # @example
      #  string.define_instance_method(:gsub)
      #
      # @see RubyLint::Definition::RubyObject#define_method
      #
      def define_instance_method(name, &block)
        return add_child_method(:instance_method, name, &block)
      end

      ##
      # Helper method that makes it easier to provide the two constructor
      # methods `new` and `initialize`. The supplied block is yielded on both
      # method definitions.
      #
      # @example
      #  some_object.define_constructors do |method|
      #    method.argument('name')
      #  end
      #
      def define_constructors(&block)
        define_method('new', &block)
        define_instance_method('initialize', &block)
      end

      ##
      # Adds the object(s) to the list of parent definitions.
      #
      # @param [Array] definitions
      #
      def inherits(*definitions)
        self.parents.concat(definitions)
      end

      ##
      # @see {RubyLint::Definition::ConstantProxy#initialize}
      # @return [RubyLint::Definition::ConstantProxy]
      #
      def constant_proxy(name, registry = nil)
        return ConstantProxy.new(self, name, registry)
      end

      ##
      # Defines `self` on the current definition as both a class and instance
      # method.
      #
      def define_self
        if instance?
          self_instance = self
          self_class    = instance(:instance_type => :class)
        else
          self_instance = self.instance
          self_class    = self
        end

        define_method('self') do |method|
          method.returns(self_class)
        end

        define_instance_method('self') do |method|
          method.returns(self_instance)
        end
      end

      ##
      # Returns a pretty formatted String that shows some info about the
      # current definition.
      #
      # @return [String]
      #
      def inspect
        attributes = [
          %Q(@name="#{name}"),
          %Q(@type="#{type}"),
          %Q(@instance_type="#{instance_type}")
        ]

        # See <http://stackoverflow.com/a/2818916> for more info.
        address = (object_id << 1).to_s(16)

        return %Q(#<#{self.class}:0x#{address} #{attributes.join(' ')}>)
      end

      private

      ##
      # Updates each parent definition if it has an existing definition for hte
      # given type and name.
      #
      # @see #add
      #
      def update_parent_definitions(type, name, value)
        parents.each do |parent|
          parent.add(type, name, value) if parent.has_definition?(type, name)
        end
      end

      ##
      # Determines what parent definition to use.
      #
      # @param [RubyLint::Definition::RubyObject] parent
      # @param [Symbol] type
      # @param [String] name
      # @param [Array] exclude
      # @return [RubyLint::Definition::RubyObject]
      #
      def determine_parent(parent, type, name, exclude = [])
        if parent.type == type and parent.name == name
          parent_definition = parent
        else
          exclude = exclude + [self] unless exclude.include?(self)

          parent_definition = parent.lookup(type, name, true, exclude)
        end

        return parent_definition
      end

      ##
      # Adds a new child definition to the current definition.
      #
      # @param [Symbol] type The definition type.
      # @param [String] name The name of the definition.
      # @param [Mixed] value
      # @return [RubyLint::Definition::RubyObject]
      #
      def add_child_definition(type, name, value = nil, &block)
        definition = self.class.new(
          :name    => name,
          :type    => type,
          :value   => value,
          :parents => inherit_self ? [self] : nil,
          &block
        )

        add(definition.type, definition.name, definition)

        return definition
      end

      ##
      # Adds a new child method to the current definition.
      #
      # @see RubyLint::Definition::RubyObject#add_child_definition
      #
      def add_child_method(type, name, &block)
        definition = RubyMethod.new(
          :name          => name,
          :type          => type,
          :parents       => [self],
          :instance_type => :instance,
          &block
        )

        add(definition.type, definition.name, definition)

        return definition
      end

      ##
      # Returns a boolean that indicates if the current definition type should
      # be looked up in a parent definition.
      #
      # @param  [Symbol] type The type of definition.
      # @return [Trueclass|FalseClass]
      #
      def lookup_parent?(type)
        return LOOKUP_PARENT.include?(type) && !parents.empty?
      end

      ##
      # Casts the type and name of data to look up to the correct values.
      #
      # @param [#to_sym] type
      # @param [#to_s] name
      # @return [Array]
      #
      def prepare_lookup(type, name)
        return type.to_sym, name.to_s
      end
    end # RubyObject
  end # Definition
end # RubyLint

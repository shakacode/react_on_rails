# Copyright (c) 2010-2013 Michael Dvorkin
#
# Awesome Print is freely distributable under the terms of MIT license.
# See LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
autoload :CGI, "cgi"
require "shellwords"

module AwesomePrint
  class Formatter

    CORE = [ :array, :bigdecimal, :class, :dir, :file, :hash, :method, :rational, :set, :struct, :unboundmethod ]
    DEFAULT_LIMIT_SIZE = 7

    def initialize(inspector)
      @inspector   = inspector
      @options     = inspector.options
      @indentation = @options[:indent].abs
    end

    # Main entry point to format an object.
    #------------------------------------------------------------------------------
    def format(object, type = nil)
      core_class = cast(object, type)
      awesome = if core_class != :self
        send(:"awesome_#{core_class}", object) # Core formatters.
      else
        awesome_self(object, type) # Catch all that falls back to object.inspect.
      end
      awesome
    end

    # Hook this when adding custom formatters. Check out lib/awesome_print/ext
    # directory for custom formatters that ship with awesome_print.
    #------------------------------------------------------------------------------
    def cast(object, type)
      CORE.grep(type)[0] || :self
    end

    # Pick the color and apply it to the given string as necessary.
    #------------------------------------------------------------------------------
    def colorize(str, type)
      str = CGI.escapeHTML(str) if @options[:html]
      if @options[:plain] || !@options[:color][type] || !@inspector.colorize?
        str
      #
      # Check if the string color method is defined by awesome_print and accepts
      # html parameter or it has been overriden by some gem such as colorize.
      #
      elsif str.method(@options[:color][type]).arity == -1 # Accepts html parameter.
        str.send(@options[:color][type], @options[:html])
      else
        str = %Q|<kbd style="color:#{@options[:color][type]}">#{str}</kbd>| if @options[:html]
        str.send(@options[:color][type])
      end
    end


    private

    # Catch all method to format an arbitrary object.
    #------------------------------------------------------------------------------
    def awesome_self(object, type)
      if @options[:raw] && object.instance_variables.any?
        awesome_object(object)
      elsif object.respond_to?(:to_hash)
        awesome_hash(object.to_hash)
      else
        colorize(object.inspect.to_s, type)
      end
    end

    # Format an array.
    #------------------------------------------------------------------------------
    def awesome_array(a)
      return "[]" if a == []

      if a.instance_variable_defined?('@__awesome_methods__')
        methods_array(a)
      elsif @options[:multiline]
        width = (a.size - 1).to_s.size 

        data = a.inject([]) do |arr, item|
          index = indent
          index << colorize("[#{arr.size.to_s.rjust(width)}] ", :array) if @options[:index]
          indented do
            arr << (index << @inspector.awesome(item))
          end
        end

        data = limited(data, width) if should_be_limited?
        "[\n" << data.join(",\n") << "\n#{outdent}]"
      else
        "[ " << a.map{ |item| @inspector.awesome(item) }.join(", ") << " ]"
      end
    end

    # Format a hash. If @options[:indent] if negative left align hash keys.
    #------------------------------------------------------------------------------
    def awesome_hash(h)
      return "{}" if h == {}

      keys = @options[:sort_keys] ? h.keys.sort { |a, b| a.to_s <=> b.to_s } : h.keys
      data = keys.map do |key|
        plain_single_line do
          [ @inspector.awesome(key), h[key] ]
        end
      end
      
      width = data.map { |key, | key.size }.max || 0
      width += @indentation if @options[:indent] > 0
  
      data = data.map do |key, value|
        indented do
          align(key, width) << colorize(" => ", :hash) << @inspector.awesome(value)
        end
      end

      data = limited(data, width, :hash => true) if should_be_limited?
      if @options[:multiline]
        "{\n" << data.join(",\n") << "\n#{outdent}}"
      else
        "{ #{data.join(', ')} }"
      end
    end

    # Format an object.
    #------------------------------------------------------------------------------
    def awesome_object(o)
      vars = o.instance_variables.map do |var|
        property = var.to_s[1..-1].to_sym # to_s because of some monkey patching done by Puppet.
        accessor = if o.respond_to?(:"#{property}=")
          o.respond_to?(property) ? :accessor : :writer
        else
          o.respond_to?(property) ? :reader : nil
        end
        if accessor
          [ "attr_#{accessor} :#{property}", var ]
        else
          [ var.to_s, var ]
        end
      end

      data = vars.sort.map do |declaration, var|
        key = left_aligned do
          align(declaration, declaration.size)
        end

        unless @options[:plain]
          if key =~ /(@\w+)/
            key.sub!($1, colorize($1, :variable))
          else
            key.sub!(/(attr_\w+)\s(\:\w+)/, "#{colorize('\\1', :keyword)} #{colorize('\\2', :method)}")
          end
        end
        indented do
          key << colorize(" = ", :hash) + @inspector.awesome(o.instance_variable_get(var))
        end
      end
      if @options[:multiline]
        "#<#{awesome_instance(o)}\n#{data.join(%Q/,\n/)}\n#{outdent}>"
      else
        "#<#{awesome_instance(o)} #{data.join(', ')}>"
      end
    end

    # Format a set.
    #------------------------------------------------------------------------------
    def awesome_set(s)
      awesome_array(s.to_a)
    end

    # Format a Struct.
    #------------------------------------------------------------------------------
    def awesome_struct(s)
      #
      # The code is slightly uglier because of Ruby 1.8.6 quirks:
      # awesome_hash(Hash[s.members.zip(s.values)]) <-- ArgumentError: odd number of arguments for Hash)
      # awesome_hash(Hash[*s.members.zip(s.values).flatten]) <-- s.members returns strings, not symbols.
      #
      hash = {}
      s.each_pair { |key, value| hash[key] = value }
      awesome_hash(hash)
    end

    # Format Class object.
    #------------------------------------------------------------------------------
    def awesome_class(c)
      if superclass = c.superclass # <-- Assign and test if nil.
        colorize("#{c.inspect} < #{superclass}", :class)
      else
        colorize(c.inspect, :class)
      end
    end

    # Format File object.
    #------------------------------------------------------------------------------
    def awesome_file(f)
      ls = File.directory?(f) ? `ls -adlF #{f.path.shellescape}` : `ls -alF #{f.path.shellescape}`
      colorize(ls.empty? ? f.inspect : "#{f.inspect}\n#{ls.chop}", :file)
    end

    # Format Dir object.
    #------------------------------------------------------------------------------
    def awesome_dir(d)
      ls = `ls -alF #{d.path.shellescape}`
      colorize(ls.empty? ? d.inspect : "#{d.inspect}\n#{ls.chop}", :dir)
    end

    # Format BigDecimal object.
    #------------------------------------------------------------------------------
    def awesome_bigdecimal(n)
      colorize(n.to_s("F"), :bigdecimal)
    end

    # Format Rational object.
    #------------------------------------------------------------------------------
    def awesome_rational(n)
      colorize(n.to_s, :rational)
    end

    # Format a method.
    #------------------------------------------------------------------------------
    def awesome_method(m)
      name, args, owner = method_tuple(m)
      "#{colorize(owner, :class)}##{colorize(name, :method)}#{colorize(args, :args)}"
    end
    alias :awesome_unboundmethod :awesome_method

    # Format object instance.
    #------------------------------------------------------------------------------
    def awesome_instance(o)
      "#{o.class}:0x%08x" % (o.__id__ * 2)
    end

    # Format object.methods array.
    #------------------------------------------------------------------------------
    def methods_array(a)
      a.sort! { |x, y| x.to_s <=> y.to_s }                  # Can't simply a.sort! because of o.methods << [ :blah ]
      object = a.instance_variable_get('@__awesome_methods__')
      tuples = a.map do |name|
        if name.is_a?(Symbol) || name.is_a?(String)         # Ignore garbage, ex. 42.methods << [ :blah ]
          tuple = if object.respond_to?(name, true)         # Is this a regular method?
            the_method = object.method(name) rescue nil     # Avoid potential ArgumentError if object#method is overridden.
            if the_method && the_method.respond_to?(:arity) # Is this original object#method?
              method_tuple(the_method)                      # Yes, we are good.
            end
          elsif object.respond_to?(:instance_method)              # Is this an unbound method?
            method_tuple(object.instance_method(name)) rescue nil # Rescue to avoid NameError when the method is not
          end                                                     # available (ex. File.lchmod on Ubuntu 12).
        end
        tuple || [ name.to_s, '(?)', '?' ]                  # Return WTF default if all the above fails.
      end

      width = (tuples.size - 1).to_s.size
      name_width = tuples.map { |item| item[0].size }.max || 0
      args_width = tuples.map { |item| item[1].size }.max || 0

      data = tuples.inject([]) do |arr, item|
        index = indent
        index << "[#{arr.size.to_s.rjust(width)}]" if @options[:index]
        indented do
          arr << "#{index} #{colorize(item[0].rjust(name_width), :method)}#{colorize(item[1].ljust(args_width), :args)} #{colorize(item[2], :class)}"
        end
      end

      "[\n" << data.join("\n") << "\n#{outdent}]"
    end

    # Return [ name, arguments, owner ] tuple for a given method.
    #------------------------------------------------------------------------------
    def method_tuple(method)
      if method.respond_to?(:parameters) # Ruby 1.9.2+
        # See http://ruby.runpaint.org/methods#method-objects-parameters
        args = method.parameters.inject([]) do |arr, (type, name)|
          name ||= (type == :block ? 'block' : "arg#{arr.size + 1}")
          arr << case type
            when :req        then name.to_s
            when :opt, :rest then "*#{name}"
            when :block      then "&#{name}"
            else '?'
          end
        end
      else # See http://ruby-doc.org/core/classes/Method.html#M001902
        args = (1..method.arity.abs).map { |i| "arg#{i}" }
        args[-1] = "*#{args[-1]}" if method.arity < 0
      end

      # method.to_s formats to handle:
      #
      # #<Method: Fixnum#zero?>
      # #<Method: Fixnum(Integer)#years>
      # #<Method: User(#<Module:0x00000103207c00>)#_username>
      # #<Method: User(id: integer, username: string).table_name>
      # #<Method: User(id: integer, username: string)(ActiveRecord::Base).current>
      # #<UnboundMethod: Hello#world>
      #
      if method.to_s =~ /(Unbound)*Method: (.*)[#\.]/
        unbound, klass = $1 && '(unbound)', $2
        if klass && klass =~ /(\(\w+:\s.*?\))/  # Is this ActiveRecord-style class?
          klass.sub!($1, '')                    # Yes, strip the fields leaving class name only.
        end
        owner = "#{klass}#{unbound}".gsub('(', ' (')
      end

      [ method.name.to_s, "(#{args.join(', ')})", owner.to_s ]
    end

    # Format hash keys as plain strings regardless of underlying data type.
    #------------------------------------------------------------------------------
    def plain_single_line
      plain, multiline = @options[:plain], @options[:multiline]
      @options[:plain], @options[:multiline] = true, false
      yield
    ensure
      @options[:plain], @options[:multiline] = plain, multiline
    end

    # Utility methods.
    #------------------------------------------------------------------------------
    def align(value, width)
      if @options[:multiline]
        if @options[:indent] > 0
          value.rjust(width)
        elsif @options[:indent] == 0
          indent + value.ljust(width)
        else
          indent[0, @indentation + @options[:indent]] + value.ljust(width)
        end
      else
        value
      end
    end

    def indented
      @indentation += @options[:indent].abs
      yield
    ensure
      @indentation -= @options[:indent].abs
    end

    def left_aligned
      current, @options[:indent] = @options[:indent], 0
      yield
    ensure
      @options[:indent] = current
    end

    def indent
      ' ' * @indentation
    end

    def outdent
      ' ' * (@indentation - @options[:indent].abs)
    end

    # To support limited output, for example:
    #
    # ap ('a'..'z').to_a, :limit => 3
    # [
    #     [ 0] "a",
    #     [ 1] .. [24],
    #     [25] "z"
    # ]
    #
    # ap (1..100).to_a, :limit => true # Default limit is 7.
    # [
    #     [ 0] 1,
    #     [ 1] 2,
    #     [ 2] 3,
    #     [ 3] .. [96],
    #     [97] 98,
    #     [98] 99,
    #     [99] 100
    # ]
    #------------------------------------------------------------------------------
    def should_be_limited?
      @options[:limit] == true or (@options[:limit].is_a?(Fixnum) and @options[:limit] > 0)
    end

    def get_limit_size
      @options[:limit] == true ? DEFAULT_LIMIT_SIZE : @options[:limit]
    end

    def limited(data, width, is_hash = false)
      limit = get_limit_size
      if data.length <= limit
        data
      else
        # Calculate how many elements to be displayed above and below the separator.
        head = limit / 2
        tail = head - (limit - 1) % 2

        # Add the proper elements to the temp array and format the separator.
        temp = data[0, head] + [ nil ] + data[-tail, tail]

        if is_hash
          temp[head] = "#{indent}#{data[head].strip} .. #{data[data.length - tail - 1].strip}"
        else
          temp[head] = "#{indent}[#{head.to_s.rjust(width)}] .. [#{data.length - tail - 1}]"
        end

        temp
      end
    end
  end
end

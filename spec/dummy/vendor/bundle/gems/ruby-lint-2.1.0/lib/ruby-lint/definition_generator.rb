require 'erb'

require_relative 'inspector'
require_relative 'template/scope'
require_relative 'generated_constant'

module RubyLint
  ##
  # The DefinitionGenerator class is used for generating definitions based on
  # the data that is available in the current Ruby runtime. Using this
  # generator the otherwise painful and time consuming task of adding
  # definitions for large projects (e.g. Ruby itself or Rails) becomes very
  # easy up to the point where it will only take a minute or two.
  #
  # Note that this generator works best on Ruby implementations that provide
  # accurate parameter information using `UnboundMethod#parameters`. Currently
  # the only implementation where this is the case is Rubinius HEAD. Both MRI
  # and Jruby provide inaccurate information.
  #
  # @!attribute [r] directory
  #  @return [String] The directory to store the generated definitions in.
  #
  # @!attribute [r] options
  #  @return [Hash]
  #
  # @!attribute [r] template
  #  @return [String] The ERB template to use.
  #
  # @!attribute [r] inspector
  #  @return [RubyLint::Inspector]
  #
  class DefinitionGenerator
    attr_reader :directory, :options, :template, :inspector

    ##
    # @param [Class] constant
    # @param [String] directory
    # @param [Hash] options
    #
    def initialize(constant, directory, options = {})
      @options   = default_options.merge(options)
      @inspector = Inspector.new(constant)
      @directory = directory
      @template  = File.read(
        File.expand_path('../template/definition.erb', __FILE__)
      )
    end

    ##
    # Generates the definitions for every constant.
    #
    def generate
      constants = inspector.inspect_constants(
        inspector.constant,
        options[:ignore].dup
      )

      constants = constants.sort

      group_constants(constants).each do |root, names|
        filepath  = File.join(directory, "#{root.snake_case}.rb")
        constants = []

        if File.file?(filepath) and !options[:overwrite]
          next
        end

        names.each do |name|
          current_inspector = Inspector.new(name)
          inspected_methods = inspect_methods(current_inspector)
          superclass        = nil

          if current_inspector.inspect_superclass
            superclass = current_inspector.inspect_superclass.to_s
          end

          constant = GeneratedConstant.new(
            :name       => current_inspector.constant_name,
            :constant   => current_inspector.constant,
            :methods    => method_information(inspected_methods),
            :superclass => superclass,

            # Kernel is ignored since its included already in core/object.rb
            :modules    => current_inspector.inspect_modules - [Kernel]
          )

          constants << constant
        end

        render_template(filepath, template, constants)
      end
    end

    private

    ##
    # @param [String] path
    # @param [String] template
    # @param [Array] constants
    #
    def render_template(path, template, constants)
      erb = render_erb(template, :constants => constants)

      File.open(path, 'w') do |handle|
        handle.write(erb)
      end
    end

    ##
    # Groups constants together based on the top level namespace segment.
    #
    # @param [Array] constants
    # @return [Hash]
    #
    def group_constants(constants)
      grouped = Hash.new { |hash, key| hash[key] = [] }

      constants.each do |name|
        root           = name.split('::')[0]
        grouped[root] << name
      end

      return grouped
    end

    ##
    # @return [Hash]
    #
    def default_options
      return {:ignore => [], :overwrite => false}
    end

    ##
    # @param [RubyLint::Inspector] inspector
    # @return [Hash]
    #
    def inspect_methods(inspector)
      return {
        :method          => inspector.inspect_methods,
        :instance_method => inspector.inspect_instance_methods
      }
    end

    ##
    # Returns a Hash containing all the instance and class methods and their
    # arguments.
    #
    # @param [Hash] inspected
    # @return [Hash]
    #
    def method_information(inspected)
      arg_mapping = argument_mapping
      info        = {:method => {}, :instance_method => {}}

      inspected.each do |type, methods|
        methods.each do |method|
          args = []

          method.parameters.each_with_index do |arg, index|
            name = arg[1] || "arg#{index + 1}"
            args << {:type => arg_mapping[arg[0]], :name => name}
          end

          info[type][method.name] = args
        end
      end

      return info
    end

    ##
    # @return [Hash]
    #
    def argument_mapping
      return {
        :req   => :argument,
        :opt   => :optional_argument,
        :rest  => :rest_argument,
        :block => :block_argument
      }
    end

    ##
    # @param [String] template
    # @param [Hash] variables
    #
    def render_erb(template, variables = {})
      scope = Template::Scope.new(variables)
      erb   = ERB.new(template, nil, '-').result(scope.get_binding)

      # Trim excessive newlines.
      erb.gsub!(/\n{3,}/, "\n\n")

      # Get rid of the occasional empty newline before `end` tokens.
      erb.gsub!(/\n{2,}end/, "\nend")

      return erb
    end
  end # DefinitionGenerator
end # RubyLint

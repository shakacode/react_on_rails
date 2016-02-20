require_relative '../ruby-lint'
require 'rake/tasklib'

module RubyLint
  ##
  # Class for easily creating Rake tasks without having to shell out to the
  # commandline executable.
  #
  # Basic usage:
  #
  #     require 'ruby-lint/rake_task'
  #
  #     RubyLint::RakeTask.new do |task|
  #       task.name  = 'lint'
  #       task.files = ['lib/my-project-name']
  #     end
  #
  # @!attribute [rw] name
  #  @return [String] The name of the task.
  #
  # @!attribute [rw] description
  #  @return [String] The description of the task.
  #
  # @!attribute [rw] debug
  #  @return [TrueClass|FalseClass] Enables/disables debugging mode.
  #
  # @!attribute [rw] files
  #  @return [Array] The files to check.
  #
  # @!attribute [rw] configuration
  #  @return [String] Path to the configuration file to use.
  #
  class RakeTask < Rake::TaskLib
    attr_accessor :name, :description, :debug, :files, :configuration

    ##
    # @param [Hash] options
    #
    def initialize(options = {})
      @name        = 'lint'
      @description = 'Check source code using ruby-lint'

      options.each do |key, value|
        instance_variable_set("@#{key}", value) if respond_to?(key)
      end

      yield self if block_given?

      desc(description)
      task(name) do
        validate!
        run_task
      end
    end

    ##
    # Checks if the task is configured properly, exists with code 1 if this
    # isn't the case.
    #
    def validate!
      if configuration and !File.file?(configuration)
        abort "The configuration file #{configuration} does not exist"
      end

      if files.empty?
        abort 'No files to check were specified'
      end
    end

    ##
    # Processes a list of files and writes the output to STDOUT.
    #
    def run_task
      config = create_configuration
      runner = RubyLint::Runner.new(config)
      list   = FileList.new
      output = runner.analyze(list.process(files))

      puts(output) unless output.empty?
    end

    ##
    # @return [RubyLint::Configuration]
    #
    def create_configuration
      config_files = RubyLint::Configuration.configuration_files

      if configuration
        config_files = [configuration]
      end

      config       = RubyLint::Configuration.load_from_file(config_files)
      config.debug = debug

      return config
    end
  end # RakeTask
end # RubyLint

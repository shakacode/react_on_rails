# encoding: utf-8
require 'shellwords'

module Cliver
  # Default implementation of the detector needed by Cliver::Assertion,
  # which will take anything that #respond_to?(:to_proc)
  class Detector < Struct.new(:command_arg, :version_pattern)
    # @param detector_argument [#call, Object]
    #   If detector_argument responds to #call, return it; otherwise attempt
    #   to create an instance of self.
    def self.generate(detector_argument)
      return detector_argument if detector_argument.respond_to?(:call)
      new(*Array(detector_argument))
    end

    # Default pattern to use when searching {#version_command} output
    DEFAULT_VERSION_PATTERN = /(version ?)?[0-9][.0-9a-z]+/i.freeze

    # Default command argument to use against the executable to get
    # version output
    DEFAULT_COMMAND_ARG = '--version'.freeze

    # Forgiving input, allows either argument if only one supplied.
    #
    # @overload initialize(*command_args)
    #   @param command_args [Array<String>]
    # @overload initialize(version_pattern)
    #   @param version_pattern [Regexp]
    # @overload initialize(*command_args, version_pattern)
    #   @param command_args [Array<String>]
    #   @param version_pattern [Regexp]
    def initialize(*args)
      version_pattern = args.pop if args.last.kind_of?(Regexp)
      command_args = args unless args.empty?

      super(command_args, version_pattern)
    end

    # @param executable_path [String] - the path to the executable to test
    # @return [String] - should be contain {Gem::Version}-parsable
    #                    version number.
    def detect_version(executable_path)
      capture = ShellCapture.new(version_command(executable_path))
      unless capture.command_found
        raise Cliver::Dependency::NotFound.new(
            "Could not find an executable at given path '#{executable_path}'." +
            "If this path was not specified explicitly, it is probably a " +
            "bug in [Cliver](https://github.com/yaauie/cliver/issues)."
          )
      end
      capture.stdout[version_pattern] || capture.stderr[version_pattern]
    end

    # This is the interface that any detector must have.
    # If not overridden, returns a proc that wraps #detect_version
    # @see #detect_version
    # @return [Proc] following method signature of {#detect_version}
    def to_proc
      method(:detect_version).to_proc
    end

    # The pattern to match the version in {#version_command}'s output.
    # Defaults to {DEFAULT_VERSION_PATTERN}
    # @return [Regexp] - the pattern used against the output
    #                    of the #version_command, which should
    #                    contain a {Gem::Version}-parsable substring.
    def version_pattern
      super || DEFAULT_VERSION_PATTERN
    end

    # The argument to pass to the executable to get current version
    # Defaults to {DEFAULT_COMMAND_ARG}
    # @return [String, Array<String>]
    def command_arg
      super || DEFAULT_COMMAND_ARG
    end

    # @param executable_path [String] the executable to test
    # @return [Array<String>]
    def version_command(executable_path)
      [executable_path, *Array(command_arg)]
    end
  end
end

# encoding: utf-8
require 'rubygems/requirement'
require 'set'

module Cliver
  # This is how a dependency is specified.
  class Dependency

    # An exception class raised when assertion is not met
    NotMet = Class.new(ArgumentError)

    # An exception that is raised when executable present, but
    # no version that matches the requirements is present.
    VersionMismatch = Class.new(Dependency::NotMet)

    # An exception that is raised when executable is not present at all.
    NotFound = Class.new(Dependency::NotMet)

    # A pattern for extracting a {Gem::Version}-parsable version
    PARSABLE_GEM_VERSION = /[0-9]+(.[0-9]+){0,4}(.[a-zA-Z0-9]+)?/.freeze

    # @overload initialize(executables, *requirements, options = {})
    #   @param executables [String,Array<String>] api-compatible executable names
    #                                      e.g, ['python2','python']
    #   @param requirements [Array<String>, String] splat of strings
    #     whose elements follow the pattern
    #       [<operator>] <version>
    #     Where <operator> is optional (default '='') and in the set
    #       '=', '!=', '>', '<', '>=', '<=', or '~>'
    #     And <version> is dot-separated integers with optional
    #     alphanumeric pre-release suffix. See also
    #     {http://docs.rubygems.org/read/chapter/16 Specifying Versions}
    #   @param options [Hash<Symbol,Object>]
    #   @option options [Cliver::Detector] :detector (Detector.new)
    #   @option options [#to_proc, Object] :detector (see Detector::generate)
    #   @option options [#to_proc] :filter ({Cliver::Filter::IDENTITY})
    #   @option options [Boolean]  :strict (false)
    #                                      true -  fail if first match on path fails
    #                                              to meet version requirements.
    #                                              This is used for Cliver::assert.
    #                                      false - continue looking on path until a
    #                                              sufficient version is found.
    #   @option options [String]   :path   ('*') the path on which to search
    #                                      for executables. If an asterisk (`*`) is
    #                                      included in the supplied string, it is
    #                                      replaced with `ENV['PATH']`
    #
    #   @yieldparam executable_path [String] (see Detector#detect_version)
    #   @yieldreturn [String] containing a version that, once filtered, can be
    #                         used for comparrison.
    def initialize(executables, *args, &detector)
      options = args.last.kind_of?(Hash) ? args.pop : {}
      @detector = Detector::generate(detector || options[:detector])
      @filter = options.fetch(:filter, Filter::IDENTITY).extend(Filter)
      @path = options.fetch(:path, '*')
      @strict = options.fetch(:strict, false)

      @executables = Array(executables).dup.freeze
      @requirement = args unless args.empty?

      check_compatibility!
    end

    # One of these things is not like the other ones...
    # Some feature combinations just aren't compatible. This method ensures
    # the the features selected for this object are compatible with each-other.
    # @return [void]
    # @raise [ArgumentError] if incompatibility found
    def check_compatibility!
      case
      when @executables.any? {|exe| exe[File::SEPARATOR] && !File.absolute_path?(exe) }
        # if the executable contains a path component, it *must* be absolute.
        raise ArgumentError, "Relative-path executable requirements are not supported."
      end
    end

    # Get all the installed versions of the api-compatible executables.
    # If a block is given, it yields once per found executable, lazily.
    # @yieldparam executable_path [String]
    # @yieldparam version [String]
    # @yieldreturn [Boolean] - true if search should stop.
    # @return [Hash<String,String>] executable_path, version
    def installed_versions
      return enum_for(:installed_versions) unless block_given?

      find_executables.each do |executable_path|
        version = detect_version(executable_path)

        break(2) if yield(executable_path, version)
      end
    end

    # The non-raise variant of {#detect!}
    # @return (see #detect!)
    #   or nil if no match found.
    def detect
      detect!
    rescue Dependency::NotMet
      nil
    end

    # Detects an installed version of the executable that matches the
    # requirements.
    # @return [String] path to an executable that meets the requirements
    # @raise [Cliver::Dependency::NotMet] if no match found
    def detect!
      installed = {}
      installed_versions.each do |path, version|
        installed[path] = version
        return path if ENV['CLIVER_NO_VERIFY']
        return path if requirement_satisfied_by?(version)
        strict?
      end

      # dependency not met. raise the appropriate error.
      raise_not_found! if installed.empty?
      raise_version_mismatch!(installed)
    end

    private

    # @api private
    # @return [Gem::Requirement]
    def filtered_requirement
      @filtered_requirement ||= begin
        Gem::Requirement.new(@filter.requirements(@requirement))
      end
    end

    # @api private
    # @param raw_version [String]
    # @return [Boolean]
    def requirement_satisfied_by?(raw_version)
      return true unless @requirement
      parsable_version = @filter.apply(raw_version)[PARSABLE_GEM_VERSION]
      parsable_version || raise(ArgumentError) # TODO: make descriptive
      filtered_requirement.satisfied_by? Gem::Version.new(parsable_version)
    end

    # @api private
    # @raise [Cliver::Dependency::NotFound] with appropriate error message
    def raise_not_found!
      raise Dependency::NotFound.new(
        "Could not find an executable #{@executables} on your path.")
    end

    # @api private
    # @raise [Cliver::Dependency::VersionMismatch] with appropriate error message
    # @param installed [Hash<String,String>] the found versions
    def raise_version_mismatch!(installed)
      raise Dependency::VersionMismatch.new(
        "Could not find an executable #{executable_description} that " +
        "matched the requirements #{requirements_description}. " +
        "Found versions were #{installed.inspect}.")
    end

    # @api private
    # @return [String] a plain-language representation of the executables
    #   for which we were searching
    def executable_description
      quoted_exes = @executables.map {|exe| "'#{exe}'" }
      return quoted_exes.first if quoted_exes.size == 1

      last_quoted_exec = quoted_exes.pop
      "#{quoted_exes.join(', ')} or #{last_quoted_exec}"
    end

    # @api private
    # @return [String] a plain-language representation of the requirements
    def requirements_description
      @requirement.map {|req| "'#{req}'" }.join(', ')
    end

    # If strict? is true, only attempt the first matching executable on the path
    # @api private
    # @return [Boolean]
    def strict?
      false | @strict
    end

    # Given a path to an executable, detect its version
    # @api private
    # @param executable_path [String]
    # @return [String]
    # @raise [ArgumentError] if version cannot be detected.
    def detect_version(executable_path)
      # No need to shell out if we are only checking its presence.
      return '99.version_detection_not_required' unless @requirement

      raw_version = @detector.to_proc.call(executable_path)
      raw_version || raise(ArgumentError,
                           "The detector #{@detector} failed to detect the" +
                           "version of the executable at '#{executable_path}'")
    end

    # Analog of Windows `where` command, or a `which` that finds *all*
    # matching executables on the supplied path.
    # @return [Enumerable<String>] - the executables found, lazily.
    def find_executables
      return enum_for(:find_executables) unless block_given?

      exts = (ENV.has_key?('PATHEXT') ? ENV.fetch('PATHEXT').split(';') : []) << ''
      paths = @path.sub('*', ENV['PATH']).split(File::PATH_SEPARATOR)
      raise ArgumentError.new('No PATH to search!') if paths.empty?
      cmds = strict? ? @executables.first(1) : @executables

      lookup_cache = Set.new
      cmds.product(paths, exts).map do |cmd, path, ext|
        exe = File.absolute_path?(cmd) ? cmd : File.expand_path("#{cmd}#{ext}", path)

        next unless lookup_cache.add?(exe) # don't yield the same exe path 2x
        next unless File.executable?(exe)

        yield exe
      end
    end
  end
end

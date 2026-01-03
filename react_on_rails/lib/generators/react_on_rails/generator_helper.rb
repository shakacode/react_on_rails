# frozen_string_literal: true

require "rainbow"
require "json"

module GeneratorHelper
  def package_json
    # Lazy load package_json gem only when actually needed for dependency management

    require "package_json" unless defined?(PackageJson)
    @package_json ||= PackageJson.read
  rescue LoadError
    puts "Warning: package_json gem not available. This is expected before Shakapacker installation."
    puts "Dependencies will be installed using the default package manager after Shakapacker setup."
    nil
  rescue StandardError => e
    puts "Warning: Could not read package.json: #{e.message}"
    puts "This is normal before Shakapacker creates the package.json file."
    nil
  end

  # Safe wrapper for package_json operations
  def add_npm_dependencies(packages, dev: false)
    pj = package_json
    return false unless pj

    begin
      if dev
        pj.manager.add(packages, type: :dev, exact: true)
      else
        pj.manager.add(packages, exact: true)
      end
      true
    rescue StandardError => e
      puts "Warning: Could not add packages via package_json gem: #{e.message}"
      puts "Will fall back to direct npm commands."
      false
    end
  end

  # Takes a relative path from the destination root, such as `.gitignore` or `app/assets/javascripts/application.js`
  def dest_file_exists?(file)
    dest_file = File.join(destination_root, file)
    File.exist?(dest_file) ? dest_file : nil
  end

  def dest_dir_exists?(dir)
    dest_dir = File.join(destination_root, dir)
    Dir.exist?(dest_dir) ? dest_dir : nil
  end

  def setup_file_error(file, data)
    <<~MSG
      #{file} was not found.
      Please add the following content to your #{file} file:
      #{data}
    MSG
  end

  def empty_directory_with_keep_file(destination, config = {})
    empty_directory(destination, config)
    keep_file(destination)
  end

  def keep_file(destination)
    create_file("#{destination}/.keep") unless options[:skip_keeps]
  end

  # As opposed to Rails::Generators::Testing.create_link, which creates a link pointing to
  # source_root, this symlinks a file in destination_root to a file also in
  # destination_root.
  def symlink_dest_file_to_dest_file(target, link)
    target_pathname = Pathname.new(File.join(destination_root, target))
    link_pathname = Pathname.new(File.join(destination_root, link))

    link_directory = link_pathname.dirname
    link_basename = link_pathname.basename
    target_relative_path = target_pathname.relative_path_from(link_directory)

    `cd #{link_directory} && ln -s #{target_relative_path} #{link_basename}`
  end

  def copy_file_and_missing_parent_directories(source_file, destination_file = nil)
    destination_file ||= source_file
    destination_path = Pathname.new(destination_file)
    parent_directories = destination_path.dirname
    empty_directory(parent_directories) unless dest_dir_exists?(parent_directories)
    copy_file source_file, destination_file
  end

  def add_documentation_reference(message, source)
    "#{message} \n#{source}"
  end

  def component_extension(options)
    options.typescript? ? "tsx" : "jsx"
  end

  # Check if a gem is present in Gemfile.lock
  #
  # @param gem_name [String] Name of the gem to check
  # @return [Boolean] true if the gem is in Gemfile.lock
  def gem_in_lockfile?(gem_name)
    gemfile = ENV["BUNDLE_GEMFILE"] || "Gemfile"
    lockfile = File.join(File.dirname(gemfile), "Gemfile.lock")

    File.file?(lockfile) &&
      File.foreach(lockfile).any? { |line| line.match?(/^\s{4}#{Regexp.escape(gem_name)}\s\(/) }
  rescue StandardError
    false
  end

  # Check if React on Rails Pro gem is installed
  #
  # Detection priority:
  # 1. Gem.loaded_specs - gem is loaded in current Ruby process (most reliable)
  # 2. Gemfile.lock - gem is resolved and installed
  #
  # @return [Boolean] true if react_on_rails_pro gem is installed
  def pro_gem_installed?
    return @pro_gem_installed if defined?(@pro_gem_installed)

    @pro_gem_installed = Gem.loaded_specs.key?("react_on_rails_pro") || gem_in_lockfile?("react_on_rails_pro")
  end

  # Check if Pro features should be enabled
  # Returns true if --pro flag is set OR --rsc flag is set (RSC implies Pro)
  #
  # @return [Boolean] true if Pro setup should be included
  def use_pro?
    options[:pro] || options[:rsc]
  end

  # Check if RSC (React Server Components) should be enabled
  # Returns true only if --rsc flag is explicitly set
  #
  # @return [Boolean] true if RSC setup should be included
  def use_rsc?
    options[:rsc]
  end

  # Detect the installed React version from package.json
  # Uses VERSION_PARTS_REGEX pattern from VersionChecker for consistency
  #
  # @return [String, nil] React version string (e.g., "19.0.3") or nil if not found/parseable
  def detect_react_version
    pj = package_json
    return nil unless pj

    dependencies = pj.fetch("dependencies", {})
    react_version = dependencies["react"]
    return nil unless react_version

    # Skip non-version strings (workspace:*, file:, link:, http://, etc.)
    return nil if react_version.include?("/") || react_version.start_with?("workspace:")

    # Extract version using the same regex pattern as VersionChecker
    # Handles: "19.0.3", "^19.0.3", "~19.0.3", "19.0.3-beta.1", etc.
    match = react_version.match(/(\d+)\.(\d+)\.(\d+)(?:[-.]([0-9A-Za-z.-]+))?/)
    return nil unless match

    # Return the matched version (without pre-release suffix for comparison)
    "#{match[1]}.#{match[2]}.#{match[3]}"
  rescue StandardError
    nil
  end

  # Check if Shakapacker 9.0 or higher is available
  # Returns true if Shakapacker >= 9.0, false otherwise
  #
  # This method is used during code generation to determine which configuration
  # patterns to use in generated files (e.g., config.privateOutputPath vs hardcoded paths).
  #
  # @return [Boolean] true if Shakapacker 9.0+ is available or likely to be installed
  #
  # @note Default behavior: Returns true when Shakapacker is not yet installed
  #   Rationale: During fresh installations, we optimistically assume users will install
  #   the latest Shakapacker version. This ensures new projects get best-practice configs.
  #   If users later install an older version, the generated webpack config includes
  #   fallback logic (e.g., `config.privateOutputPath || hardcodedPath`) that prevents
  #   breakage, and validation warnings guide them to fix any misconfigurations.
  def shakapacker_version_9_or_higher?
    return @shakapacker_version_9_or_higher if defined?(@shakapacker_version_9_or_higher)

    @shakapacker_version_9_or_higher = begin
      # If Shakapacker is not available yet (fresh install), default to true
      # since we're likely installing the latest version
      return true unless defined?(ReactOnRails::PackerUtils)

      ReactOnRails::PackerUtils.shakapacker_version_requirement_met?("9.0.0")
    rescue StandardError
      # If we can't determine version, assume latest
      true
    end
  end

  # Check if SWC is configured as the JavaScript transpiler in shakapacker.yml
  #
  # @return [Boolean] true if SWC is configured or should be used by default
  #
  # Detection logic:
  # 1. If shakapacker.yml exists and specifies javascript_transpiler: parse it
  # 2. For Shakapacker 9.3.0+, SWC is the default if not specified
  # 3. Returns true for fresh installations (SWC is recommended default)
  #
  # @note This method is used to determine whether to install SWC dependencies
  #   (@swc/core, swc-loader) instead of Babel dependencies during generation.
  #
  # @note Caching: The result is memoized for the lifetime of the generator instance.
  #   If shakapacker.yml changes during generator execution (unlikely), the cached
  #   value will not update. This is acceptable since generators run quickly.
  def using_swc?
    return @using_swc if defined?(@using_swc)

    @using_swc = detect_swc_configuration
  end

  private

  def detect_swc_configuration
    shakapacker_yml_path = File.join(destination_root, "config/shakapacker.yml")

    if File.exist?(shakapacker_yml_path)
      config = parse_shakapacker_yml(shakapacker_yml_path)
      transpiler = config.dig("default", "javascript_transpiler")

      # Explicit configuration takes precedence
      return transpiler == "swc" if transpiler

      # For Shakapacker 9.3.0+, SWC is the default
      return shakapacker_version_9_3_or_higher?
    end

    # Fresh install: SWC is recommended default for Shakapacker 9.3.0+
    shakapacker_version_9_3_or_higher?
  end

  def parse_shakapacker_yml(path)
    require "yaml"
    # Use safe_load_file for security (defense-in-depth, even though this is user's own config)
    # permitted_classes: [Symbol] allows symbol keys which shakapacker.yml may use
    # aliases: true allows YAML anchors (&default, *default) commonly used in Rails configs
    YAML.safe_load_file(path, permitted_classes: [Symbol], aliases: true)
  rescue ArgumentError
    # Older Psych versions don't support all parameters - try without aliases
    begin
      YAML.safe_load_file(path, permitted_classes: [Symbol])
    rescue ArgumentError
      # Very old Psych - fall back to safe_load with File.read
      YAML.safe_load(File.read(path), permitted_classes: [Symbol]) # rubocop:disable Style/YAMLFileRead
    end
  rescue StandardError
    # If we can't parse the file, return empty config
    {}
  end

  # Check if Shakapacker 9.3.0 or higher is available
  # This version made SWC the default JavaScript transpiler
  def shakapacker_version_9_3_or_higher?
    return true unless defined?(ReactOnRails::PackerUtils)

    ReactOnRails::PackerUtils.shakapacker_version_requirement_met?("9.3.0")
  rescue StandardError
    # If we can't determine version, assume latest (which uses SWC)
    true
  end
end

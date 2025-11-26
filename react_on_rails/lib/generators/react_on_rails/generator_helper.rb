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
    # Support both old and new Psych versions
    YAML.load_file(path, aliases: true)
  rescue ArgumentError
    # Older Psych versions don't support the aliases parameter
    YAML.load_file(path)
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

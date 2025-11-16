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
end

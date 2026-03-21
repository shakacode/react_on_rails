# frozen_string_literal: true

module ReactOnRails
  # Synchronizes React on Rails npm package versions with loaded gem versions.
  # Dry-run is the default behavior. Use write mode to persist updates.
  class VersionSynchronizer
    PACKAGE_SECTIONS = %w[dependencies devDependencies peerDependencies optionalDependencies].freeze
    PACKAGE_VERSION_SOURCES = {
      "react-on-rails" => :react_on_rails,
      "react-on-rails-pro" => :react_on_rails_pro,
      "react-on-rails-pro-node-renderer" => :react_on_rails_pro
    }.freeze

    Result = Struct.new(:changes, :changed_files, keyword_init: true)

    def initialize(package_json_path: VersionChecker::NodePackageVersion.package_json_path, io: $stdout)
      @package_json_path = package_json_path.to_s
      @io = io
      @converter = VersionSyntaxConverter.new
    end

    def sync(write: false)
      package_json_data = parse_package_json
      changes = detect_changes(package_json_data)

      apply_changes!(package_json_data, changes) if write && changes.any?
      print_summary(changes, write: write)

      changed_files = write && changes.any? ? [package_json_path] : []
      Result.new(changes: changes, changed_files: changed_files)
    end

    private

    attr_reader :package_json_path, :io, :converter

    def parse_package_json
      raise ReactOnRails::Error, "package.json not found at #{package_json_path}" unless File.exist?(package_json_path)

      JSON.parse(File.read(package_json_path))
    rescue JSON::ParserError => e
      raise ReactOnRails::Error, "Invalid JSON in #{package_json_path}: #{e.message}"
    end

    def detect_changes(package_json_data)
      expected_versions = expected_package_versions

      PACKAGE_SECTIONS.each_with_object([]) do |section, changes|
        dependencies = package_json_data[section]
        next unless dependencies.is_a?(Hash)

        PACKAGE_VERSION_SOURCES.each do |package_name, source_key|
          next unless dependencies.key?(package_name)

          expected_version = expected_versions[source_key]
          next if expected_version.nil?
          next if dependencies[package_name] == expected_version

          changes << {
            section: section,
            package: package_name,
            from: dependencies[package_name],
            to: expected_version
          }
        end
      end
    end

    def expected_package_versions
      versions = {
        react_on_rails: converter.rubygem_to_npm(ReactOnRails::VERSION)
      }

      pro_version = ReactOnRails::Utils.react_on_rails_pro_version
      return versions if pro_version.blank?

      versions[:react_on_rails_pro] = converter.rubygem_to_npm(pro_version)
      versions
    end

    def apply_changes!(package_json_data, changes)
      changes.each do |change|
        package_json_data[change[:section]][change[:package]] = change[:to]
      end

      File.write(package_json_path, "#{JSON.pretty_generate(package_json_data)}\n")
    end

    def print_summary(changes, write:)
      if changes.empty?
        io.puts "No version mismatches found in #{package_json_path}."
        return
      end

      io.puts "Version mismatches detected in #{package_json_path}:"
      changes.each do |change|
        io.puts "  - #{change[:section]}.#{change[:package]}: #{change[:from]} -> #{change[:to]}"
      end

      if write
        io.puts "Updated file:"
        io.puts "  - #{package_json_path}"
      else
        io.puts "Dry run only. Re-run with WRITE=true to apply changes."
      end
    end
  end
end

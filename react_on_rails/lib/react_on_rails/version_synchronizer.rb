# frozen_string_literal: true

require "json"
require_relative "version_syntax_converter"

module ReactOnRails
  # Synchronizes React on Rails npm package versions with loaded gem versions.
  # Dry-run is the default behavior. Use write mode to persist updates.
  class VersionSynchronizer
    PACKAGE_SECTIONS = %w[dependencies devDependencies optionalDependencies peerDependencies].freeze
    # Matches exact npm versions (e.g. "1.2.3", "1.2.3-rc.4") and rubygem-style
    # prerelease notation (e.g. "1.2.3.rc.4") so malformed copied values can be corrected.
    EXACT_VERSION_REGEX = /\A\d+\.\d+\.\d+(?:[-.][0-9A-Za-z.-]+)?\z/
    PACKAGE_VERSION_SOURCES = {
      "react-on-rails" => :react_on_rails,
      "react-on-rails-pro" => :react_on_rails_pro,
      "react-on-rails-pro-node-renderer" => :react_on_rails_pro
    }.freeze

    Result = Struct.new(:changes, :changed_files, :unsupported_specs, keyword_init: true)

    def initialize(package_json_path: VersionChecker::NodePackageVersion.package_json_path, io: $stdout)
      @package_json_path = package_json_path.to_s
      @io = io
      @converter = VersionSyntaxConverter.new
    end

    def sync(write: false)
      package_json_data, original_content = parse_package_json
      changes, unsupported_specs = detect_changes(package_json_data)

      apply_changes!(package_json_data, changes, original_content) if write && changes.any?
      print_summary(changes, unsupported_specs: unsupported_specs, write: write)

      changed_files = write && changes.any? ? [package_json_path] : []
      Result.new(changes: changes, changed_files: changed_files, unsupported_specs: unsupported_specs)
    end

    private

    attr_reader :package_json_path, :io, :converter

    def parse_package_json
      raise ReactOnRails::Error, "package.json not found at #{package_json_path}" unless File.file?(package_json_path)

      content = File.read(package_json_path)
      [JSON.parse(content), content]
    rescue JSON::ParserError => e
      raise ReactOnRails::Error, "Invalid JSON in #{package_json_path}: #{e.message}"
    rescue SystemCallError => e
      raise ReactOnRails::Error, "Unable to read #{package_json_path}: #{e.message}"
    end

    def detect_changes(package_json_data)
      expected_versions = expected_package_versions
      changes = []
      unsupported_specs = []

      PACKAGE_SECTIONS.each do |section|
        dependencies = package_json_data[section]
        next unless dependencies.is_a?(Hash)

        PACKAGE_VERSION_SOURCES.each do |package_name, source_key|
          next unless dependencies.key?(package_name)

          current_version = dependencies[package_name]
          unless exact_version?(current_version)
            unsupported_specs << { section: section, package: package_name, version: current_version }
            next
          end

          expected_version = expected_versions[source_key]
          next if expected_version.nil?
          next if current_version == expected_version

          changes << {
            section: section,
            package: package_name,
            from: current_version,
            to: expected_version
          }
        end
      end

      [changes, unsupported_specs]
    end

    def expected_package_versions
      versions = {
        react_on_rails: converter.rubygem_to_npm(ReactOnRails::VERSION)
      }

      pro_version = ReactOnRails::Utils.react_on_rails_pro_version
      return versions if pro_version.empty?

      versions[:react_on_rails_pro] = converter.rubygem_to_npm(pro_version)
      versions
    end

    def apply_changes!(package_json_data, changes, original_content)
      changes.each do |change|
        package_json_data[change[:section]][change[:package]] = change[:to]
      end

      indentation = detect_indentation(original_content)
      generated_json = JSON.generate(package_json_data,
                                     ascii_only: false,
                                     indent: indentation,
                                     object_nl: "\n",
                                     array_nl: "\n",
                                     space: " ")
      write_atomically("#{generated_json}\n")
    end

    def print_summary(changes, unsupported_specs:, write:)
      if changes.empty?
        print_no_changes_summary
      else
        print_changes_summary(changes, write: write)
      end

      print_unsupported_specs(unsupported_specs)
    end

    def exact_version?(version)
      version.is_a?(String) && version.match?(EXACT_VERSION_REGEX)
    end

    def write_atomically(content)
      tmp_path = "#{package_json_path}.tmp-#{Process.pid}-#{Thread.current.object_id}"
      File.write(tmp_path, content)
      File.rename(tmp_path, package_json_path)
    ensure
      cleanup_tmp_file(tmp_path)
    end

    def lockfile_present?
      package_dir = File.dirname(package_json_path)
      %w[yarn.lock package-lock.json pnpm-lock.yaml bun.lock].any? do |lockfile_name|
        File.exist?(File.join(package_dir, lockfile_name))
      end
    end

    def print_no_changes_summary
      io.puts "No package.json version mismatches found in #{package_json_path}."
      io.puts "Lockfiles may still pin different versions than package.json." if lockfile_present?
    end

    def print_changes_summary(changes, write:)
      io.puts "Version mismatches detected in #{package_json_path}:"
      changes.each do |change|
        io.puts "  - #{change[:section]}.#{change[:package]}: #{change[:from]} -> #{change[:to]}"
      end

      if write
        io.puts "Updated file:"
        io.puts "  - #{package_json_path}"
        io.puts "Run your package manager install command to refresh lockfile entries."
        io.puts "Write mode may normalize package.json formatting, including array wrapping."
      else
        io.puts "Dry run only. Re-run with WRITE=true to apply changes."
      end
    end

    def print_unsupported_specs(unsupported_specs)
      return if unsupported_specs.empty?

      io.puts "Skipped non-exact version specs (not auto-updated):"
      unsupported_specs.each do |spec|
        io.puts "  - #{spec[:section]}.#{spec[:package]}: #{spec[:version]}"
      end
    end

    def cleanup_tmp_file(tmp_path)
      return unless tmp_path && File.exist?(tmp_path)

      File.delete(tmp_path)
    rescue SystemCallError
      nil
    end

    def detect_indentation(content)
      indented_key_line = content.each_line.find { |line| line.match?(/^[ \t]+"[^"\n]+":/) }
      indentation = indented_key_line&.slice(/^[ \t]+/)
      indentation.nil? ? "  " : indentation
    end
  end
end

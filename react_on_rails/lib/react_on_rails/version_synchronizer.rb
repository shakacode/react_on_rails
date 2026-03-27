# frozen_string_literal: true

require "json"
require "securerandom"
require_relative "version_syntax_converter"
require_relative "version_checker"

module ReactOnRails
  # rubocop:disable Metrics/ClassLength
  class VersionSynchronizer
    PACKAGE_SECTIONS = %w[dependencies devDependencies optionalDependencies peerDependencies].freeze
    NPM_ALIAS_PREFIX = "npm:"
    # Matches exact npm versions and rubygem-style prerelease notation (e.g. "1.2.3.rc.4").
    # Prerelease/build segments are intentionally bounded to avoid matching arbitrarily long dotted suffixes.
    EXACT_VERSION_REGEX = /\A\d+\.\d+\.\d+(?:[-.][0-9A-Za-z]+(?:\.[0-9A-Za-z-]+){0,4})?\z/
    PACKAGE_VERSION_SOURCES = {
      "react-on-rails" => :react_on_rails,
      "react-on-rails-pro" => :react_on_rails_pro,
      "react-on-rails-pro-node-renderer" => :react_on_rails_pro
    }.freeze

    Result = Struct.new(:changes, :changed_files, :unsupported_specs, :missing_source_specs, keyword_init: true)

    def initialize(package_json_path: VersionChecker::NodePackageVersion.package_json_path, io: $stdout)
      @package_json_path = package_json_path.to_s
      @io = io
      @converter = VersionSyntaxConverter.new
    end

    def sync(write: false)
      package_json_data, original_content = parse_package_json
      changes, unsupported_specs, missing_source_specs = detect_changes(package_json_data)

      apply_changes!(package_json_data, changes, original_content) if write && changes.any?
      print_summary(changes,
                    unsupported_specs: unsupported_specs,
                    missing_source_specs: missing_source_specs,
                    write: write)

      changed_files = write && changes.any? ? [package_json_path] : []
      Result.new(changes: changes,
                 changed_files: changed_files,
                 unsupported_specs: unsupported_specs,
                 missing_source_specs: missing_source_specs)
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
      missing_source_specs = []

      PACKAGE_SECTIONS.each do |section|
        dependencies = package_json_data[section]
        next unless dependencies.is_a?(Hash)

        PACKAGE_VERSION_SOURCES.each do |package_name, source_key|
          next unless dependencies.key?(package_name)

          current_version = dependencies[package_name]
          parsed_spec = parse_supported_spec(current_version)
          unless parsed_spec
            unsupported_specs << { section: section, package: package_name, version: current_version }
            next
          end

          expected_version = expected_versions[source_key]
          if expected_version.nil?
            missing_source_specs << { section: section, package: package_name, source: source_key }
            next
          end
          normalized_current_version = converter.rubygem_to_npm(parsed_spec[:version])
          next if normalized_current_version == expected_version

          changes << {
            section: section,
            package: package_name,
            from: current_version,
            to: rewritten_spec(parsed_spec, expected_version)
          }
        end
      end

      [changes, unsupported_specs, missing_source_specs]
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

    def print_summary(changes, unsupported_specs:, missing_source_specs:, write:)
      if changes.empty?
        print_no_changes_summary
      else
        print_changes_summary(changes, write: write)
      end

      print_unsupported_specs(unsupported_specs)
      return if missing_source_specs.empty?

      io.puts "Skipped packages whose source gem is not loaded:"
      missing_source_specs.each do |spec|
        io.puts "  - #{spec[:section]}.#{spec[:package]} (missing #{spec[:source]} gem)"
      end
    end

    def exact_version?(version)
      version.is_a?(String) && version.match?(EXACT_VERSION_REGEX)
    end

    def parse_supported_spec(version_spec)
      return { version: version_spec, prefix: nil } if exact_version?(version_spec)
      return unless version_spec.is_a?(String) && version_spec.start_with?(NPM_ALIAS_PREFIX)

      at_index = version_spec.rindex("@")
      # Ensure at least one package-name character appears after "npm:" and before the version separator.
      return unless at_index && at_index > NPM_ALIAS_PREFIX.length

      alias_version = version_spec[(at_index + 1)..]
      return unless exact_version?(alias_version)

      { version: alias_version, prefix: version_spec[0..at_index] }
    end

    def rewritten_spec(parsed_spec, expected_version)
      return expected_version unless parsed_spec[:prefix]

      "#{parsed_spec[:prefix]}#{expected_version}"
    end

    def write_atomically(content)
      tmp_path = "#{package_json_path}.tmp-#{Process.pid}-#{Thread.current.object_id}-#{SecureRandom.hex(4)}"
      File.write(tmp_path, content)
      File.rename(tmp_path, package_json_path)
    rescue StandardError => e
      raise ReactOnRails::Error, "Unable to write #{package_json_path}: #{e.message}"
    ensure
      # On success tmp_path no longer exists (it was renamed), so this is a no-op.
      # On failure, remove any partially-written temp file while preserving package_json_path.
      cleanup_tmp_file(tmp_path)
    end

    def lockfile_present?
      package_dir = File.dirname(package_json_path)
      %w[yarn.lock package-lock.json pnpm-lock.yaml bun.lock bun.lockb].any? do |lockfile_name|
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
        io.puts "Run your package manager install command to apply package.json updates."
        io.puts "Lockfiles may still pin previous versions until install completes." if lockfile_present?
        io.puts "Write mode reformats package.json and may normalize whitespace/newline layout."
        io.puts "For minified package.json files, indentation falls back to two spaces."
      else
        io.puts "Dry run only. Re-run with REACT_ON_RAILS_WRITE=true to apply changes."
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
    rescue SystemCallError => e
      warn "react_on_rails: could not remove temp file #{tmp_path}: #{e.message}"
    end

    def detect_indentation(content)
      normalized_content = content.gsub("\r\n", "\n")
      indentations = normalized_content.each_line.filter_map { |line| line.slice(/^[ \t]+(?="[^"\n]+":)/) }
      return "  " if indentations.empty?

      indentation = indentation_for_majority_char(indentations)
      indentation.nil? || indentation.empty? ? "  " : indentation
    end

    def indentation_for_majority_char(indentations)
      # Compare indentation widths within the dominant whitespace character class to avoid tabs
      # (length 1) always winning against space indentation.
      char = predominant_indent_char(indentations)
      same_char = indentations.select { |indentation| indentation.chars.uniq == [char] }
      (same_char.empty? ? indentations : same_char).min_by(&:length)
    end

    def predominant_indent_char(indentations)
      indentations.map { |indentation| indentation[0] }.tally.max_by { |_value, count| count }&.first || " "
    end
  end
  # rubocop:enable Metrics/ClassLength
end

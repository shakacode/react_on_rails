# frozen_string_literal: true

require "fileutils"
require "pathname"

ROOT = File.expand_path("..", __dir__)
GEM_LIB = File.join(ROOT, "react_on_rails", "lib")
$LOAD_PATH.unshift(GEM_LIB) unless $LOAD_PATH.include?(GEM_LIB)

# Keep generated SmartError examples stable regardless of the caller's shell.
ENV["RAILS_ENV"] = "development"

require "react_on_rails"

class ErrorReferenceGenerator
  OUTPUT_FILE = File.join(ROOT, "docs", "oss", "reference", "error-reference.md")
  REGENERATE_COMMAND = "BUNDLE_GEMFILE=react_on_rails/Gemfile bundle exec ruby script/generate_error_reference.rb"
  ANSI_ESCAPE = /\e\[[0-9;]*m/
  CODE_PATTERN = /\AROR\d{3}\z/
  REQUIRED_DEFINITION_KEYS = %i[code title summary sample_context].freeze

  def initialize(check_mode:)
    @check_mode = check_mode
    @failed = false
  end

  def run
    validate_definitions
    return 1 if @failed

    output = render

    if @check_mode
      check_output(output)
    else
      FileUtils.mkdir_p(File.dirname(OUTPUT_FILE))
      File.write(OUTPUT_FILE, output)
    end

    if @failed
      1
    else
      puts "✓ #{relative_output_file} #{@check_mode ? 'is current' : 'generated'}: " \
           "#{definitions.length} SmartError codes."
      0
    end
  end

  private

  def definitions
    ReactOnRails::SmartError.error_definitions
  end

  def ordered_definitions
    definitions.sort_by { |error_type, definition| [definition.fetch(:code, ""), error_type.to_s] }
  end

  def validate_definitions
    seen_codes = {}

    ordered_definitions.each do |error_type, definition|
      REQUIRED_DEFINITION_KEYS.each do |key|
        record_failure("#{error_type} is missing #{key}") unless definition.key?(key)
      end

      next unless definition.key?(:code)

      code = definition[:code]
      record_failure("#{error_type} has invalid code #{code.inspect}; expected ROR001-style format") unless
        code.is_a?(String) && CODE_PATTERN.match?(code)

      if seen_codes.key?(code)
        record_failure("#{error_type} reuses #{code}; already assigned to #{seen_codes.fetch(code)}")
      else
        seen_codes[code] = error_type
      end
    end
  end

  def render
    code_index_rows = []
    entries = []

    ordered_definitions.each do |error_type, definition|
      code_index_rows << [
        "[#{definition.fetch(:code)}](##{anchor_for(definition)})",
        definition.fetch(:title),
        "`:#{error_type}`"
      ]
      entries.concat(render_error_entry(error_type, definition))
    end

    parts = [
      "---",
      "title: Error Reference",
      "---",
      "",
      "<!-- GENERATED FILE - DO NOT EDIT DIRECTLY. -->",
      "<!-- Regenerate with: #{REGENERATE_COMMAND} -->",
      "<!-- Source: react_on_rails/lib/react_on_rails/smart_error.rb -->",
      "",
      "# Error Reference",
      "",
      "React on Rails SmartError messages include stable `ROR###` codes and canonical URLs. " \
      "Use this page to look up a code from a terminal error, server log, or support request.",
      "",
      "Error codes are append-only once published: do not reuse a removed code for a different failure.",
      "",
      "## Code Index",
      ""
    ]

    parts.concat(markdown_table(["Code", "Error", "SmartError type"], code_index_rows))
    parts.concat(entries)
    "#{parts.join("\n")}\n"
  end

  def markdown_table(headers, rows)
    widths = headers.each_index.map do |index|
      ([headers[index]] + rows.map { |row| row[index] }).map(&:length).max
    end

    [
      markdown_table_row(headers, widths),
      markdown_table_row(widths.map { |width| "-" * width }, widths),
      *rows.map { |row| markdown_table_row(row, widths) }
    ]
  end

  def markdown_table_row(cells, widths)
    "| #{cells.each_with_index.map { |cell, index| cell.ljust(widths[index]) }.join(' | ')} |"
  end

  def render_error_entry(error_type, definition)
    [
      "",
      %(<a id="#{anchor_for(definition)}"></a>),
      "",
      "## #{definition.fetch(:code)}: #{definition.fetch(:title)}",
      "",
      "**SmartError type:** `:#{error_type}`",
      "",
      "**Canonical URL:** #{ReactOnRails::SmartError.docs_url_for(error_type)}",
      "",
      definition.fetch(:summary),
      "",
      "### Example SmartError Output",
      "",
      "```text",
      example_message_for(error_type, definition),
      "```"
    ]
  end

  def example_message_for(error_type, definition)
    sample_context = definition.fetch(:sample_context)
    error = ReactOnRails::SmartError.new(error_type:, **sample_context)

    strip_ansi(error.message)
      .lines
      .map(&:rstrip)
      .join("\n")
  end

  def strip_ansi(message)
    message.gsub(ANSI_ESCAPE, "")
  end

  def anchor_for(definition)
    definition.fetch(:code).downcase
  end

  def check_output(output)
    existing = File.exist?(OUTPUT_FILE) ? File.read(OUTPUT_FILE) : ""
    return if existing == output

    record_failure("#{relative_output_file} is stale. Run `#{REGENERATE_COMMAND}` and commit the result.")
  end

  def relative_output_file
    Pathname.new(OUTPUT_FILE).relative_path_from(Pathname.new(ROOT)).to_s
  end

  def record_failure(message)
    warn "✗ #{message}"
    @failed = true
  end
end

def usage
  warn "Usage: #{ErrorReferenceGenerator::REGENERATE_COMMAND} [--check]"
  1
end

args = ARGV.dup
check_mode = args.delete("--check")
exit(usage) unless args.empty?

exit(ErrorReferenceGenerator.new(check_mode: !check_mode.nil?).run)

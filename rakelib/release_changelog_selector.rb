# frozen_string_literal: true

module ReleaseChangelogSelector
  UNRELEASED_HEADING = /^### \[Unreleased\]\s*$/
  VERSION_HEADING = /^### \[([^\]]+)\]/

  module_function

  def prepared_version(lines, version_pattern:)
    unreleased_index = lines.index { |line| line.match?(UNRELEASED_HEADING) }
    return unless unreleased_index

    version_index = ((unreleased_index + 1)...lines.length).find { |index| !lines.fetch(index).strip.empty? }
    return unless version_index

    version = version_from_heading(lines.fetch(version_index))
    return unless version && version_pattern.match?(version)
    return unless releasable_section?(lines, version_index)

    version
  end

  def version_from_heading(line)
    line.match(VERSION_HEADING)&.[](1)&.strip
  end

  def releasable_section?(lines, version_index)
    section_end = ((version_index + 1)...lines.length).find { |index| lines[index].start_with?("### [") }
    section_lines = lines[(version_index + 1)...(section_end || lines.length)]
    section_lines.any? { |line| !line.strip.empty? && !line.start_with?("#") }
  end
end

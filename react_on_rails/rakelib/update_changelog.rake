# frozen_string_literal: true

require "date"
require "English"
require "bundler"
require "open3"
require_relative "task_helpers"

CLAUDE_CODE_TIP = <<~TIP
  ┌─────────────────────────────────────────────────────────────────────────────┐
  │ TIP: This task adds version headers and links, not changelog entry text.   │
  │ For full commit analysis + entry writing, run /update-changelog in Claude. │
  │                                                                             │
  │ After running this task, manually add entries under the new header:        │
  │   #### Fixed / #### Added / #### Changed / etc.                            │
  └─────────────────────────────────────────────────────────────────────────────┘
TIP

def monorepo_root_for_changelog
  File.expand_path("../..", __dir__)
end

def prerelease_version?(version)
  version.to_s.match?(/\.(test|beta|alpha|rc|pre)\./i)
end

def normalize_version_string(version_or_tag)
  version = version_or_tag.to_s.strip
  version = version.delete_prefix("v")
  version = version.sub(/-(test|beta|alpha|rc|pre)\./i, '.\1.')

  unless version.match?(/\A\d+\.\d+\.\d+(\.(test|beta|alpha|rc|pre)\.\d+)?\z/i)
    abort "Failed to parse version from #{version_or_tag.inspect}. Expected format like 16.4.0 or 16.4.0.rc.1."
  end

  version.downcase
end

def parse_release_tag_to_version(tag)
  version_pattern = /\d+\.\d+\.\d+(?:\.(?:test|beta|alpha|rc|pre)\.\d+)?|\d+\.\d+\.\d+-(?:test|beta|alpha|rc|pre)\.\d+/
  tag_match = tag.to_s.strip.match(/\Av(?<version>#{version_pattern})\z/i)
  return nil unless tag_match

  normalize_version_string(tag_match[:version])
rescue SystemExit
  nil
end

def fetch_git_tags!(monorepo_root)
  remotes_output, remotes_status = Open3.capture2e("git", "-C", monorepo_root, "remote")
  abort "Failed to list git remotes.\n#{remotes_output}" unless remotes_status.success?

  remote_names = remotes_output.lines.map(&:strip).reject(&:empty?)
  return if remote_names.empty?

  remote_name = remote_names.include?("origin") ? "origin" : remote_names.first
  fetch_output, fetch_status = Open3.capture2e("git", "-C", monorepo_root, "fetch", remote_name, "--tags", "--quiet")
  abort "Failed to fetch git tags from #{remote_name}.\n#{fetch_output}" unless fetch_status.success?
end

def tag_versions(monorepo_root)
  tags_output, status = Open3.capture2e("git", "-C", monorepo_root, "tag", "-l", "v*")
  abort "Failed to list git tags.\n#{tags_output}" unless status.success?

  tags_output.lines.map(&:strip).filter_map { |tag| parse_release_tag_to_version(tag) }.uniq
end

def stable_tag_versions(monorepo_root)
  tag_versions(monorepo_root).reject { |version| prerelease_version?(version) }
end

def latest_stable_tag_version(monorepo_root)
  versions = stable_tag_versions(monorepo_root)
  abort "Failed to compute latest stable tag: no stable v* tags found." if versions.empty?

  versions.max_by { |version| Gem::Version.new(version) }
end

def extract_unreleased_section(changelog)
  lines = changelog.lines
  start_index = lines.index { |line| line.start_with?("### [Unreleased]") }
  abort "Failed to find '### [Unreleased]' in CHANGELOG.md" unless start_index

  end_index = ((start_index + 1)...lines.length).find { |idx| lines[idx].start_with?("### [") } || lines.length
  lines[start_index...end_index].join
end

def inferred_bump_type_from_unreleased(changelog)
  section = extract_unreleased_section(changelog)
  return :major if section.match?(/^####\s+(?:⚠️\s*)?Breaking(?:\s+Changes?)?\b/i)
  return :minor if section.match?(/^####\s+(Added|New\s+Features?|Features?|Enhancements?)\b/i)
  return :patch if section.match?(/^####\s+(Fixed|Fixes|Bug\s+Fixes?|Security|Improved|Changed|Deprecated|Removed)\b/i)

  :patch
end

def bump_stable_version(version, bump_type)
  match = version.match(/\A(\d+)\.(\d+)\.(\d+)\z/)
  abort "Failed to bump version: stable version #{version.inspect} is invalid." unless match

  major = match[1].to_i
  minor = match[2].to_i
  patch = match[3].to_i

  case bump_type
  when :major
    "#{major + 1}.0.0"
  when :minor
    "#{major}.#{minor + 1}.0"
  else
    "#{major}.#{minor}.#{patch + 1}"
  end
end

def prerelease_indices_from_tags(monorepo_root, base_version, channel)
  tags_output, status = Open3.capture2e("git", "-C", monorepo_root, "tag", "-l", "v#{base_version}*")
  abort "Failed to list prerelease tags.\n#{tags_output}" unless status.success?

  tags_output.lines.map(&:strip).filter_map do |tag|
    normalized_version = parse_release_tag_to_version(tag)
    match = normalized_version&.match(/\A#{Regexp.escape(base_version)}\.#{channel}\.(\d+)\z/i)
    match&.captures&.first&.to_i
  end
end

def prerelease_indices_from_changelog(changelog, base_version, channel)
  changelog.scan(/^### \[#{Regexp.escape(base_version)}\.#{channel}\.(\d+)\]/i).flatten.map(&:to_i)
end

def parse_changelog_sections(changelog)
  lines = changelog.lines
  headers = []
  lines.each_with_index do |line, index|
    match = line.match(/^### \[([^\]]+)\].*$/)
    headers << { index: index, version: match[1], header: line } if match
  end

  return { prefix: changelog, sections: [] } if headers.empty?

  prefix = lines[0...headers.first[:index]].join
  sections = headers.each_with_index.map do |header, section_index|
    section_end = if section_index + 1 < headers.length
                    headers[section_index + 1][:index]
                  else
                    lines.length
                  end

    {
      version: header[:version],
      header: header[:header],
      body: lines[(header[:index] + 1)...section_end].join
    }
  end

  { prefix: prefix, sections: sections }
end

def render_changelog_sections(prefix, sections)
  "#{prefix}#{sections.map { |section| "#{section[:header]}#{section[:body]}" }.join}"
end

def changelog_versions(changelog)
  parse_changelog_sections(changelog)[:sections]
    .map { |section| section[:version] }
    .reject { |version| version == "Unreleased" }
    .map { |version| normalize_version_string(version) }
end

def prerelease_base_version(version)
  version.to_s.sub(/\.(test|beta|alpha|rc|pre)\.\d+\z/i, "")
end

def active_prerelease_base_version(monorepo_root, changelog)
  latest_stable = latest_stable_tag_version(monorepo_root)
  prerelease_bases = (tag_versions(monorepo_root) + changelog_versions(changelog))
                     .uniq
                     .select { |version| prerelease_version?(version) }
                     .map { |version| prerelease_base_version(version) }
                     .select do |base_version|
                       Gem::Version.new(base_version) > Gem::Version.new(latest_stable)
                     end
                     .uniq

  prerelease_bases.max_by { |base_version| Gem::Version.new(base_version) }
end

def collapse_prerelease_series(changelog, base_version)
  %w[test beta alpha rc pre].reduce(changelog) do |current_changelog, channel|
    collapse_prerelease_sections(current_changelog, base_version, channel)
  end
end

def prepare_changelog_for_auto_version(changelog, monorepo_root)
  active_base_version = active_prerelease_base_version(monorepo_root, changelog)
  return changelog unless active_base_version

  changelog = collapse_prerelease_series(changelog, active_base_version)
  cleanup_collapsed_prerelease_links(changelog, active_base_version)
end

# After collapsing prerelease sections, remove their orphaned compare links
# and update [unreleased] to compare from the last stable version.
def cleanup_collapsed_prerelease_links(changelog, base_version)
  compare_prefix = Regexp.escape("https://github.com/shakacode/react_on_rails/compare/")
  prerelease_pattern = /#{Regexp.escape(base_version)}\.(?:test|beta|alpha|rc|pre)\.\d+/i

  # Find the "from" version in prerelease links that points to a non-prerelease (stable) version
  stable_from = nil
  changelog.scan(/^\[#{prerelease_pattern}\]:\s*#{compare_prefix}(\S+)\.\.\./i) do |from_version,|
    stable_from = from_version unless from_version.delete_prefix("v").match?(prerelease_pattern)
  end

  if stable_from
    # Update [unreleased] link to compare from the stable version instead of the old prerelease
    changelog = changelog.sub(
      /^(\[unreleased\]:\s*#{compare_prefix})\S+(\.\.\.master)/i,
      "\\1#{stable_from}\\2"
    )
  end

  # Remove all prerelease compare link lines for this base version
  changelog.gsub(/^\[#{prerelease_pattern}\]:.*\n/i, "")
end

def changelog_section_blocks(section_body)
  block_lines = []
  blocks = []

  section_body.lines.each do |line|
    normalized_line = line.rstrip
    if normalized_line.match?(/^####+\s+/) && !block_lines.empty?
      blocks << normalize_changelog_block(block_lines)
      block_lines = [normalized_line]
    else
      block_lines << normalized_line
    end
  end

  blocks << normalize_changelog_block(block_lines) unless block_lines.empty?
  blocks.reject(&:empty?)
end

def normalize_changelog_block(lines)
  normalized_lines = lines.map(&:rstrip)
  normalized_lines.shift while normalized_lines.first == ""
  normalized_lines.pop while normalized_lines.last == ""
  normalized_lines.join("\n")
end

def normalize_heading_key(line)
  normalized = line.to_s.strip
  heading_level = normalized[/\A(#+)/, 1] || ""
  heading_text = normalized.sub(/\A#+\s+/, "")
                           .gsub(/\A(?:⚠️|⚠)\s*/, "")
                           .downcase
                           .gsub(/\s+/, " ")
  "#{heading_level} #{heading_text}".strip
end

# Merge an array of changelog blocks so that blocks with the same heading
# (e.g. two "#### Fixed" blocks) are combined into one.  Header-only blocks
# like "#### Pro" are kept at their first-seen position, ensuring they remain
# as parent headings for any ##### sub-sections that follow.
# Also strips the "Changes since the last non-beta release." marker text
# and deduplicates entries that share the same PR number.
# rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
def consolidate_changelog_blocks(blocks)
  consolidated = []
  heading_indices = {}

  blocks.each do |block|
    cleaned = block.gsub(/\n*Changes since the last non-beta release\.\s*/, "\n").strip
    next if cleaned.empty?

    first_line = cleaned.lines.first&.rstrip || ""
    heading_match = first_line.match(/\A(####+\s+.+)/)

    if heading_match
      heading_key = normalize_heading_key(heading_match[1])

      if heading_indices.key?(heading_key)
        # Append this block's content (lines after heading) to existing block
        idx = heading_indices[heading_key]
        content_after_heading = cleaned.lines.drop(1).join.gsub(/\A\n+/, "").rstrip
        consolidated[idx] = "#{consolidated[idx].rstrip}\n#{content_after_heading}" unless content_after_heading.empty?
      else
        heading_indices[heading_key] = consolidated.length
        consolidated << cleaned
      end
    else
      # Keep non-heading prose blocks (for example explanatory text). Marker-only
      # blocks are already stripped by the cleanup + empty guard above.
      consolidated << cleaned
    end
  end

  # Deduplicate entries within each block by PR number
  consolidated.map { |block| deduplicate_block_entries(block) }
end
# rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

# Remove duplicate changelog entries within a single block.
# Entries are deduplicated by normalized text content — two entries are
# considered duplicates only when their text is identical (ignoring
# leading/trailing whitespace).  This preserves distinct entries that
# share the same PR number (e.g. multiple fixes in one PR).
# Multi-line entries (continuation lines not starting with "- ") are
# kept together with their parent entry.
# rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
def deduplicate_block_entries(block)
  lines = block.lines
  first_line = lines.first&.rstrip || ""
  return block unless first_line.match?(/\A####+\s+/)

  # Split into heading + entries
  heading = first_line
  body_lines = lines.drop(1)

  # Group body lines into logical entries.
  # Only top-level "- " lines start new entries; nested bullets belong to the
  # current entry body.
  # Keep ##### subheadings attached to the next bullet so deduplication drops
  # both together when a duplicate PR is removed.
  entries = []
  pending_subheading = +""
  current_entry = nil

  body_lines.each do |line|
    next if line.strip.empty? && entries.empty? && pending_subheading.empty? && current_entry.nil?

    if line.match?(/\A#####\s+/)
      entries << current_entry if current_entry
      current_entry = nil
      pending_subheading << line
    elsif line.start_with?("- ")
      entries << current_entry if current_entry
      current_entry = +"#{pending_subheading}#{line}"
      pending_subheading = +""
    elsif current_entry
      current_entry << line
    elsif pending_subheading.empty?
      # Keep free-form prose lines as standalone entries.
      entries << line
    else
      pending_subheading << line
    end
  end

  entries << current_entry if current_entry
  entries << pending_subheading unless pending_subheading.empty?

  # Deduplicate by full entry text (keep first occurrence).
  # This preserves distinct entries that share the same PR number.
  seen_texts = {}
  unique_entries = entries.select do |entry|
    key = entry.strip
    if key.empty?
      true
    elsif seen_texts.key?(key)
      false
    else
      seen_texts[key] = true
      true
    end
  end

  "#{heading}\n#{unique_entries.join}"
end
# rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

# rubocop:disable Metrics/AbcSize
def collapse_prerelease_sections(changelog, base_version, channel)
  parsed = parse_changelog_sections(changelog)
  sections = parsed[:sections]
  unreleased_section = sections.find { |section| section[:version] == "Unreleased" }
  return changelog unless unreleased_section

  target_regex = /\A#{Regexp.escape(base_version)}\.#{channel}\.\d+\z/i
  matching_sections = sections.select { |section| section[:version].match?(target_regex) }
  return changelog if matching_sections.empty?

  # Collect blocks from Unreleased first, then prerelease sections.
  # Unreleased blocks come first so they are the "first seen" for each heading,
  # and prerelease content is appended to them (Unreleased is newer).
  all_blocks = changelog_section_blocks(unreleased_section[:body]) +
               matching_sections.flat_map { |section| changelog_section_blocks(section[:body]) }

  # Merge blocks with the same heading instead of simple .uniq
  consolidated = consolidate_changelog_blocks(all_blocks)
  merged_body = consolidated.join("\n\n").strip

  sections.reject! { |section| section[:version].match?(target_regex) }
  unreleased_section[:body] = merged_body.empty? ? "\n" : "\n\n#{merged_body}\n"

  render_changelog_sections(parsed[:prefix], sections)
end
# rubocop:enable Metrics/AbcSize

def compute_auto_version(changelog, mode, monorepo_root, changelog_for_bump: nil)
  # Keep backward compatibility with older callers that pass changelog_for_bump
  # as a keyword while allowing the new 3-argument call shape.
  changelog_for_bump ||= changelog
  bump_type = inferred_bump_type_from_unreleased(changelog_for_bump)
  latest_stable = latest_stable_tag_version(monorepo_root)
  base_version = bump_stable_version(latest_stable, bump_type)

  return base_version if mode == "release"

  # Only use git tags to determine the next prerelease index.
  # Changelog headers are drafts that may not have been released yet —
  # git tags are the authoritative source of shipped versions.
  indices = prerelease_indices_from_tags(monorepo_root, base_version, mode)
  next_index = indices.empty? ? 0 : indices.max + 1
  "#{base_version}.#{mode}.#{next_index}"
end

def fetch_git_tag_date(monorepo_root, git_tag)
  output, status = Open3.capture2e("git", "-C", monorepo_root, "show", "-s", "--format=%cs", git_tag)
  return nil unless status.success?

  output.split("\n").last&.strip
end

# Update the compare links at the bottom of the changelog
# version: version string without 'v' prefix (e.g., "16.2.0.beta.20")
# anchor: markdown anchor (e.g., "[16.2.0.beta.20]")
def update_changelog_links(changelog, version, anchor)
  compare_link_prefix = "https://github.com/shakacode/react_on_rails/compare"
  match_data = %r{#{compare_link_prefix}/(?<prev_version>.*)\.\.\.master}.match(changelog)
  return unless match_data

  prev_version = match_data[:prev_version]
  new_unreleased_link = "#{compare_link_prefix}/v#{version}...master"
  new_version_link = "#{anchor}: #{compare_link_prefix}/#{prev_version}...v#{version}"
  changelog.sub!(match_data[0], "#{new_unreleased_link}\n#{new_version_link}")
end

# Insert version header into changelog, returns true if successful
def insert_version_header(changelog, anchor, tag_date)
  # Try inserting right after ### [Unreleased] first
  return true if changelog.sub!("### [Unreleased]", "### [Unreleased]\n\n### #{anchor} - #{tag_date}")

  # Fallback: insert after "Changes since the last non-beta release."
  return true if changelog.sub!("Changes since the last non-beta release.", "\\0\n\n### #{anchor} - #{tag_date}")

  false
end

desc "Updates CHANGELOG.md by inserting a version header and compare links.
Argument: Mode (`release`, `rc`, `beta`) or explicit git tag/version.

Modes:
  - release: auto-compute next stable version from Unreleased section headings
  - rc: auto-compute next RC version and collapse prior RC sections of same base version
  - beta: auto-compute next beta version and collapse prior beta sections of same base version

Explicit argument examples:
  - v16.4.0.rc.6
  - 16.4.0.rc.6

No argument: use latest git tag.
TIP: Use /update-changelog in Claude Code for full automation."

# rubocop:disable Metrics/BlockLength
task :update_changelog, %i[mode_or_tag] do |_, args|
  puts CLAUDE_CODE_TIP

  monorepo_root = monorepo_root_for_changelog
  changelog_path = File.join(monorepo_root, "CHANGELOG.md")
  changelog = File.read(changelog_path)
  input = args[:mode_or_tag].to_s.strip
  auto_mode = %w[release rc beta].find { |mode| mode == input.downcase }

  if auto_mode
    fetch_git_tags!(monorepo_root)
    prepared_changelog = prepare_changelog_for_auto_version(changelog, monorepo_root)
    changelog_version = compute_auto_version(prepared_changelog, auto_mode, monorepo_root)
    changelog = prepared_changelog
    tag_date = Date.today.strftime("%Y-%m-%d")
    puts "Auto-computed #{auto_mode} version: #{changelog_version}"
  else
    git_tag = if input.empty?
                git_output, git_status = Open3.capture2e("git", "-C", monorepo_root, "describe", "--tags", "--abbrev=0")
                abort "Failed to get latest git tag.\n#{git_output}" unless git_status.success?
                git_output.strip
              else
                input
              end

    changelog_version = normalize_version_string(git_tag)
    tag_candidates = [git_tag, git_tag.start_with?("v") ? git_tag : "v#{git_tag}", "v#{changelog_version}"].uniq
    tag_date = tag_candidates.filter_map { |candidate| fetch_git_tag_date(monorepo_root, candidate) }.first ||
               Date.today.strftime("%Y-%m-%d")
  end

  anchor = "[#{changelog_version}]"
  header = "### #{anchor}"
  if changelog.include?(header)
    puts "Version #{changelog_version} is already documented in CHANGELOG.md"
    next
  end

  unless insert_version_header(changelog, anchor, tag_date)
    abort("Failed to insert version header: could not find '### [Unreleased]' " \
          "or 'Changes since the last non-beta release.' in CHANGELOG.md")
  end

  update_changelog_links(changelog, changelog_version, anchor)

  File.write(changelog_path, changelog)
  puts "Updated CHANGELOG.md with version header for #{changelog_version}"
  puts "NOTE: You still need to write the changelog entries manually."
end
# rubocop:enable Metrics/BlockLength

# frozen_string_literal: true

require "English"
require "bundler"
require_relative "task_helpers"

CLAUDE_CODE_TIP = <<~TIP
  ┌─────────────────────────────────────────────────────────────────────────────┐
  │ TIP: This task only adds version headers and links, not changelog entries. │
  │ For full automation, run /update-changelog in Claude Code.                 │
  └─────────────────────────────────────────────────────────────────────────────┘
TIP

def update_changelog_links(changelog, tag, anchor)
  compare_link_prefix = "https://github.com/shakacode/react_on_rails/compare"
  match_data = %r{#{compare_link_prefix}/(?<prev_tag>.*)\.\.\.master}.match(changelog)
  return unless match_data

  prev_tag = match_data[:prev_tag]
  new_unreleased_link = "#{compare_link_prefix}/#{tag}...master"
  new_tag_link = "#{anchor}: #{compare_link_prefix}/#{prev_tag}...#{tag}"
  changelog.sub!(match_data[0], "#{new_unreleased_link}\n#{new_tag_link}")
end

# Find the most recent version from the changelog (beta or stable)
# Returns nil if no version is found
def find_most_recent_version(changelog)
  # Match version headers like "### [16.2.0.beta.19] - 2025-12-10" or "### [16.1.1] - 2025-09-24"
  version_pattern = /^### \[([^\]]+)\] - \d{4}-\d{2}-\d{2}/
  match = changelog.match(version_pattern)
  match ? match[1] : nil
end

desc "Updates CHANGELOG.md inserting headers for the new version (headers only, not content).
Argument: Git tag. Defaults to the latest tag.
TIP: Use /update-changelog in Claude Code for full automation."

task :update_changelog, %i[tag] do |_, args|
  puts CLAUDE_CODE_TIP

  tag = args[:tag] || `git describe --tags --abbrev=0`.strip
  anchor = "[#{tag}]"
  changelog = File.read("CHANGELOG.md")

  if changelog.include?(anchor)
    puts "Tag #{tag} is already documented in CHANGELOG.md"
    next
  end

  tag_date = `git show -s --format=%cs #{tag} 2>&1`.split("\n").last&.strip
  abort("Failed to find tag #{tag}") unless $CHILD_STATUS.success? && tag_date

  most_recent_version = find_most_recent_version(changelog)
  header_inserted = false

  if most_recent_version
    # Insert the new version header right after ### [Unreleased]
    # This works for both beta→beta and stable→beta transitions
    if changelog.sub!("### [Unreleased]", "### [Unreleased]\n\n### #{anchor} - #{tag_date}")
      header_inserted = true
    end
  end

  unless header_inserted
    # Fallback: insert after "Changes since the last non-beta release." if no version found
    # or if ### [Unreleased] was not found
    if changelog.sub!("Changes since the last non-beta release.", "\\0\n\n### #{anchor} - #{tag_date}")
      header_inserted = true
    end
  end

  unless header_inserted
    abort("Failed to insert version header: could not find '### [Unreleased]' or 'Changes since the last non-beta release.' in CHANGELOG.md")
  end

  update_changelog_links(changelog, tag, anchor)

  File.write("CHANGELOG.md", changelog)
  puts "Updated CHANGELOG.md with version header for #{tag}"
  puts "NOTE: You still need to write the changelog entries manually."
end

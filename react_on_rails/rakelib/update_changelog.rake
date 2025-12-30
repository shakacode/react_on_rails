# frozen_string_literal: true

require "English"
require "bundler"
require_relative "task_helpers"

CLAUDE_CODE_TIP = <<~TIP
  ┌─────────────────────────────────────────────────────────────────────────────┐
  │ TIP: This task only adds version headers and links, not changelog entries. │
  │ For full automation, run /update-changelog in Claude Code.                 │
  │                                                                             │
  │ After running this task, manually add entries under the new header:        │
  │   #### Fixed / #### Added / #### Changed / etc.                            │
  └─────────────────────────────────────────────────────────────────────────────┘
TIP

# Update the compare links at the bottom of the changelog
# version: version string without 'v' prefix (e.g., "16.2.0.beta.20")
# anchor: markdown anchor (e.g., "[16.2.0.beta.20]")
def update_changelog_links(changelog, version, anchor)
  compare_link_prefix = "https://github.com/shakacode/react_on_rails/compare"
  match_data = %r{#{compare_link_prefix}/(?<prev_version>.*)\.\.\.master}.match(changelog)
  return unless match_data

  prev_version = match_data[:prev_version]
  new_unreleased_link = "#{compare_link_prefix}/#{version}...master"
  new_version_link = "#{anchor}: #{compare_link_prefix}/#{prev_version}...#{version}"
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

desc "Updates CHANGELOG.md inserting headers for the new version (headers only, not content).
Argument: Git tag. Defaults to the latest tag.
TIP: Use /update-changelog in Claude Code for full automation."

task :update_changelog, %i[tag] do |_, args|
  puts CLAUDE_CODE_TIP

  # Git tags may have 'v' prefix (historical tags) - strip it for CHANGELOG
  git_tag = args[:tag] || `git describe --tags --abbrev=0`.strip
  changelog_version = git_tag.delete_prefix("v")
  anchor = "[#{changelog_version}]"
  changelog = File.read("CHANGELOG.md")

  if changelog.include?(anchor)
    puts "Tag #{git_tag} is already documented in CHANGELOG.md"
    next
  end

  tag_date = `git show -s --format=%cs #{git_tag} 2>&1`.split("\n").last&.strip
  abort("Failed to find tag #{git_tag}") unless $CHILD_STATUS.success? && tag_date

  unless insert_version_header(changelog, anchor, tag_date)
    abort("Failed to insert version header: could not find '### [Unreleased]' " \
          "or 'Changes since the last non-beta release.' in CHANGELOG.md")
  end

  update_changelog_links(changelog, changelog_version, anchor)

  File.write("CHANGELOG.md", changelog)
  puts "Updated CHANGELOG.md with version header for #{git_tag}"
  puts "NOTE: You still need to write the changelog entries manually."
end

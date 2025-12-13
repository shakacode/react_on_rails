# frozen_string_literal: true

require "English"
require "bundler"
require_relative "task_helpers"

CLAUDE_CODE_TIP = <<~TIP

  ┌─────────────────────────────────────────────────────────────────────────────┐
  │ TIP: This task only adds version headers and links, not changelog entries. │
  │                                                                             │
  │ For full changelog automation, use Claude Code:                             │
  │   Run /update-changelog to analyze commits, write entries, and create a PR │
  └─────────────────────────────────────────────────────────────────────────────┘

TIP

desc "Updates CHANGELOG.md inserting headers for the new version (headers only, not content).

Argument: Git tag. Defaults to the latest tag.

TIP: For a better experience, use the /update-changelog command in Claude Code.
     It will analyze commits, write changelog entries, and create a PR automatically."

task :update_changelog, %i[tag] do |_, args|
  puts CLAUDE_CODE_TIP

  tag = args[:tag] || `git describe --tags --abbrev=0`.strip
  anchor = "[#{tag}]"

  changelog = File.read("CHANGELOG.md")

  if changelog.include?(anchor)
    puts "Tag #{tag} is already documented in CHANGELOG.md, update manually if needed"
    next
  end

  tag_date_output = `git show -s --format=%cs #{tag} 2>&1`
  if $CHILD_STATUS.success?
    tag_date = tag_date_output.split("\n").last.strip
  else
    abort("Failed to find tag #{tag}")
  end

  # after "Changes since the last non-beta release.", insert link header
  changelog.sub!("Changes since the last non-beta release.", "\\0\n\n### #{anchor} - #{tag_date}")

  # find the link in "[Unreleased]: ...", update it, and add the link for our new tag after it
  compare_link_prefix = "https://github.com/shakacode/react_on_rails/compare"
  match_data = %r{#{compare_link_prefix}/(?<prev_tag>.*)\.\.\.master}.match(changelog)
  if match_data
    prev_tag = match_data[:prev_tag]
    new_unreleased_link = "#{compare_link_prefix}/#{tag}...master"
    new_tag_link = "#{anchor}: #{compare_link_prefix}/#{prev_tag}...#{tag}"
    changelog.sub!(match_data[0], "#{new_unreleased_link}\n#{new_tag_link}")
  end

  File.write("CHANGELOG.md", changelog)
  puts "Updated CHANGELOG.md with version header for #{tag}"
  puts "NOTE: You still need to write the changelog entries manually."
end

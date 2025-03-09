# frozen_string_literal: true

require "bundler"
require_relative "task_helpers"

desc "Updates CHANGELOG.md inserting headers for the new version.

Argument: Git tag. Defaults to the latest tag."

task :update_changelog, %i[tag] do |_, args|
  tag = args[:tag] || `git describe --tags --abbrev=0`.strip
  anchor = "[#{tag}]"

  changelog = File.read("CHANGELOG.md")

  if changelog.include?(anchor)
    puts "Tag #{tag} already documented in CHANGELOG.md"
    next
  end

  tag_date_output = `git show -s --format=%cs #{tag} 2>&1`
  if $?.success?
    tag_date = tag_date_output.split("\n").last.strip
  else
    puts "Failed to find the tag: #{tag_date_output}"
    next
  end

  # after "Changes since the last non-beta release.", insert link header
  changelog.sub!("Changes since the last non-beta release.", "\\0\n\n## #{anchor} - #{tag_date}")

  # find the link in "[Unreleased]: ...", update it, and add the link for our new tag after it
  match_data = %r{https://github.com/shakacode/react_on_rails/compare/(?<prev_tag>.*)\.\.\.master}.match(changelog)
  if match_data
    prev_tag = match_data[:prev_tag]
    new_unreleased_link = "https://github.com/shakacode/react_on_rails/compare/#{tag}...master"
    new_tag_link = "#{anchor}: https://github.com/shakacode/react_on_rails/compare/#{prev_tag}...#{tag}"
    changelog.sub!(match_data[0], "#{new_unreleased_link}\n#{new_tag_link}")
  end

  File.write("CHANGELOG.md", changelog)
end

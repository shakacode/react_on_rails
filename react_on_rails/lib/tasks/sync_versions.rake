# frozen_string_literal: true

require_relative "../react_on_rails"

namespace :react_on_rails do
  desc "Sync React on Rails npm package versions with gem versions (dry-run by default)"
  task :sync_versions do
    write = ENV["WRITE"] == "true"
    dry_run = ENV["DRY_RUN"] == "true"

    raise ReactOnRails::Error, "WRITE and DRY_RUN cannot both be true" if write && dry_run

    ReactOnRails::VersionSynchronizer.new.sync(write: write)
  end
end

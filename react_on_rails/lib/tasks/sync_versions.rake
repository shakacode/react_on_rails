# frozen_string_literal: true

require_relative "../react_on_rails"
require_relative "../react_on_rails/version_synchronizer"

namespace :react_on_rails do
  desc "Sync React on Rails npm package versions with gem versions (dry-run by default; WRITE=true applies changes)"
  task :prepare_sync_versions do
    ENV["REACT_ON_RAILS_SKIP_VALIDATION"] = "true" if ENV["REACT_ON_RAILS_SKIP_VALIDATION"].nil?
  end

  task sync_versions: %i[prepare_sync_versions environment] do
    write = ENV["WRITE"] == "true"
    # DRY_RUN=true is an explicit alias for default dry-run behavior.
    # It has no effect unless WRITE=true would otherwise apply.
    dry_run = ENV["DRY_RUN"] == "true"

    raise ReactOnRails::Error, "WRITE and DRY_RUN cannot both be true" if write && dry_run

    ReactOnRails::VersionSynchronizer.new.sync(write: write)
  end
end

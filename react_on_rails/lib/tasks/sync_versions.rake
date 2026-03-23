# frozen_string_literal: true

require_relative "../react_on_rails"
require_relative "../react_on_rails/version_synchronizer"

namespace :react_on_rails do
  task :prepare_sync_versions do
    ENV["REACT_ON_RAILS_SKIP_VALIDATION"] = "true"
  end

  desc "Sync package.json versions with gem versions (dry-run by default; " \
       "REACT_ON_RAILS_WRITE=true (or WRITE=true) writes and may reformat package.json; " \
       "REACT_ON_RAILS_DRY_RUN=true (or DRY_RUN=true) forces dry-run mode)"
  task sync_versions: %i[prepare_sync_versions environment] do
    write = ENV.fetch("REACT_ON_RAILS_WRITE", ENV.fetch("WRITE", "false")) == "true"
    # Also accept shorter WRITE/DRY_RUN aliases.
    dry_run = ENV.fetch("REACT_ON_RAILS_DRY_RUN", ENV.fetch("DRY_RUN", "false")) == "true"

    raise ReactOnRails::Error, "WRITE and DRY_RUN cannot both be true" if write && dry_run

    ReactOnRails::VersionSynchronizer.new.sync(write: write)
  end
end

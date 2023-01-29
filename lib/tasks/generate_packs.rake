# frozen_string_literal: true

namespace :react_on_rails do
  desc <<~DESC
    If there is a file inside any directory matching config.components_subdirectory, this command generates corresponding packs.
  DESC

  task generate_packs: :environment do
    ReactOnRails::PacksGenerator.instance.generate_packs_if_stale
  end
end

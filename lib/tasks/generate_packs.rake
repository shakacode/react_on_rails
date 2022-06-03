# frozen_string_literal: true

namespace :react_on_rails do
  desc <<~DESC
    If there is a jsx file inside config.components_directory, this command generates corresponding packs and#{' '}
    registers the component for usage with react_component_with_bundle helper.
  DESC

  task generate_packs: :environment do
    ReactOnRails::PacksGenerator.generate
  end
end

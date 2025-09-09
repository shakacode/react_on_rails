# frozen_string_literal: true

namespace :react_on_rails do
  desc <<~DESC
    If there is a file inside any directory matching config.components_subdirectory, this command generates corresponding packs.
    
    This task will:
    - Clean out existing generated directories (javascript/generated and javascript/packs/generated)
    - List all files being deleted for transparency
    - Generate new pack files for discovered React components
    - Skip generation if files are already up to date
    
    Generated directories:
    - app/javascript/packs/generated/ (client pack files)
    - app/javascript/generated/ (server bundle files)
  DESC

  task generate_packs: :environment do
    puts Rainbow("🚀 Starting React on Rails pack generation...").bold
    puts Rainbow("📁 Auto-load bundle: #{ReactOnRails.configuration.auto_load_bundle}").cyan
    puts Rainbow("📂 Components subdirectory: #{ReactOnRails.configuration.components_subdirectory}").cyan
    puts ""
    
    start_time = Time.now
    ReactOnRails::PacksGenerator.instance.generate_packs_if_stale
    end_time = Time.now
    
    puts ""
    puts Rainbow("✨ Pack generation completed in #{((end_time - start_time) * 1000).round(1)}ms").green
  end
end

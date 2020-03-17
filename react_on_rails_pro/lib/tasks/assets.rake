# frozen_string_literal: true

require "active_support"

Rake::Task["assets:precompile"].enhance do
  Rake::Task["react_on_rails_pro:copy_assets_to_vm_renderer"].invoke
end

namespace :react_on_rails_pro do
  desc "Copy assets to remote vm-renderer"
  task copy_assets_to_vm_renderer: :environment do
    unless ReactOnRailsPro.configuration.renderer_url.include?("localhost")
      Rails.logger.info { "[ReactOnRailsPro] Copying assets to remote vm-renderer..." }
      ReactOnRailsPro::Utils.copy_assets
    else
      puts "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
      puts "assets.rake: #{__LINE__},  method: #{__method__}"
      puts "[ReactOnRailsPro] Skip copying assets to vm-renderer. It's on localhost"
      puts "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
    end
  end
end

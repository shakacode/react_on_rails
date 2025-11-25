# frozen_string_literal: true

require_relative "task_helpers"

namespace :dummy_apps do
  include ReactOnRails::TaskHelpers

  task :pnpm_install do
    pnpm_install_cmd = "pnpm install"
    sh_in_dir(dummy_app_dir, pnpm_install_cmd)
    sh_in_dir(dummy_app_dir, "yalc link react-on-rails")
  end

  task dummy_app: [:pnpm_install] do
    dummy_app_dir = File.join(gem_root, "spec/dummy")
    bundle_install_in(dummy_app_dir)
  end

  task :generate_packs do
    dummy_app_dir = File.join(gem_root, "spec/dummy")
    sh_in_dir(dummy_app_dir, "bundle exec rake react_on_rails:generate_packs")
  end

  task dummy_apps: %i[dummy_app node_package generate_packs] do
    puts "Prepared all Dummy Apps"
  end
end

desc "Prepares all dummy apps by installing dependencies"
task dummy_apps: ["dummy_apps:dummy_apps"]

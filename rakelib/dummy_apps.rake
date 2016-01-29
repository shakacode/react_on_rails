require_relative "task_helpers"
include ReactOnRails::TaskHelpers

namespace :dummy_apps do
  task :dummy_app do
    dummy_app_dir = File.join(gem_root, "spec/dummy")
    bundle_install_in(dummy_app_dir)
  end

  task :dummy_app_no_turbolinks do
    dummy_app_dir = File.join(gem_root, "spec/dummy")
    bundle_install_in_no_turbolinks(dummy_app_dir)
  end

  task dummy_apps: [:dummy_app, :node_package] do
    puts "Prepared all Dummy Apps"
  end
end

desc "Prepares all dummy apps by installing dependencies"
task dummy_apps: ["dummy_apps:dummy_apps"]

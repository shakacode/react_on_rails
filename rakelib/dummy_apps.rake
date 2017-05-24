require_relative "task_helpers"
include ReactOnRails::TaskHelpers

namespace :dummy_apps do
  task :yarn_install do
    yarn_install_cmd = "yarn install --mutex network && yarn run install-react-on-rails"
    sh_in_dir(dummy_app_dir, yarn_install_cmd)
  end

  task dummy_app: [:yarn_install] do
    dummy_app_dir = File.join(gem_root, "spec/dummy")
    bundle_install_in(dummy_app_dir)
  end

  task dummy_app_with_turbolinks_2: [:yarn_install] do
    dummy_app_dir = File.join(gem_root, "spec/dummy")
    bundle_install_with_turbolinks_2_in(dummy_app_dir)
  end

  task dummy_apps: %i[dummy_app node_package] do
    puts "Prepared all Dummy Apps"
  end
end

desc "Prepares all dummy apps by installing dependencies"
task dummy_apps: ["dummy_apps:dummy_apps"]

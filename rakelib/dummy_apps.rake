require_relative "task_helpers"

# rubocop:disable Style/MixinUsage
include ReactOnRailsPro::TaskHelpers
# rubocop:enable Style/MixinUsage

namespace :dummy_apps do
  task :yarn_install do
    # TODO: figure out how and if pro-package should be installed
    # yarn_install_cmd = "yarn run install-pro-package && yarn install --mutex network"
    yarn_install_cmd = "yarn install --mutex network"
    sh_in_dir(dummy_app_dir, yarn_install_cmd)
  end

  task dummy_app: [:yarn_install] do
    dummy_app_dir = File.join(gem_root, "spec/dummy")
    bundle_install_in(dummy_app_dir)
  end

  task dummy_apps: %i[dummy_app node_package] do
    puts "Prepared all Dummy Apps"
  end
end

desc "Prepares all dummy apps by installing dependencies"
task dummy_apps: ["dummy_apps:dummy_apps"]

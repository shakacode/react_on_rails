require_relative "task_helpers"
include ReactOnRails::TaskHelpers

namespace :dummy_apps do
  task :dummy_app do
    dummy_app_dir = File.join(gem_root, "spec/dummy")
    bundle_install_in(dummy_app_dir)
    dummy_app_client_dir = File.join(dummy_app_dir, "client")
    sh_in_dir(dummy_app_client_dir, ["npm install",
                                     "$(npm bin)/webpack --config webpack.server.js",
                                     "$(npm bin)/webpack --config webpack.client.js"])
  end

  task :dummy_react_013_app do
    dummy_app_dir = File.join(gem_root, "spec/dummy-react-013")
    bundle_install_in(dummy_app_dir)
    dummy_app_client_dir = File.join(dummy_app_dir, "client")
    sh_in_dir(dummy_app_client_dir, ["npm install",
                                     "$(npm bin)/webpack --config webpack.server.js",
                                     "$(npm bin)/webpack --config webpack.client.js"])
  end

  task dummy_apps: [:dummy_app, :dummy_react_013_app] do
    puts "Prepared all Dummy Apps"
  end
end

desc "Prepares all dummy apps by installing dependencies"
task dummy_apps: ["dummy_apps:dummy_apps"]

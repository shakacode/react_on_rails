require_relative "task_helpers"
include ReactOnRails::TaskHelpers

namespace :node_package do
  task :build do
    sh "npm run build"
  end

  desc "Has all examples and dummy apps use local node_package folder for react-on-rails node dependency"
  task :symlink do
    # sh_in_dir(gem_root, "npm run symlink-node-package")
  end
end

desc "Prepares node_package by building and symlinking any example/dummy apps present"
task node_package: "node_package:build" do
  Rake::Task["node_package:symlink"].invoke
end

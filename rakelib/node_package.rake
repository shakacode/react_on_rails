require_relative "task_helpers"
include ReactOnRails::TaskHelpers

namespace :node_package do
  task :build do
    sh "yarn run build"
  end
end

desc "Prepares node_package by building and symlinking any example/dummy apps present"
task node_package: "node_package:build"

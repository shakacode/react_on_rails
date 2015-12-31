require_relative "task_helpers"
include ReactOnRails::TaskHelpers

namespace :node_package do
  task :build do
    sh 'npm run build'
  end
end

desc "Prepares all node_package by building"
task node_package: ["node_package:build"]

# frozen_string_literal: true

require_relative "task_helpers"

namespace :node_package do
  include ReactOnRails::TaskHelpers

  task :build do
    puts "Building Node Package and running 'yarn link'"
    sh "yarn run build && yarn link"
  end
end

desc "Prepares node_package by building and symlinking any example/dummy apps present"
task node_package: "node_package:build"

# frozen_string_literal: true

require_relative "task_helpers"

namespace :node_package do
  include ReactOnRails::TaskHelpers

  task :build do
    puts "Building Node Package"
    sh "pnpm run build"
  end
end

desc "Prepares node_package by building the TypeScript to JavaScript"
task node_package: "node_package:build"

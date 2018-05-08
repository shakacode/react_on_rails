require_relative "task_helpers"

namespace :vm_renderer do
  include ReactOnRailsPro::TaskHelpers
  task :build do
    puts "Building Node Package and running 'yarn link'"
    sh "yarn run build && yarn link"
  end
end

desc "Prepares vm_renderer by building and symlinking any example/dummy apps present"
task vm_renderer: "vm_renderer:build"

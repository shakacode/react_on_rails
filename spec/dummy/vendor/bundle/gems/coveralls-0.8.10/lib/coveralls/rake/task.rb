require 'rake'
require 'rake/tasklib'

module Coveralls
  class RakeTask < ::Rake::TaskLib
    include ::Rake::DSL if defined?(::Rake::DSL)

    def initialize(*args, &task_block)
      namespace :coveralls do
        desc "Push latest coverage results to Coveralls.io"
        task :push do
          require 'coveralls'
          Coveralls.push!
        end
      end
    end # initialize

  end # class
end # module

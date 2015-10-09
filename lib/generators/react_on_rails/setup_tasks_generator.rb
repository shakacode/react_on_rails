require "rails/generators"

module ReactOnRails
  module Generators
    class SetupTasksGenerator < Rails::Generators::Base
      hide!
      source_root File.expand_path("../templates", __FILE__)

      def copy_tasks
        copy_file "lib/tasks/assets.rake", "lib/tasks/assets.rake"
        copy_file "lib/tasks/brakeman.rake", "lib/tasks/brakeman.rake"
        copy_file "lib/tasks/ci.rake", "lib/tasks/ci.rake"
        copy_file "lib/tasks/linters.rake", "lib/tasks/linters.rake"
      end
    end
  end
end

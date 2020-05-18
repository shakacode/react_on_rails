# frozen_string_literal: true

require "active_support"

if Rake::Task.task_defined?("assets:precompile")
  Rake::Task["assets:precompile"].enhance do
    Rake::Task["react_on_rails:assets:webpack"].invoke
  end
else
  Rake::Task.define_task("assets:precompile" => ["react_on_rails:assets:webpack"])
end

# Sprockets independent tasks
namespace :react_on_rails do
  namespace :assets do
    desc <<-DESC.strip_heredoc
      Compile assets with webpack
      Uses command defined with ReactOnRails.configuration.build_production_command

      sh "#{ReactOnRails::Utils.prepend_cd_node_modules_directory('<ReactOnRails.configuration.build_production_command>')}"
    DESC
    task webpack: :locale do
      if ReactOnRails.configuration.build_production_command.present?
        sh ReactOnRails::Utils.prepend_cd_node_modules_directory(
          ReactOnRails.configuration.build_production_command
        ).to_s
      end
    end
  end
end

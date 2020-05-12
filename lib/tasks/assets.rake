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
    # In this task, set prerequisites for the assets:precompile task	
    desc <<-DESC.strip_heredoc	
      Create webpack assets before calling assets:environment	
      The webpack task must run before assets:environment task.	
      Otherwise Sprockets cannot find the files that webpack produces.	
      This is the secret sauce for how a Heroku deployment knows to create the webpack generated JavaScript files.	
    DESC
    task compile_environment: :webpack do	
      Rake::Task["assets:environment"].invoke	
    end

    desc <<-DESC.strip_heredoc
      Compile assets with webpack
      Uses command defined with ReactOnRails.configuration.build_production_command

      sh "#{ReactOnRails::Utils.prepend_cd_node_modules_directory('<ReactOnRails.configuration.build_production_command>')}"
    DESC
    task webpack: :locale do
      if Rake::Task.task_defined?("webpacker:compile")
        # TODO: Eventually, this will need reconsideration if we use any of the Webpacker compilation
        Rake::Task["webpacker:compile"].clear
      end

      if ReactOnRails.configuration.build_production_command.present?
        sh ReactOnRails::Utils.prepend_cd_node_modules_directory(
          ReactOnRails.configuration.build_production_command
        ).to_s
      end
    end
  end
end

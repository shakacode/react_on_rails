# frozen_string_literal: true

# Important: The default assets:precompile is modified ONLY if the rails/webpacker webpack config
# does not exist!

require "active_support"

ENV["RAILS_ENV"] ||= ENV["RACK_ENV"] || "development"
ENV["NODE_ENV"]  ||= "development"

unless ReactOnRails::WebpackerUtils.webpacker_webpack_production_config_exists?
  if Rake::Task.task_defined?("assets:precompile")
    Rake::Task["assets:precompile"].enhance do
      Rake::Task["react_on_rails:assets:webpack"].invoke
      puts "Invoking task webpacker:clean from React on Rails"
      Rake::Task["webpacker:clean"].invoke
    end
  else
    Rake::Task.define_task("assets:precompile" => ["react_on_rails:assets:webpack"])
  end
end

# Sprockets independent tasks
namespace :react_on_rails do
  namespace :assets do
    desc <<-DESC.strip_heredoc
      Compile assets with webpack	
      Uses command defined with ReactOnRails.configuration.build_production_command	
      sh "#{ReactOnRails::Utils.prepend_cd_node_modules_directory('<ReactOnRails.configuration.build_production_command>')}"	
      Note: This command is not automatically added to assets:precompile if the rails/webpacker	
      configuration file config/webpack/production.js exists.
    DESC
    task webpack: :locale do
      if ReactOnRails.configuration.build_production_command.present?
        sh ReactOnRails::Utils.prepend_cd_node_modules_directory(
          ReactOnRails.configuration.build_production_command
        ).to_s
      else
        msg = <<~MSG
          React on Rails is aborting webpack compilation from task react_on_rails:assets:webpack
          because you do not have the `config.build_production_command` defined.

          Note, this task may have run as part of `assets:precompile`. If file
          config/webpack/production.js does not exist, React on Rails will modify
          the default `asset:precompile` to run task `react_on_rails:assets:webpack`.
        MSG
        puts Rainbow(msg).red
        exit!(1)
      end
    end
  end
end

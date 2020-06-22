# frozen_string_literal: true

# Important: The default assets:precompile is modified ONLY if the rails/webpacker webpack config
# does not exist!

require "active_support"

ENV["RAILS_ENV"] ||= ENV["RACK_ENV"] || "development"
ENV["NODE_ENV"]  ||= "development"
webpacker_webpack_config_abs_path = File.join(Rails.root, "config/webpack/#{ENV["NODE_ENV"]}.js")
webpack_config_path = Pathname.new(webpacker_webpack_config_abs_path).relative_path_from(Rails.root).to_s

unless File.exists?(webpacker_webpack_config_abs_path)
  if Rake::Task.task_defined?("assets:precompile")
    Rake::Task["assets:precompile"].enhance do
      Rake::Task["react_on_rails:assets:webpack"].invoke
      puts "Invoking task wepacker:clean from React on Rails"
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
      configuration file #{webpack_config_path} exists.
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

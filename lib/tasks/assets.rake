# frozen_string_literal: true

# Important: The default assets:precompile is modified ONLY if the rails/webpacker webpack config
# does not exist!

require "active_support"

ENV["RAILS_ENV"] ||= ENV["RACK_ENV"] || "development"

skip_react_on_rails_precompile = %w[no false n f].include?(ENV["REACT_ON_RAILS_PRECOMPILE"])

if !skip_react_on_rails_precompile && !ReactOnRails::WebpackerUtils.webpacker_webpack_production_config_exists?
  # Ensure that rails/webpacker does not call bin/webpack if we're providing
  # the build command.
  ENV["WEBPACKER_PRECOMPILE"] = "false"

  precompile_tasks = lambda {
    Rake::Task["react_on_rails:assets:webpack"].invoke
    puts "Invoking task webpacker:clean from React on Rails"

    # VERSIONS is per the rails/webpacker clean method definition.
    # We set it very big so that it is not used, and then clean just
    # removes files older than 1 hour.
    versions = 100_000
    Rake::Task["webpacker:clean"].invoke(versions)
  }

  if Rake::Task.task_defined?("assets:precompile")
    Rake::Task["assets:precompile"].enhance do
      precompile_tasks.call
    end
  else
    Rake::Task.define_task("assets:precompile") do
      precompile_tasks.call
    end
  end
end

# Sprockets independent tasks
# rubocop:disable Metrics/BlockLength
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
      build_production_command = ReactOnRails.configuration.build_production_command
      if build_production_command.present?
        if build_production_command.is_a?(String)
          sh ReactOnRails::Utils.prepend_cd_node_modules_directory(
            build_production_command
          ).to_s
        elsif build_production_command.methods.include?(:call)
          build_production_command.call
        else
          msg = "ReactonRails.configuration.build_production_command is improperly configured. "\
                "Value = #{build_production_command} with class #{build_production_command.class}"
          puts Rainbow(msg).red
          exit!(1)
        end
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
# rubocop:enable Metrics/BlockLength

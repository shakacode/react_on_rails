# frozen_string_literal: true

require "active_support"

if defined?(Sprockets)
  # These tasks run as pre-requisites of assets:precompile.
  # Note, it's not possible to refer to ReactOnRails configuration values at this point.
  Rake::Task["assets:precompile"]
    .clear_prerequisites
    .enhance([:environment, "react_on_rails:assets:compile_environment"])
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

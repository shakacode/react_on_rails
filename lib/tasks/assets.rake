# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
namespace :react_on_rails do
  namespace :assets do
    desc <<~DESC
      If config.build_production_command is defined, this command is automatically
      added to task assets:precompile and the regular webpacker compile will not run.
      The defined command is either a script or a module with a method `call`.
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
        # Left in this warning message in case this rake task is run directly
        msg = <<~MSG
          React on Rails is aborting webpack compilation from task react_on_rails:assets:webpack
          because you do not have the `config.build_production_command` defined.
        MSG
        puts Rainbow(msg).red
        exit!(1)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength

# frozen_string_literal: true

require "react_on_rails_pro/v8_log_processor"

namespace :react_on_rails_pro do
  desc <<-DESC
    Processes V8 log files by moving them to a specified directory, generating a combined
    V8 profile, and optionally deleting the original log files. The resulting profile.v8log.json file
    can be analyzed using tools like Speed Scope (https://www.speedscope.app) or Chrome Developer Tools
    to visualize and analyze performance metrics.

    @param keep_files [String] 'true' to keep the original log files, 'false' to delete them.
    @param output_dir [String] The directory where log files are moved and the profile is saved.
  DESC
  task :process_v8_logs, %i[keep_files output_dir] => [:environment] do |_, args|
    args.with_defaults(keep_files: "false", output_dir: "v8_profiles")
    keep_files = args.keep_files == "true"
    ReactOnRailsPro::V8LogProcessor.process_v8_logs(keep_files, args.output_dir)
  end
end

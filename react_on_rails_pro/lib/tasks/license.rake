# frozen_string_literal: true

require "react_on_rails_pro/license_task_formatter"

namespace :react_on_rails_pro do
  desc "Verify the React on Rails Pro license and display its status"
  task verify_license: :environment do
    format = ENV.fetch("FORMAT", "text")
    info = ReactOnRailsPro::LicenseValidator.license_info
    result = ReactOnRailsPro::LicenseTaskFormatter.build_result(info)

    if format.casecmp("json").zero?
      require "json"
      puts JSON.pretty_generate(result)
    else
      ReactOnRailsPro::LicenseTaskFormatter.print_text(result, info)
    end

    raise "License verification failed: #{info[:status]}" if info[:status] != :valid
  end
end

# frozen_string_literal: true

# Helpers for the GitHub Actions runtime context shared by the benchmark scripts.
module Github
  module_function

  def run_url
    "#{ENV.fetch('GITHUB_SERVER_URL')}/#{ENV.fetch('GITHUB_REPOSITORY')}/actions/runs/#{ENV.fetch('GITHUB_RUN_ID')}"
  end

  def warning(message)
    $stdout.puts "::warning::#{message}"
  end
end

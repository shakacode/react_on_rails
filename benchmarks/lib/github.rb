# frozen_string_literal: true

# Helpers for the GitHub Actions runtime context shared by the benchmark scripts.
module Github
  module_function

  def run_url
    "#{ENV.fetch('GITHUB_SERVER_URL')}/#{ENV.fetch('GITHUB_REPOSITORY')}/actions/runs/#{ENV.fetch('GITHUB_RUN_ID')}"
  end

  def warning(message)
    $stdout.puts "::warning::#{escape_workflow_command_data(message)}"
  end

  def notice(message)
    $stdout.puts "::notice::#{escape_workflow_command_data(message)}"
  end

  def debug(message)
    $stdout.puts "::debug::#{escape_workflow_command_data(message)}"
  end

  def escape_workflow_command_data(value)
    value.to_s
         # Escape percent first so the percent signs introduced below are not double-encoded.
         .gsub("%", "%25")
         .gsub("\r", "%0D")
         .gsub("\n", "%0A")
  end
end

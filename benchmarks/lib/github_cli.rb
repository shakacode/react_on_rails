# frozen_string_literal: true

require "open3"

module GithubCli
  module_function

  def capture(*args, env: {}, error_message: nil, stdin_data: nil)
    stdout, stderr, status = Open3.capture3(env, *args, stdin_data: stdin_data)
    warn stderr unless stderr.empty?
    warn "::error::#{error_message}" if error_message && !status.success?
    [stdout, status]
  end

  def capture_success(*args, error_message:, env: {})
    stdout, status = capture(*args, env: env, error_message: error_message)
    return stdout if status.success?

    nil
  end

  def run(*args, env: {}, error_message: nil, stdin_data: nil)
    _stdout, status = capture(*args, env: env, error_message: error_message, stdin_data: stdin_data)
    status.success?
  end
end

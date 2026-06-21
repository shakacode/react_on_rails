# frozen_string_literal: true

require "open3"

module GithubCli
  module_function

  def capture(*, env: {}, error_message: nil, stdin_data: nil)
    stdout, stderr, status = Open3.capture3(env, *, stdin_data:)
    warn stderr unless stderr.empty?
    warn "::error::#{error_message}" if error_message && !status.success?
    [stdout, status]
  end

  def capture_success(*, error_message:, env: {}, stdin_data: nil)
    stdout, status = capture(*, env:, error_message:, stdin_data:)
    return stdout if status.success?

    nil
  end

  def run(*, env: {}, error_message: nil, stdin_data: nil)
    _stdout, status = capture(*, env:, error_message:, stdin_data:)
    status.success?
  end
end

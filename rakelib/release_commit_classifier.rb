# frozen_string_literal: true

require "open3"
require "tmpdir"

# Canonical adapter for the CI detector's non-runtime-only commit verdict.
module ReleaseCommitClassifier
  module_function

  def non_runtime_only?(monorepo_root:, sha:)
    detector = File.join(monorepo_root, "script", "ci-changes-detector")
    return false unless File.executable?(detector)

    Dir.mktmpdir("ror-ci-detector") do |dir|
      output_file = File.join(dir, "github_output")
      File.write(output_file, "")
      _stdout, status = Open3.capture2e(
        { "GITHUB_OUTPUT" => output_file }, detector, "#{sha}^", sha, chdir: monorepo_root
      )
      return false unless status.success?

      flag = File.read(output_file).lines.reverse.find { |line| line.start_with?("non_runtime_only=") }
      return false if flag.nil?

      flag.split("=", 2).last.strip == "true"
    end
  rescue StandardError
    false
  end
end

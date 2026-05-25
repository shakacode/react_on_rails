# frozen_string_literal: true

require_relative "spec_helper"

require "fileutils"
require "open3"
require "tmpdir"

RSpec.describe "Pro dummy bin/prod" do
  let(:bin_prod_path) do
    File.expand_path("../dummy/bin/prod", __dir__)
  end

  def run_bin_prod(fake_commands:, port: nil)
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(
        [
          File.join(dir, "bin"),
          File.join(dir, "client"),
          File.join(dir, "config"),
          File.join(dir, "public/assets"),
          File.join(dir, "public/webpack/production")
        ]
      )
      File.write(File.join(dir, "public/webpack/production/manifest.json"), "{}")
      FileUtils.cp(bin_prod_path, File.join(dir, "bin/prod"))

      fake_bin_path = File.join(dir, "fake-bin")
      command_log_path = File.join(dir, "command.log")
      FileUtils.mkdir_p(fake_bin_path)

      fake_commands.each do |command|
        path = File.join(fake_bin_path, command)
        File.write(
          path,
          <<~BASH
            #!/usr/bin/env bash
            printf '%s %s\\n' "${0##*/}" "$*" > "$COMMAND_LOG_PATH"
          BASH
        )
        FileUtils.chmod(0o755, path)
      end

      stdout, stderr, status = Open3.capture3(
        {
          "COMMAND_LOG_PATH" => command_log_path,
          "PATH" => "#{fake_bin_path}:/usr/bin:/bin:/usr/sbin:/sbin",
          "PORT" => port
        },
        "bash",
        "bin/prod",
        chdir: dir
      )

      {
        command_log: File.exist?(command_log_path) ? File.read(command_log_path) : nil,
        status: status,
        stderr: stderr,
        stdout: stdout
      }
    end
  end

  it "starts Overmind on the production benchmark port by default" do
    result = run_bin_prod(fake_commands: %w[overmind foreman])

    aggregate_failures do
      expect(result[:status]).to be_success
      expect(result[:command_log]).to eq("overmind start -f Procfile.prod -p 3001\n")
      expect(result[:stderr]).to be_empty
      expect(result[:stdout]).to be_empty
    end
  end

  it "starts Foreman on the production benchmark port by default" do
    result = run_bin_prod(fake_commands: %w[foreman])

    aggregate_failures do
      expect(result[:status]).to be_success
      expect(result[:command_log]).to eq("foreman start -f Procfile.prod -p 3001\n")
      expect(result[:stderr]).to be_empty
      expect(result[:stdout]).to be_empty
    end
  end

  it "preserves an explicitly configured production port" do
    result = run_bin_prod(fake_commands: %w[foreman], port: "4242")

    aggregate_failures do
      expect(result[:status]).to be_success
      expect(result[:command_log]).to eq("foreman start -f Procfile.prod -p 4242\n")
      expect(result[:stderr]).to be_empty
      expect(result[:stdout]).to be_empty
    end
  end
end

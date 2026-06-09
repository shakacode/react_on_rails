# frozen_string_literal: true

require_relative "spec_helper"
require_relative "../lib/pr_report_poster"

RSpec.describe PrReportPoster do
  include BenchmarkEnvHelper

  subject(:poster) do
    described_class.new(
      repository: "shakacode/react_on_rails",
      pr_number: "123",
      suite_name: "Core",
      marker: "<!-- BENCHER CORE -->"
    )
  end

  describe "#initialize" do
    it "rejects non-numeric pull request numbers before building GitHub paths" do
      expect do
        described_class.new(
          repository: "shakacode/react_on_rails",
          pr_number: "main/456",
          suite_name: "Core",
          marker: "<!-- BENCHER CORE -->"
        )
      end.to raise_error(ArgumentError, 'pr_number must be numeric, got: "main/456"')
    end
  end

  describe ".from_env" do
    it "wires the repository and pull request number from GitHub Actions env" do
      status = instance_double(Process::Status, success?: true)
      allow(GithubCli).to receive_messages(run: true, capture: ["", status])

      with_env("GITHUB_REPOSITORY" => "shakacode/react_on_rails", "PR_NUMBER" => "456") do
        described_class.from_env(suite_name: "Pro", marker: "<!-- BENCHER PRO -->").replace("### report")
      end

      expect(GithubCli).to have_received(:run).with(
        "gh", "pr", "comment", "456", "--body-file", "-",
        error_message: "Failed to post Pro benchmark report comment",
        stdin_data: "<!-- BENCHER PRO -->\n### report"
      )
      expect(GithubCli).to have_received(:capture).with(
        "gh", "api", "repos/shakacode/react_on_rails/issues/456/comments",
        "--paginate",
        "--jq", ".[] | select(.body | startswith(env.MARKER)) | select(.created_at < env.CUTOFF_TS) | .id",
        env: { "MARKER" => "<!-- BENCHER PRO -->", "CUTOFF_TS" => kind_of(String) },
        error_message: "Failed to list stale Pro Bencher report comments"
      )
    end

    it "rejects non-numeric pull request numbers before building GitHub paths" do
      with_env("GITHUB_REPOSITORY" => "shakacode/react_on_rails", "PR_NUMBER" => "main/456") do
        expect do
          described_class.from_env(suite_name: "Pro", marker: "<!-- BENCHER PRO -->")
        end.to raise_error(ArgumentError, 'pr_number must be numeric, got: "main/456"')
      end
    end
  end

  describe "#replace" do
    it "posts the marked report over stdin and deletes comments older than the new post" do
      now = Time.utc(2026, 6, 7, 12, 0, 0)
      status = instance_double(Process::Status, success?: true)

      allow(Time).to receive(:now).and_return(now)
      allow(GithubCli).to receive_messages(run: true, capture: ["", status])

      poster.replace("### report")

      expect(GithubCli).to have_received(:run).with(
        "gh", "pr", "comment", "123", "--body-file", "-",
        error_message: "Failed to post Core benchmark report comment",
        stdin_data: "<!-- BENCHER CORE -->\n### report"
      )
      expect(GithubCli).to have_received(:capture).with(
        "gh", "api", "repos/shakacode/react_on_rails/issues/123/comments",
        "--paginate",
        "--jq", ".[] | select(.body | startswith(env.MARKER)) | select(.created_at < env.CUTOFF_TS) | .id",
        env: { "MARKER" => "<!-- BENCHER CORE -->", "CUTOFF_TS" => now.utc.iso8601 },
        error_message: "Failed to list stale Core Bencher report comments"
      )
    end

    it "keeps prior comments when posting fails" do
      allow(GithubCli).to receive(:run).and_return(false)
      allow(GithubCli).to receive(:capture)

      expect { poster.replace("### report") }
        .to output(/::warning::Failed to post Core benchmark report comment/).to_stdout

      expect(GithubCli).to have_received(:run).with(
        "gh", "pr", "comment", "123", "--body-file", "-",
        error_message: "Failed to post Core benchmark report comment",
        stdin_data: "<!-- BENCHER CORE -->\n### report"
      )
      expect(GithubCli).not_to have_received(:capture)
    end

    it "does nothing for an empty report" do
      allow(GithubCli).to receive(:run)

      poster.replace("")

      expect(GithubCli).not_to have_received(:run)
    end

    it "deletes each stale comment id" do
      status = instance_double(Process::Status, success?: true)

      allow(GithubCli).to receive_messages(capture: ["111\n222\n", status], run: true)

      expect { poster.replace("### report") }
        .to output(/Deleting stale Core Bencher report comment 111/).to_stdout
      expect(GithubCli).to have_received(:run).with(
        "gh", "api", "-X", "DELETE", "repos/shakacode/react_on_rails/issues/comments/111",
        error_message: "Failed to delete stale Core Bencher report comment 111"
      )
      expect(GithubCli).to have_received(:run).with(
        "gh", "api", "-X", "DELETE", "repos/shakacode/react_on_rails/issues/comments/222",
        error_message: "Failed to delete stale Core Bencher report comment 222"
      )
    end

    it "warns and does not delete anything when the stale comment listing command fails" do
      status = instance_double(Process::Status, success?: false)

      allow(GithubCli).to receive_messages(capture: ["111\n", status], run: true)

      expect { poster.replace("### report") }
        .to output(/::warning::Failed to list stale Core Bencher report comments; skipping cleanup/).to_stdout

      expect(GithubCli).not_to have_received(:run).with(
        "gh", "api", "-X", "DELETE", "repos/shakacode/react_on_rails/issues/comments/111",
        any_args
      )
    end

    it "warns when stale comment deletion fails" do
      status = instance_double(Process::Status, success?: true)

      allow(GithubCli).to receive(:capture).and_return(["111\n", status])
      allow(GithubCli).to receive(:run)
        .with("gh", "pr", "comment", anything, any_args)
        .and_return(true)
      allow(GithubCli).to receive(:run)
        .with("gh", "api", "-X", "DELETE", anything, any_args)
        .and_return(false)

      expect { poster.replace("### report") }
        .to output(/::warning::Failed to delete 1 stale Core Bencher report comment/).to_stdout
    end

    it "warns about mixed non-numeric stale comment ids while deleting numeric ids" do
      status = instance_double(Process::Status, success?: true)

      allow(GithubCli).to receive_messages(capture: ["111\nnot-an-id\n222\n", status], run: true)

      expect { poster.replace("### report") }
        .to output(/::warning::Stale Core Bencher report comment listing returned 1 non-numeric ID/).to_stdout

      expect(GithubCli).to have_received(:run).with("gh", "api", "-X", "DELETE", anything, any_args).twice
      expect(GithubCli).not_to have_received(:run).with(
        "gh", "api", "-X", "DELETE", "repos/shakacode/react_on_rails/issues/comments/not-an-id",
        any_args
      )
    end

    it "warns when stale comment listing returns no numeric ids" do
      status = instance_double(Process::Status, success?: true)

      allow(GithubCli).to receive_messages(capture: ["not-an-id\n", status], run: true)

      expect { poster.replace("### report") }
        .to output(/::warning::Stale Core Bencher report comment listing returned no numeric IDs.*not-an-id/).to_stdout
      expect(GithubCli).not_to have_received(:run).with(
        "gh", "api", "-X", "DELETE", "repos/shakacode/react_on_rails/issues/comments/not-an-id",
        any_args
      )
    end
  end
end

# frozen_string_literal: true

require_relative "../spec_helper"
require "react_on_rails/dev/server_mode"
require "fileutils"
require "tmpdir"

RSpec.describe ReactOnRails::Dev::ServerMode do
  around do |example|
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) { example.run }
    end
  end

  def write_shakapacker_config(content)
    FileUtils.mkdir_p("config")
    File.write("config/shakapacker.yml", content)
  end

  describe ".detect" do
    it "defaults missing config to HMR mode" do
      expect(described_class.detect("config/missing.yml")).to eq(:hmr)
    end

    it "uses the supplied fallback when config is missing" do
      expect(described_class.detect("config/missing.yml", fallback: :live_reload)).to eq(:live_reload)
    end

    it "uses Shakapacker's live reload default when hmr is false and live_reload is omitted" do
      write_shakapacker_config(<<~YAML)
        development:
          dev_server:
            hmr: false
      YAML

      expect(described_class.detect("config/shakapacker.yml")).to eq(:live_reload)
    end

    it "uses live reload default when dev_server has only host/port settings" do
      write_shakapacker_config(<<~YAML)
        development:
          dev_server:
            host: localhost
            port: 3035
      YAML

      expect(described_class.detect("config/shakapacker.yml")).to eq(:live_reload)
    end

    it "treats live_reload false without HMR as generic development server mode" do
      write_shakapacker_config(<<~YAML)
        development:
          dev_server:
            live_reload: false
      YAML

      expect(described_class.detect("config/shakapacker.yml")).to eq(:development_server)
    end

    it "detects live reload when live_reload is true without an HMR key" do
      write_shakapacker_config(<<~YAML)
        development:
          dev_server:
            live_reload: true
      YAML

      expect(described_class.detect("config/shakapacker.yml")).to eq(:live_reload)
    end

    it "prefers HMR when both hmr and live_reload are true" do
      write_shakapacker_config(<<~YAML)
        development:
          dev_server:
            hmr: true
            live_reload: true
      YAML

      expect(described_class.detect("config/shakapacker.yml")).to eq(:hmr)
    end

    it "detects HMR when hmr is webpack-dev-server only mode" do
      write_shakapacker_config(<<~YAML)
        development:
          dev_server:
            hmr: only
      YAML

      expect(described_class.detect("config/shakapacker.yml")).to eq(:hmr)
    end

    it "ignores quoted HMR boolean strings" do
      write_shakapacker_config(<<~YAML)
        development:
          dev_server:
            hmr: "true"
      YAML

      expect(described_class.detect("config/shakapacker.yml")).to eq(:live_reload)
    end

    it "ignores quoted live_reload boolean strings" do
      write_shakapacker_config(<<~YAML)
        development:
          dev_server:
            live_reload: "false"
      YAML

      expect(described_class.detect("config/shakapacker.yml")).to eq(:live_reload)
    end

    it "ignores invalid HMR values when live reload uses the Shakapacker default" do
      write_shakapacker_config(<<~YAML)
        development:
          dev_server:
            hmr: sometimes
      YAML

      expect(described_class.detect("config/shakapacker.yml")).to eq(:live_reload)
    end

    it "lets live_reload false win over invalid HMR values" do
      write_shakapacker_config(<<~YAML)
        development:
          dev_server:
            hmr: sometimes
            live_reload: false
      YAML

      expect(described_class.detect("config/shakapacker.yml")).to eq(:development_server)
    end

    it "uses the fallback mode when dev_server is empty" do
      write_shakapacker_config(<<~YAML)
        development:
          dev_server:
      YAML

      expect(described_class.detect("config/shakapacker.yml")).to eq(:hmr)
    end

    it "detects HMR from the default section when development is absent" do
      write_shakapacker_config(<<~YAML)
        default:
          dev_server:
            hmr: true
      YAML

      expect(described_class.detect("config/shakapacker.yml")).to eq(:hmr)
    end

    it "lets development hmr override default hmr" do
      write_shakapacker_config(<<~YAML)
        default:
          dev_server:
            hmr: true
        development:
          dev_server:
            hmr: false
      YAML

      expect(described_class.detect("config/shakapacker.yml")).to eq(:live_reload)
    end

    it "merges default and development dev_server settings" do
      write_shakapacker_config(<<~YAML)
        default:
          dev_server:
            hmr: true
        development:
          dev_server:
            live_reload: false
      YAML

      expect(described_class.detect("config/shakapacker.yml")).to eq(:hmr)
    end

    it "warns when Shakapacker config parsing fails" do
      write_shakapacker_config(<<~YAML)
        development:
          dev_server:
            hmr: [
      YAML

      expect { described_class.detect("config/shakapacker.yml") }
        .to output(%r{\[ReactOnRails\] Could not parse config/shakapacker.yml}).to_stderr
    end

    it "warns when Shakapacker config ERB evaluation fails" do
      write_shakapacker_config(<<~YAML)
        development:
          dev_server:
            hmr: <%= ENV.fetch("MISSING_HMR_FLAG") %>
      YAML

      expect { described_class.detect("config/shakapacker.yml") }
        .to output(%r{\[ReactOnRails\] Could not parse config/shakapacker.yml}).to_stderr
    end

    it "evaluates ERB in the config file" do
      write_shakapacker_config(<<~YAML)
        development:
          dev_server:
            hmr: <%= true %>
      YAML

      expect(described_class.detect("config/shakapacker.yml")).to eq(:hmr)
    end
  end

  describe ".hmr_enabled?" do
    it "returns true when HMR is explicitly enabled" do
      write_shakapacker_config(<<~YAML)
        development:
          dev_server:
            hmr: true
      YAML

      expect(described_class.hmr_enabled?("config/shakapacker.yml")).to be(true)
    end

    it "returns true when HMR is set to webpack-dev-server only mode" do
      write_shakapacker_config(<<~YAML)
        development:
          dev_server:
            hmr: only
      YAML

      expect(described_class.hmr_enabled?("config/shakapacker.yml")).to be(true)
    end

    it "does not treat missing config as HMR enabled" do
      expect(described_class.hmr_enabled?("config/missing.yml")).to be(false)
    end
  end

  describe ".text" do
    it "uses mode-specific command labels" do
      expect(described_class.text(:hmr, :command_label)).to eq("(none) / hmr")
      expect(described_class.text(:live_reload, :command_label)).to eq("(none)")
    end

    it "uses live reload wording for live reload shared output warnings" do
      expect(described_class.text(:live_reload, :shared_output_warning))
        .to eq("Do not combine shared output path with bin/dev (live reload)")
    end

    it "raises a descriptive error for unknown text keys" do
      expect { described_class.text(:hmr, :missing_key) }
        .to raise_error(ArgumentError, /Unknown ServerMode text key :missing_key/)
    end

    it "raises a descriptive error for unknown modes" do
      expect { described_class.text(:missing_mode, :command_description) }
        .to raise_error(ArgumentError, /Unknown ServerMode :missing_mode/)
    end
  end

  describe ".details" do
    it "returns detail lines separately from string text" do
      expect(described_class.details(:live_reload))
        .to include("Full-page live reload enabled", "Browser refreshes after changes")
      expect { described_class.text(:live_reload, :details) }
        .to raise_error(ArgumentError, /Unknown ServerMode text key :details/)
    end
  end
end

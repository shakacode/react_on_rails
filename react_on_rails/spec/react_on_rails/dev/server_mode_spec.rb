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

    it "treats hmr false without live reload as generic development server mode" do
      write_shakapacker_config(<<~YAML)
        development:
          dev_server:
            hmr: false
      YAML

      expect(described_class.detect("config/shakapacker.yml")).to eq(:development_server)
    end

    it "keeps live_reload false without HMR as the fallback HMR mode" do
      write_shakapacker_config(<<~YAML)
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
  end

  describe ".hmr_enabled?" do
    it "uses the same fallback behavior as detect" do
      expect(described_class.hmr_enabled?("config/missing.yml")).to be(true)
    end
  end

  describe ".text" do
    it "uses live reload wording for live reload shared output warnings" do
      expect(described_class.text(:live_reload, :shared_output_warning))
        .to eq("Do not combine shared output path with bin/dev (live reload)")
    end

    it "raises a descriptive error for unknown text keys" do
      expect { described_class.text(:hmr, :missing_key) }
        .to raise_error(ArgumentError, /Unknown ServerMode text key :missing_key/)
    end
  end
end

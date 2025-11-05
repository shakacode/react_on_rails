# frozen_string_literal: true

require_relative "../spec_helper"
require "react_on_rails/dev/pack_generator"

RSpec.describe ReactOnRails::Dev::PackGenerator do
  describe ".generate" do
    it "runs pack generation successfully in verbose mode" do
      allow(described_class).to receive(:system)
        .with("bundle", "exec", "rake", "react_on_rails:generate_packs")
        .and_return(true)

      expect { described_class.generate(verbose: true) }
        .to output(/📦 Generating React on Rails packs.../).to_stdout_from_any_process
    end

    it "runs pack generation successfully in quiet mode" do
      allow(described_class).to receive(:system)
        .with("bundle", "exec", "rake", "react_on_rails:generate_packs", out: File::NULL, err: File::NULL)
        .and_return(true)

      expect { described_class.generate(verbose: false) }
        .to output(/📦 Generating packs\.\.\. ✅/).to_stdout_from_any_process
    end

    it "exits with error when pack generation fails" do
      allow(described_class).to receive(:system)
        .with("bundle", "exec", "rake", "react_on_rails:generate_packs", out: File::NULL, err: File::NULL)
        .and_return(false)

      expect { described_class.generate(verbose: false) }.to raise_error(SystemExit)
    end
  end
end

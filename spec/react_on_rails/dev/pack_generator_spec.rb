# frozen_string_literal: true

require_relative "../spec_helper"
require "react_on_rails/dev/pack_generator"

RSpec.describe ReactOnRails::Dev::PackGenerator do
  describe ".generate" do
    before do
      allow(ReactOnRails::PackerUtils).to receive(:shakapacker_precompile_hook_configured?).and_return(false)
    end

    context "when shakapacker precompile hook is configured" do
      before do
        allow(ReactOnRails::PackerUtils).to receive(:shakapacker_precompile_hook_configured?).and_return(true)
      end

      it "skips pack generation in verbose mode" do
        expect { described_class.generate(verbose: true) }
          .to output(/⏭️  Skipping pack generation \(handled by shakapacker precompile hook\)/)
          .to_stdout_from_any_process
      end

      it "skips pack generation in quiet mode" do
        expect { described_class.generate(verbose: false) }
          .not_to output.to_stdout_from_any_process
      end
    end

    context "when shakapacker precompile hook is not configured" do
      it "runs pack generation successfully in verbose mode" do
        command = "bundle exec rake react_on_rails:generate_packs"
        allow(described_class).to receive(:system).with(command).and_return(true)

        expect { described_class.generate(verbose: true) }
          .to output(/📦 Generating React on Rails packs.../).to_stdout_from_any_process
      end

      it "runs pack generation successfully in quiet mode" do
        command = "bundle exec rake react_on_rails:generate_packs > /dev/null 2>&1"
        allow(described_class).to receive(:system).with(command).and_return(true)

        expect { described_class.generate(verbose: false) }
          .to output(/📦 Generating packs\.\.\. ✅/).to_stdout_from_any_process
      end

      it "exits with error when pack generation fails" do
        command = "bundle exec rake react_on_rails:generate_packs > /dev/null 2>&1"
        allow(described_class).to receive(:system).with(command).and_return(false)

        expect { described_class.generate(verbose: false) }.to raise_error(SystemExit)
      end
    end
  end
end

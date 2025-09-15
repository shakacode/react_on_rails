# frozen_string_literal: true

require_relative "../spec_helper"
require "react_on_rails/dev/pack_generator"

RSpec.describe ReactOnRails::Dev::PackGenerator do
  # Suppress stdout/stderr during tests using around hook
  around do |example|
    original_stderr = $stderr
    original_stdout = $stdout
    begin
      $stderr = File.open(File::NULL, "w")
      $stdout = File.open(File::NULL, "w")
      example.run
    ensure
      $stderr = original_stderr
      $stdout = original_stdout
    end
  end

  describe ".generate" do
    it "runs pack generation successfully in verbose mode" do
      command = "bundle exec rake react_on_rails:generate_packs"
      allow(Kernel).to receive(:system).with(command).and_return(true)

      expect { described_class.generate(verbose: true) }.not_to raise_error
    end

    it "runs pack generation successfully in quiet mode" do
      command = "bundle exec rake react_on_rails:generate_packs > /dev/null 2>&1"
      allow(Kernel).to receive(:system).with(command).and_return(true)

      expect { described_class.generate(verbose: false) }.not_to raise_error
    end

    it "exits with error when pack generation fails" do
      command = "bundle exec rake react_on_rails:generate_packs > /dev/null 2>&1"
      allow(Kernel).to receive(:system).with(command).and_return(false)

      expect { described_class.generate(verbose: false) }.to raise_error(SystemExit)
    end
  end
end

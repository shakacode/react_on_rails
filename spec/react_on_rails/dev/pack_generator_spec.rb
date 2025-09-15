# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe ReactOnRails::Dev::PackGenerator do
  # Suppress stdout/stderr during tests
  before(:all) do
    @original_stderr = $stderr
    @original_stdout = $stdout
    $stderr = File.open(File::NULL, "w")
    $stdout = File.open(File::NULL, "w")
  end

  after(:all) do
    $stderr = @original_stderr
    $stdout = @original_stdout
  end

  describe ".generate" do
    it "runs pack generation successfully in verbose mode" do
      command = "bundle exec rake react_on_rails:generate_packs"
      allow_any_instance_of(Kernel).to receive(:system).with(command).and_return(true)

      expect { described_class.generate(verbose: true) }.not_to raise_error
    end

    it "runs pack generation successfully in quiet mode" do
      command = "bundle exec rake react_on_rails:generate_packs > /dev/null 2>&1"
      allow_any_instance_of(Kernel).to receive(:system).with(command).and_return(true)

      expect { described_class.generate(verbose: false) }.not_to raise_error
    end

    it "exits with error when pack generation fails" do
      command = "bundle exec rake react_on_rails:generate_packs > /dev/null 2>&1"
      allow_any_instance_of(Kernel).to receive(:system).with(command).and_return(false)
      expect_any_instance_of(Kernel).to receive(:exit).with(1)

      described_class.generate(verbose: false)
    end
  end
end

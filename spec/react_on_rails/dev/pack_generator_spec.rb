# frozen_string_literal: true

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
    it "runs pack generation successfully" do
      allow_any_instance_of(Kernel).to receive(:system).with("bundle exec rake react_on_rails:generate_packs").and_return(true)
      allow($CHILD_STATUS).to receive(:success?).and_return(true)

      expect { described_class.generate }.not_to raise_error
    end

    it "exits with error when pack generation fails" do
      allow_any_instance_of(Kernel).to receive(:system).with("bundle exec rake react_on_rails:generate_packs").and_return(false)
      allow($CHILD_STATUS).to receive(:success?).and_return(false)
      expect_any_instance_of(Kernel).to receive(:exit).with(1)

      described_class.generate
    end
  end
end

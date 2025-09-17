# frozen_string_literal: true

require "spec_helper"
require "rails/generators"
require_relative "../../../../lib/generators/react_on_rails/doctor_generator"

RSpec.describe ReactOnRails::Generators::DoctorGenerator, type: :generator do
  let(:generator) { described_class.new }

  before do
    allow(generator).to receive(:destination_root).and_return("/tmp")
    allow(Dir).to receive(:chdir).with("/tmp").and_yield
  end

  describe "#run_diagnosis" do
    before do
      allow(generator).to receive(:exit)
      allow(generator).to receive(:puts)
      allow(File).to receive(:exist?).and_return(false)
      allow(File).to receive(:directory?).and_return(false)
    end

    it "runs all diagnosis checks" do
      expect(generator).to receive(:print_header)
      expect(generator).to receive(:run_all_checks)
      expect(generator).to receive(:print_summary)
      expect(generator).to receive(:exit_with_status)

      generator.run_diagnosis
    end

    context "when verbose option is enabled" do
      let(:generator) { described_class.new([], [], { verbose: true }) }

      it "shows detailed output" do
        allow(generator).to receive(:print_header)
        allow(generator).to receive(:run_all_checks)
        allow(generator).to receive(:print_summary)
        allow(generator).to receive(:exit_with_status)

        expect(generator.options[:verbose]).to be true
      end
    end
  end

  describe "system checks integration" do
    let(:checker) { ReactOnRails::Generators::SystemChecker.new }

    before do
      allow(ReactOnRails::Generators::SystemChecker).to receive(:new).and_return(checker)
    end

    it "creates a system checker instance" do
      allow(generator).to receive(:exit)
      allow(generator).to receive(:puts)
      allow(File).to receive(:exist?).and_return(false)
      allow(File).to receive(:directory?).and_return(false)

      expect(ReactOnRails::Generators::SystemChecker).to receive(:new)
      generator.run_diagnosis
    end

    it "checks all required components" do
      allow(generator).to receive(:exit)
      allow(generator).to receive(:puts)
      allow(File).to receive(:exist?).and_return(false)
      allow(File).to receive(:directory?).and_return(false)

      expect(checker).to receive(:check_node_installation)
      expect(checker).to receive(:check_package_manager)
      expect(checker).to receive(:check_react_on_rails_packages)
      expect(checker).to receive(:check_shakapacker_configuration)
      expect(checker).to receive(:check_react_dependencies)
      expect(checker).to receive(:check_rails_integration)
      expect(checker).to receive(:check_webpack_configuration)

      generator.run_diagnosis
    end
  end

  describe "exit status" do
    before do
      allow(generator).to receive(:puts)
      allow(File).to receive(:exist?).and_return(false)
      allow(File).to receive(:directory?).and_return(false)
    end

    context "when there are errors" do
      it "exits with status 1" do
        checker = ReactOnRails::Generators::SystemChecker.new
        checker.add_error("Test error")
        allow(ReactOnRails::Generators::SystemChecker).to receive(:new).and_return(checker)

        expect(generator).to receive(:exit).with(1)
        generator.run_diagnosis
      end
    end

    context "when there are only warnings" do
      it "exits with status 0" do
        checker = ReactOnRails::Generators::SystemChecker.new
        checker.add_warning("Test warning")
        allow(ReactOnRails::Generators::SystemChecker).to receive(:new).and_return(checker)

        expect(generator).to receive(:exit).with(0)
        generator.run_diagnosis
      end
    end

    context "when all checks pass" do
      it "exits with status 0" do
        checker = ReactOnRails::Generators::SystemChecker.new
        checker.add_success("All good")
        allow(ReactOnRails::Generators::SystemChecker).to receive(:new).and_return(checker)

        expect(generator).to receive(:exit).with(0)
        generator.run_diagnosis
      end
    end
  end
end
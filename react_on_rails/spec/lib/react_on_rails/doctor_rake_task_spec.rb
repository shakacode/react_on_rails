# frozen_string_literal: true

require_relative "../../react_on_rails/spec_helper"
require "rake"

RSpec.describe "doctor rake task" do
  let(:rake_file) { File.expand_path("../../../lib/tasks/doctor.rake", __dir__) }

  before do
    Rake::Task.clear
    load rake_file
  end

  describe "rake react_on_rails:doctor task" do
    it "exists" do
      expect(Rake::Task.task_defined?("react_on_rails:doctor")).to be true
    end

    it "can be loaded without requiring missing task_helpers" do
      # This test ensures the rake file doesn't try to require excluded files
      # that would cause LoadError in packaged gems
      expect { load rake_file }.not_to raise_error
    end

    it "can be invoked without errors" do
      # Mock the Doctor class to avoid actual diagnosis
      doctor_instance = instance_double(ReactOnRails::Doctor)
      allow(ReactOnRails::Doctor).to receive(:new).and_return(doctor_instance)
      allow(doctor_instance).to receive(:run_diagnosis)

      task = Rake::Task["react_on_rails:doctor"]
      expect { task.invoke }.not_to raise_error
    end
  end
end

# frozen_string_literal: true

require_relative "../../react_on_rails/spec_helper"
require "rake"

RSpec.describe "sync_versions rake task" do
  let(:rake_file) { File.expand_path("../../../lib/tasks/sync_versions.rake", __dir__) }
  let(:sync_result) { ReactOnRails::VersionSynchronizer::Result.new(changes: [], changed_files: []) }

  before do
    Rake::Task.clear
    load rake_file
    ENV.delete("WRITE")
    ENV.delete("DRY_RUN")
  end

  after do
    ENV.delete("WRITE")
    ENV.delete("DRY_RUN")
  end

  describe "rake react_on_rails:sync_versions task" do
    it "exists" do
      expect(Rake::Task.task_defined?("react_on_rails:sync_versions")).to be true
    end

    it "runs in dry-run mode by default" do
      synchronizer = instance_double(ReactOnRails::VersionSynchronizer)
      allow(ReactOnRails::VersionSynchronizer).to receive(:new).and_return(synchronizer)
      allow(synchronizer).to receive(:sync).with(write: false).and_return(sync_result)

      task = Rake::Task["react_on_rails:sync_versions"]
      expect { task.invoke }.not_to raise_error
      expect(synchronizer).to have_received(:sync).with(write: false)
    end

    it "runs in write mode when WRITE=true" do
      synchronizer = instance_double(ReactOnRails::VersionSynchronizer)
      allow(ReactOnRails::VersionSynchronizer).to receive(:new).and_return(synchronizer)
      allow(synchronizer).to receive(:sync).with(write: true).and_return(sync_result)

      ENV["WRITE"] = "true"
      task = Rake::Task["react_on_rails:sync_versions"]
      expect { task.invoke }.not_to raise_error
      expect(synchronizer).to have_received(:sync).with(write: true)
    end

    it "raises an error when WRITE=true and DRY_RUN=true" do
      ENV["WRITE"] = "true"
      ENV["DRY_RUN"] = "true"

      task = Rake::Task["react_on_rails:sync_versions"]
      expect { task.invoke }.to raise_error(ReactOnRails::Error, /WRITE and DRY_RUN cannot both be true/)
    end
  end
end

# frozen_string_literal: true

require_relative "../../react_on_rails/spec_helper"
require "rake"

RSpec.describe "sync_versions rake task" do
  let(:rake_file) { File.expand_path("../../../lib/tasks/sync_versions.rake", __dir__) }
  let(:env_seen) { { value: nil } }
  let(:sync_result) do
    ReactOnRails::VersionSynchronizer::Result.new(changes: [],
                                                  changed_files: [],
                                                  unsupported_specs: [],
                                                  missing_source_specs: [])
  end

  before do
    Rake::Task.clear
    Rake::Task.define_task(:environment) do
      env_seen[:value] = ENV.fetch("REACT_ON_RAILS_SKIP_VALIDATION", nil)
    end
    load rake_file
    ENV.delete("WRITE")
    ENV.delete("DRY_RUN")
    ENV.delete("REACT_ON_RAILS_WRITE")
    ENV.delete("REACT_ON_RAILS_DRY_RUN")
    ENV.delete("REACT_ON_RAILS_SKIP_VALIDATION")
  end

  after do
    ENV.delete("WRITE")
    ENV.delete("DRY_RUN")
    ENV.delete("REACT_ON_RAILS_WRITE")
    ENV.delete("REACT_ON_RAILS_DRY_RUN")
    ENV.delete("REACT_ON_RAILS_SKIP_VALIDATION")
  end

  describe "rake react_on_rails:sync_versions task" do
    it "exists" do
      expect(Rake::Task.task_defined?("react_on_rails:sync_versions")).to be true
    end

    it "depends on the Rails environment" do
      task = Rake::Task["react_on_rails:sync_versions"]

      expect(task.prerequisites).to include("environment")
      expect(task.prerequisites).to include("prepare_sync_versions")
    end

    it "sets REACT_ON_RAILS_SKIP_VALIDATION before loading environment" do
      synchronizer = instance_double(ReactOnRails::VersionSynchronizer)
      allow(ReactOnRails::VersionSynchronizer).to receive(:new).and_return(synchronizer)
      allow(synchronizer).to receive(:sync).with(write: false).and_return(sync_result)

      Rake::Task["react_on_rails:sync_versions"].invoke

      expect(env_seen[:value]).to eq("true")
    end

    it "forces REACT_ON_RAILS_SKIP_VALIDATION=true even if set to false" do
      synchronizer = instance_double(ReactOnRails::VersionSynchronizer)
      allow(ReactOnRails::VersionSynchronizer).to receive(:new).and_return(synchronizer)
      allow(synchronizer).to receive(:sync).with(write: false).and_return(sync_result)

      ENV["REACT_ON_RAILS_SKIP_VALIDATION"] = "false"
      Rake::Task["react_on_rails:sync_versions"].invoke

      expect(env_seen[:value]).to eq("true")
    end

    it "runs in dry-run mode by default" do
      synchronizer = instance_double(ReactOnRails::VersionSynchronizer)
      allow(ReactOnRails::VersionSynchronizer).to receive(:new).and_return(synchronizer)
      allow(synchronizer).to receive(:sync).with(write: false).and_return(sync_result)

      task = Rake::Task["react_on_rails:sync_versions"]
      expect { task.invoke }.not_to raise_error
      expect(synchronizer).to have_received(:sync).with(write: false)
    end

    it "runs in dry-run mode when DRY_RUN=true" do
      synchronizer = instance_double(ReactOnRails::VersionSynchronizer)
      allow(ReactOnRails::VersionSynchronizer).to receive(:new).and_return(synchronizer)
      allow(synchronizer).to receive(:sync).with(write: false).and_return(sync_result)

      ENV["DRY_RUN"] = "true"
      ENV.delete("WRITE")
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

    it "runs in write mode when REACT_ON_RAILS_WRITE=true" do
      synchronizer = instance_double(ReactOnRails::VersionSynchronizer)
      allow(ReactOnRails::VersionSynchronizer).to receive(:new).and_return(synchronizer)
      allow(synchronizer).to receive(:sync).with(write: true).and_return(sync_result)

      ENV["REACT_ON_RAILS_WRITE"] = "true"
      task = Rake::Task["react_on_rails:sync_versions"]
      expect { task.invoke }.not_to raise_error
      expect(synchronizer).to have_received(:sync).with(write: true)
    end

    it "runs in dry-run mode when REACT_ON_RAILS_DRY_RUN=true" do
      synchronizer = instance_double(ReactOnRails::VersionSynchronizer)
      allow(ReactOnRails::VersionSynchronizer).to receive(:new).and_return(synchronizer)
      allow(synchronizer).to receive(:sync).with(write: false).and_return(sync_result)

      ENV["REACT_ON_RAILS_DRY_RUN"] = "true"
      task = Rake::Task["react_on_rails:sync_versions"]
      expect { task.invoke }.not_to raise_error
      expect(synchronizer).to have_received(:sync).with(write: false)
    end

    it "raises an error when WRITE=true and DRY_RUN=true" do
      ENV["WRITE"] = "true"
      ENV["DRY_RUN"] = "true"

      task = Rake::Task["react_on_rails:sync_versions"]
      expect { task.invoke }.to raise_error(ReactOnRails::Error, /WRITE and DRY_RUN cannot both be true/)
    end

    it "raises an error when REACT_ON_RAILS_WRITE=true and REACT_ON_RAILS_DRY_RUN=true" do
      ENV["REACT_ON_RAILS_WRITE"] = "true"
      ENV["REACT_ON_RAILS_DRY_RUN"] = "true"

      task = Rake::Task["react_on_rails:sync_versions"]
      expect { task.invoke }.to raise_error(ReactOnRails::Error, /WRITE and DRY_RUN cannot both be true/)
    end
  end
end

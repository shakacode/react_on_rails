# frozen_string_literal: true

require "rake"

RSpec.describe "RBS Rake Tasks" do
  before do
    # Load the rake tasks file
    load File.expand_path("../../rakelib/rbs.rake", __dir__)
  end

  describe "rake rbs:validate" do
    it "is defined" do
      expect(Rake::Task.task_defined?("rbs:validate")).to be true
    end

    it "is a rake task" do
      task = Rake::Task["rbs:validate"]
      expect(task).to be_a(Rake::Task)
    end
  end

  describe "rake rbs:check" do
    it "is defined as alias for validate" do
      expect(Rake::Task.task_defined?("rbs:check")).to be true
    end

    it "depends on validate task" do
      task = Rake::Task["rbs:check"]
      # Prerequisites are stored without namespace when defined with task name: :prerequisite
      expect(task.prerequisites).to include("validate")
    end
  end

  describe "rake rbs:steep" do
    it "is defined" do
      expect(Rake::Task.task_defined?("rbs:steep")).to be true
    end

    it "is a rake task" do
      task = Rake::Task["rbs:steep"]
      expect(task).to be_a(Rake::Task)
    end
  end

  describe "rake rbs:list" do
    it "is defined" do
      expect(Rake::Task.task_defined?("rbs:list")).to be true
    end

    it "is a rake task" do
      task = Rake::Task["rbs:list"]
      expect(task).to be_a(Rake::Task)
    end
  end

  describe "rake rbs:all" do
    it "is defined" do
      expect(Rake::Task.task_defined?("rbs:all")).to be true
    end

    it "depends on validate and steep tasks" do
      task = Rake::Task["rbs:all"]
      # Prerequisites are stored without namespace when defined with task name: :prerequisite
      expect(task.prerequisites).to include("validate", "steep")
    end
  end
end

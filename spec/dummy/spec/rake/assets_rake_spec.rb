# frozen_string_literal: true

require "rake"
require "fileutils"

require "rails_helper"

# can't use it as a closure like you can a lambda
module CustomModule
  def self.custom_production_build_command
    FileUtils.touch(Rails.root.join("tmp", "module_token_file"))
  end
end

describe "assets:webpack task" do
  before do
    paths = [Rails.root.join("..", "..")]
    Rake.application.rake_require("lib/tasks/assets", paths)
    Rake.application.rake_require("lib/tasks/locale", paths)
    Rake::Task.define_task(:environment)
  end

  it "calls build_production_command if build_production_command is a module" do
    filepath = Rails.root.join("tmp", "module_token_file")
    FileUtils.rm_f(filepath)
    expect(File).not_to exist(filepath)

    ReactOnRails.configuration.build_production_command = CustomModule

    Rake::Task["react_on_rails:assets:webpack"].execute

    expect(File).to exist(filepath)
  end

  it "calls build_production_command if build_production_command is a string" do
    filepath = Rails.root.join("tmp", "string_token_file")
    FileUtils.rm_f(filepath)
    expect(File).not_to exist(filepath)

    ReactOnRails.configuration.build_production_command = "touch #{filepath}"

    Rake::Task["react_on_rails:assets:webpack"].execute

    expect(File).to exist(filepath)
  end
end

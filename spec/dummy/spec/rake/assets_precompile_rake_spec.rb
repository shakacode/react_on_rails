# frozen_string_literal: true

require "rake"
require "fileutils"

require "rails_helper"

describe "rake assets:precompile task" do
  it "doesn't show deprecation message for using webpacker:clean task" do
    ENV["SHAKAPACKER_PRECOMPILE"] = "false"

    Rails.application.load_tasks

    ReactOnRails.configure do |config|
      config.build_production_command = "RAILS_ENV=production NODE_ENV=production bin/shakapacker"
    end

    expect do
      Rake::Task["assets:precompile"].execute
    end.not_to output(/Consider using `rake shakapacker:clean`/).to_stdout
  end
end

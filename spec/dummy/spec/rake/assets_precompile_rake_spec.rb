# frozen_string_literal: true

require "rake"

require "rails_helper"
require "react_on_rails"

describe "rake assets:precompile task" do
  it "doesn't show deprecation message for using webpacker:clean task" do
    allow(ENV).to receive(:[]).with(anything).and_call_original
    allow(ENV).to receive(:[]).with("SHAKAPACKER_PRECOMPILE").and_return("false")

    Rails.application.load_tasks

    ReactOnRails.configure do |config|
      config.build_production_command = "RAILS_ENV=production NODE_ENV=production bin/#{ReactOnRails::PackerUtils.packer_type}"
    end

    expect do
      system "bundle install && yarn install && yarn run build:test"
      Rake::Task["assets:precompile"].execute
    end.not_to output(/Consider using `rake shakapacker:clean`/).to_stdout

    Rake::Task.clear
  end
end

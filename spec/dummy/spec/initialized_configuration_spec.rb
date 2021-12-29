# frozen_string_literal: true

require "rails_helper"

describe "ReactOnRails initializer" do
  it "changes ENV[\"WEBPACKER_PRECOMPILE\"] to \"false\" because config.build_production_command is defined" do
    expect(ENV["WEBPACKER_PRECOMPILE"]).to eq("false")
  end
end

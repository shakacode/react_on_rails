# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe "Shakapacker precompile hook shared script" do
  before do
    load File.expand_path("../support/shakapacker_precompile_hook_shared.rb", __dir__)
  end

  it "exposes run_precompile_tasks for load-based callers" do
    allow(self).to receive(:build_rescript_if_needed)
    allow(self).to receive(:generate_packs_if_needed)

    run_precompile_tasks

    expect(self).to have_received(:build_rescript_if_needed)
    expect(self).to have_received(:generate_packs_if_needed)
  end
end

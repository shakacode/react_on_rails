# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe "Shakapacker precompile hook shared script" do
  before do
    load File.expand_path("../support/shakapacker_precompile_hook_shared.rb", __dir__)
  end

  def with_env(overrides)
    # Initialize before any ENV operation that could raise, so the ensure block can always iterate.
    original = {}
    overrides.each_key { |key| original[key] = ENV.fetch(key, nil) }
    overrides.each { |key, value| ENV[key] = value }
    yield
  ensure
    original.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end

  it "exposes run_precompile_tasks for load-based callers" do
    allow(self).to receive(:build_rescript_if_needed)
    allow(self).to receive(:generate_packs_if_needed)
    allow(self).to receive(:generate_rsc_manifest_client_references_if_needed)

    run_precompile_tasks

    expect(self).to have_received(:build_rescript_if_needed)
    expect(self).to have_received(:generate_packs_if_needed)
    expect(self).to have_received(:generate_rsc_manifest_client_references_if_needed)
  end

  describe "valid_rsc_registration_entry_path?" do
    it "rejects registration entries under node_modules, public, or tmp" do
      expect(valid_rsc_registration_entry_path?(
               "/app/node_modules/pkg/client/generated/server-component-registration-entry.js"
             )).to be(false)
      expect(valid_rsc_registration_entry_path?(
               "/app/public/packs/generated/server-component-registration-entry.js"
             )).to be(false)
      expect(valid_rsc_registration_entry_path?(
               "/app/tmp/cache/generated/server-component-registration-entry.js"
             )).to be(false)
    end

    it "accepts a registration entry under the app source tree" do
      expect(valid_rsc_registration_entry_path?(
               "/app/client/app/generated/server-component-registration-entry.js"
             )).to be(true)
    end
  end

  describe "generate_rsc_manifest_client_references_if_needed" do
    it "skips discovery during a reference-discovery build to avoid recursing into itself" do
      allow(self).to receive(:find_rails_root)

      with_env("RSC_REFERENCE_DISCOVERY_BUILD" => "true") do
        generate_rsc_manifest_client_references_if_needed
      end

      expect(self).not_to have_received(:find_rails_root)
    end

    it "does nothing when no server component registration entry is present" do
      allow(self).to receive_messages(find_rails_root: "/rails/root", rsc_manifest_registration_entry: nil)
      allow(self).to receive(:system)

      with_env("RSC_REFERENCE_DISCOVERY_BUILD" => nil) do
        generate_rsc_manifest_client_references_if_needed
      end

      expect(self).not_to have_received(:system)
    end

    it "aborts the precompile with a non-zero exit when the discovery build fails" do
      registration_entry = "/rails/root/client/app/generated/server-component-registration-entry.js"
      allow(self).to receive_messages(find_rails_root: "/rails/root",
                                      rsc_manifest_registration_entry: registration_entry)
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with("/rails/root/bin/shakapacker").and_return(true)
      allow(Dir).to receive(:chdir).and_yield
      allow(self).to receive(:puts)
      allow(self).to receive(:warn)
      allow(self).to receive(:system).and_raise(RuntimeError.new("discovery build failed"))

      with_env("RSC_REFERENCE_DISCOVERY_BUILD" => nil) do
        expect { generate_rsc_manifest_client_references_if_needed }.to raise_error(SystemExit)
      end

      expect(self).to have_received(:warn).with(/RSC manifest client reference generation failed/)
    end
  end
end

# frozen_string_literal: true

require_relative "spec_helper"
require "tmpdir"

RSpec.describe "Shakapacker precompile hook shared script" do
  before do
    load File.expand_path("../support/shakapacker_precompile_hook_shared.rb", __dir__)
  end

  def with_env(overrides)
    # Initialize outside the begin/ensure region so the cleanup always has a hash to iterate,
    # even if an ENV operation in the protected body raises.
    original = {}
    begin
      overrides.each_key { |key| original[key] = ENV.fetch(key, nil) }
      overrides.each { |key, value| ENV[key] = value }
      yield
    ensure
      original.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
    end
  end

  it "preserves setup failures while cleaning any captured env keys" do
    bad_overrides = Object.new

    def bad_overrides.each_key
      raise "env setup failed"
    end

    expect { with_env(bad_overrides) { raise "should not yield" } }.to raise_error(RuntimeError, "env setup failed")
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
    it "rejects registration entries under generated dependency, output, temp, or test trees" do
      expect(valid_rsc_registration_entry_path?(
               "/app/node_modules/pkg/client/generated/server-component-registration-entry.js"
             )).to be(false)
      expect(valid_rsc_registration_entry_path?(
               "/app/public/packs/generated/server-component-registration-entry.js"
             )).to be(false)
      expect(valid_rsc_registration_entry_path?(
               "/app/spec/fixtures/generated/server-component-registration-entry.js"
             )).to be(false)
      expect(valid_rsc_registration_entry_path?(
               "/app/test/fixtures/generated/server-component-registration-entry.js"
             )).to be(false)
      expect(valid_rsc_registration_entry_path?(
               "/app/tmp/cache/generated/server-component-registration-entry.js"
             )).to be(false)
      expect(valid_rsc_registration_entry_path?(
               "/app/.git/objects/generated/server-component-registration-entry.js"
             )).to be(false)
      expect(valid_rsc_registration_entry_path?(
               "/app/vendor/bundle/generated/server-component-registration-entry.js"
             )).to be(false)
      expect(valid_rsc_registration_entry_path?(
               "/app/log/generated/server-component-registration-entry.js"
             )).to be(false)
    end

    it "accepts a registration entry under the app source tree" do
      expect(valid_rsc_registration_entry_path?(
               "/app/client/app/generated/server-component-registration-entry.js"
             )).to be(true)
    end

    it "treats excluded names as path components instead of substrings" do
      expect(valid_rsc_registration_entry_path?(
               "/app/client/tmpfiles/generated/server-component-registration-entry.js"
             )).to be(true)
    end
  end

  describe "rsc_manifest_registration_entry" do
    it "finds app entries without traversing excluded directory trees" do
      Dir.mktmpdir(nil, "/tmp") do |rails_root|
        app_entry = File.join(rails_root, "client", "app", "generated", "server-component-registration-entry.js")
        node_modules_entry = File.join(
          rails_root,
          "node_modules",
          "pkg",
          "generated",
          "server-component-registration-entry.js"
        )
        FileUtils.mkdir_p(File.dirname(app_entry))
        FileUtils.mkdir_p(File.dirname(node_modules_entry))
        File.write(app_entry, "// app\n")
        File.write(node_modules_entry, "// ignored\n")

        expect(rsc_manifest_registration_entry(rails_root)).to eq(app_entry)
      end
    end

    it "ignores generated registration fixtures under spec trees" do
      Dir.mktmpdir(nil, "/tmp") do |rails_root|
        fixture_entry = File.join(
          rails_root,
          "spec",
          "fixtures",
          "automated_packs_generation",
          "generated",
          "server-component-registration-entry.js"
        )
        FileUtils.mkdir_p(File.dirname(fixture_entry))
        File.write(fixture_entry, "// fixture\n")

        expect(rsc_manifest_registration_entry(rails_root)).to be_nil
      end
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

    it "removes stale default client references when no server component registration entry is present" do
      Dir.mktmpdir(nil, "/tmp") do |rails_root|
        stale_manifest = File.join(rails_root, "ssr-generated", "rsc-client-references.json")
        FileUtils.mkdir_p(File.dirname(stale_manifest))
        File.write(stale_manifest, "{}\n")
        allow(self).to receive_messages(find_rails_root: rails_root, rsc_manifest_registration_entry: nil)
        allow(self).to receive(:system)

        with_env("RSC_REFERENCE_DISCOVERY_BUILD" => nil) do
          generate_rsc_manifest_client_references_if_needed
        end

        expect(self).not_to have_received(:system)
        expect(File).not_to exist(stale_manifest)
      end
    end

    it "aborts when a registration entry exists but the shakapacker binstub is missing" do
      registration_entry = "/rails/root/client/app/generated/server-component-registration-entry.js"
      allow(self).to receive_messages(find_rails_root: "/rails/root",
                                      rsc_manifest_registration_entry: registration_entry)
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with("/rails/root/bin/shakapacker").and_return(false)
      allow(self).to receive(:warn)
      allow(self).to receive(:system)

      with_env("RSC_REFERENCE_DISCOVERY_BUILD" => nil) do
        expect { generate_rsc_manifest_client_references_if_needed }.to raise_error(SystemExit)
      end

      expect(self).not_to have_received(:system)
      expect(self).to have_received(:warn).with(%r{bin/shakapacker is missing})
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

    it "clears client/server bundle-only env vars for the nested discovery build" do
      registration_entry = "/rails/root/client/app/generated/server-component-registration-entry.js"
      allow(self).to receive_messages(find_rails_root: "/rails/root",
                                      rsc_manifest_registration_entry: registration_entry)
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with("/rails/root/bin/shakapacker").and_return(true)
      allow(Dir).to receive(:chdir).with("/rails/root").and_yield
      allow(self).to receive(:puts)
      allow(self).to receive(:system)

      with_env(
        "CLIENT_BUNDLE_ONLY" => "true",
        "SERVER_BUNDLE_ONLY" => "true",
        "RSC_REFERENCE_DISCOVERY_BUILD" => nil
      ) do
        generate_rsc_manifest_client_references_if_needed
      end

      expect(self).to have_received(:system).with(
        hash_including(
          "CLIENT_BUNDLE_ONLY" => nil,
          "SERVER_BUNDLE_ONLY" => nil,
          "RSC_BUNDLE_ONLY" => "true",
          "RSC_REFERENCE_DISCOVERY_BUILD" => "true"
        ),
        "/rails/root/bin/shakapacker",
        exception: true
      )
    end
  end
end

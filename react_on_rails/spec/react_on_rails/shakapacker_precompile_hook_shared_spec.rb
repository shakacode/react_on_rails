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

  def with_default_external(encoding)
    original_verbose = $VERBOSE
    $VERBOSE = nil
    original = Encoding.default_external
    Encoding.default_external = encoding
    yield
  ensure
    Encoding.default_external = original
    $VERBOSE = original_verbose
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

  # Without LANG/LC_ALL (C/POSIX locale), Encoding.default_external is US-ASCII, and File.read
  # of files containing non-ASCII characters returns strings that raise on regex match or encode.
  describe "non-UTF-8 default external encoding" do
    it "generates packs when the initializer contains non-ASCII characters" do
      Dir.mktmpdir(nil, "/tmp") do |rails_root|
        initializer_path = File.join(rails_root, "config", "initializers", "react_on_rails.rb")
        FileUtils.mkdir_p(File.dirname(initializer_path))
        File.write(initializer_path, <<~RUBY)
          # ⚠️ auto bundling enabled
          ReactOnRails.configure do |config|
            config.auto_load_bundle = true
          end
        RUBY

        allow(self).to receive_messages(find_rails_root: rails_root, puts: nil)
        allow(Dir).to receive(:chdir)

        # The buggy behavior is warn + exit 1, so guard against SystemExit explicitly —
        # otherwise the exit would abort the whole RSpec process instead of failing the example.
        with_default_external(Encoding::US_ASCII) do
          expect { generate_packs_if_needed }.not_to raise_error
        end

        expect(Dir).to have_received(:chdir).with(rails_root)
      end
    end

    it "builds ReScript when package.json contains non-ASCII characters" do
      Dir.mktmpdir(nil, "/tmp") do |rails_root|
        File.write(File.join(rails_root, "rescript.json"), "{}\n")
        File.write(File.join(rails_root, "package.json"), <<~JSON)
          {
            "description": "ReScript app — non-ASCII description",
            "scripts": { "build:rescript": "rescript build" }
          }
        JSON

        allow(self).to receive_messages(find_rails_root: rails_root, puts: nil)
        allow(Dir).to receive(:chdir)

        with_default_external(Encoding::US_ASCII) do
          expect { build_rescript_if_needed }.not_to raise_error
        end

        expect(Dir).to have_received(:chdir).with(rails_root)
      end
    end

    it "forces a UTF-8 locale for the i18n locale-generation subprocess" do
      Dir.mktmpdir(nil, "/tmp") do |rails_root|
        initializer_path = File.join(rails_root, "config", "initializers", "react_on_rails.rb")
        FileUtils.mkdir_p(File.dirname(initializer_path))
        File.write(initializer_path, <<~RUBY)
          # ⚠️ i18n enabled
          ReactOnRails.configure do |config|
            config.i18n_dir = Rails.root.join("client", "app", "i18n", "generated")
          end
        RUBY

        allow(self).to receive_messages(find_rails_root: rails_root, puts: nil)
        # Run the chdir block so the subprocess invocation is reached, but stub `system`
        # so we capture its env hash instead of actually shelling out to `bundle exec rake`.
        allow(Dir).to receive(:chdir).and_yield
        captured_env = nil
        allow(self).to receive(:system) do |env, *_args|
          captured_env = env
          true
        end

        with_default_external(Encoding::US_ASCII) do
          expect { generate_locales_if_needed }.not_to raise_error
        end

        # Without a forced UTF-8 locale, the spawned `bundle exec` dies parsing a Gemfile with
        # non-ASCII bytes ("invalid byte sequence in US-ASCII"), aborting the whole precompile.
        expect(captured_env).to include("RUBYOPT" => a_string_matching(/-EUTF-8:UTF-8/))
        expect(captured_env).to include("LANG" => a_string_matching(/UTF-8/i))
        expect(captured_env).to include("LC_ALL" => a_string_matching(/UTF-8/i))
        expect(self).to have_received(:system).with(hash_including("RUBYOPT"), "bundle", "exec", "rake",
                                                    "react_on_rails:locale", exception: true)
      end
    end

    it "forces a UTF-8 locale for the pack-generation subprocess" do
      Dir.mktmpdir(nil, "/tmp") do |rails_root|
        initializer_path = File.join(rails_root, "config", "initializers", "react_on_rails.rb")
        FileUtils.mkdir_p(File.dirname(initializer_path))
        File.write(initializer_path, <<~RUBY)
          # ⚠️ auto bundling enabled
          ReactOnRails.configure do |config|
            config.auto_load_bundle = true
          end
        RUBY

        allow(self).to receive_messages(find_rails_root: rails_root, puts: nil)
        allow(Dir).to receive(:chdir).and_yield
        captured_env = nil
        allow(self).to receive(:system) do |env, *_args|
          captured_env = env
          true
        end

        with_default_external(Encoding::US_ASCII) do
          expect { generate_packs_if_needed }.not_to raise_error
        end

        expect(captured_env).to include("RUBYOPT" => a_string_matching(/-EUTF-8:UTF-8/))
        expect(self).to have_received(:system).with(hash_including("RUBYOPT"), "bundle", "exec", "rails",
                                                    "react_on_rails:generate_packs", exception: true)
      end
    end
  end

  describe "#utf8_subprocess_env" do
    it "defaults LANG/LC_ALL to a UTF-8 locale and adds the UTF-8 Ruby pin when unset" do
      with_env("LANG" => nil, "LC_ALL" => nil, "RUBYOPT" => nil) do
        env = utf8_subprocess_env
        expect(env["LANG"]).to match(/UTF-8/i)
        expect(env["LC_ALL"]).to match(/UTF-8/i)
        expect(env["RUBYOPT"]).to eq("-EUTF-8:UTF-8")
      end
    end

    it "preserves an existing UTF-8 locale and keeps the UTF-8 Ruby pin before existing RUBYOPT" do
      with_env("LANG" => "en_US.UTF-8", "LC_ALL" => "en_US.UTF-8", "RUBYOPT" => "-W0") do
        env = utf8_subprocess_env
        expect(env["LANG"]).to eq("en_US.UTF-8")
        expect(env["LC_ALL"]).to eq("en_US.UTF-8")
        expect(env["RUBYOPT"]).to eq("-EUTF-8:UTF-8 -W0")
      end
    end

    it "merges and lets caller keys extend the base env" do
      expect(utf8_subprocess_env("FOO" => "bar")).to include(
        "FOO" => "bar",
        "RUBYOPT" => a_string_matching(/-EUTF-8:UTF-8/)
      )
    end

    it "strips conflicting RUBYOPT encoding flags before pinning UTF-8" do
      conflicting_flags = [
        "-EUS-ASCII",
        "-E US-ASCII",
        "--encoding=US-ASCII",
        "--encoding US-ASCII",
        "--external-encoding=US-ASCII",
        "--external-encoding US-ASCII",
        "--internal-encoding=US-ASCII",
        "--internal-encoding US-ASCII",
        "-KU",
        "-K U",
        "-Ks"
      ]

      conflicting_flags.each do |rubyopt|
        with_env("RUBYOPT" => "-W0 #{rubyopt}") do
          expect(utf8_subprocess_env["RUBYOPT"]).to eq("-EUTF-8:UTF-8 -W0")
        end
      end
    end

    it "strips encoding switches embedded in short-option clusters" do
      expect(force_utf8_rubyopt("-wEUS-ASCII")).to eq("-EUTF-8:UTF-8 -w")
      expect(force_utf8_rubyopt("-wE US-ASCII")).to eq("-EUTF-8:UTF-8 -w")
      expect(force_utf8_rubyopt("-W0EUS-ASCII")).to eq("-EUTF-8:UTF-8 -W0")
      expect(force_utf8_rubyopt("-wKs")).to eq("-EUTF-8:UTF-8 -w")
      expect(force_utf8_rubyopt("-wK U")).to eq("-EUTF-8:UTF-8 -w")
    end

    it "sanitizes caller-supplied RUBYOPT extras instead of dropping the UTF-8 guarantee" do
      with_env("RUBYOPT" => "-W0") do
        env = utf8_subprocess_env("RUBYOPT" => "--encoding=US-ASCII --disable-gems")

        expect(env["RUBYOPT"]).to eq("-EUTF-8:UTF-8 --disable-gems")
      end
    end

    it "preserves non-encoding RUBYOPT flags without shell escaping" do
      with_env("RUBYOPT" => "-IC:\\Ruby\\lib -r json -W0 -EUS-ASCII") do
        expect(utf8_subprocess_env["RUBYOPT"]).to eq("-EUTF-8:UTF-8 -IC:\\Ruby\\lib -r json -W0")
      end
    end

    it "keeps the UTF-8 pin from being consumed by argument-taking Ruby switches" do
      expect(force_utf8_rubyopt("-I")).to eq("-EUTF-8:UTF-8 -I")
      expect(force_utf8_rubyopt("-r")).to eq("-EUTF-8:UTF-8 -r")
      expect(force_utf8_rubyopt("-I -W0")).to eq("-EUTF-8:UTF-8 -I -W0")
      expect(force_utf8_rubyopt("-r json")).to eq("-EUTF-8:UTF-8 -r json")
    end

    it "preserves the UTF-8 guarantee when caller-supplied RUBYOPT is nil" do
      with_env("RUBYOPT" => "-W0") do
        expect(utf8_subprocess_env("RUBYOPT" => nil)["RUBYOPT"]).to eq("-EUTF-8:UTF-8")
      end
    end

    it "normalizes an existing UTF-8 encoding request without duplicating it" do
      with_env("RUBYOPT" => "-EUTF-8") do
        expect(utf8_subprocess_env["RUBYOPT"]).to eq("-EUTF-8:UTF-8")
      end
    end
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
    it "uses an explicit registration entry path without scanning" do
      Dir.mktmpdir(nil, "/tmp") do |rails_root|
        configured_entry = File.join(rails_root, "client", "app", "generated", "server-component-registration-entry.js")
        FileUtils.mkdir_p(File.dirname(configured_entry))
        File.write(configured_entry, "// configured\n")

        expect(Find).not_to receive(:find)

        with_env(
          "REACT_ON_RAILS_RSC_REGISTRATION_ENTRY_PATH" =>
            "client/app/generated/server-component-registration-entry.js"
        ) do
          expect(rsc_manifest_registration_entry(rails_root)).to eq(configured_entry)
        end
      end
    end

    it "falls back to scanning when an explicit registration entry path is missing" do
      Dir.mktmpdir(nil, "/tmp") do |rails_root|
        app_entry = File.join(rails_root, "client", "app", "generated", "server-component-registration-entry.js")
        FileUtils.mkdir_p(File.dirname(app_entry))
        File.write(app_entry, "// app\n")

        with_env("REACT_ON_RAILS_RSC_REGISTRATION_ENTRY_PATH" => "missing/server-component-registration-entry.js") do
          expect(rsc_manifest_registration_entry(rails_root)).to eq(app_entry)
        end
      end
    end

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
      discovery_error = RuntimeError.new("discovery build failed")
      discovery_error.set_backtrace(["bin/shakapacker:12", "config/webpack/rscWebpackConfig.js:4"])
      allow(self).to receive(:system).and_raise(discovery_error)

      with_env("RSC_REFERENCE_DISCOVERY_BUILD" => nil) do
        expect { generate_rsc_manifest_client_references_if_needed }.to raise_error(SystemExit)
      end

      expect(self).to have_received(:warn).with(/RSC manifest client reference generation failed/)
      expect(self).to have_received(:warn).with("bin/shakapacker:12\nconfig/webpack/rscWebpackConfig.js:4")
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
          "RSC_REFERENCE_DISCOVERY_BUILD" => "true",
          # The discovery build also forces a UTF-8 locale so the shakapacker child does not crash
          # under a C/POSIX locale parsing a Gemfile with non-ASCII bytes (see utf8_subprocess_env).
          "RUBYOPT" => a_string_matching(/-EUTF-8:UTF-8/)
        ),
        "/rails/root/bin/shakapacker",
        exception: true
      )
    end
  end
end

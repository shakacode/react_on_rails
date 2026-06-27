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

  # Stub the locale-derived encoding (Encoding.find("locale")). This is the signal utf8_subprocess_env
  # gates on, and unlike Encoding.default_external it cannot be changed at runtime, so tests must stub
  # it to simulate a C/POSIX, UTF-8, or national locale.
  def with_locale_encoding(encoding)
    allow(Encoding).to receive(:find).and_call_original
    allow(Encoding).to receive(:find).with("locale").and_return(encoding)
    yield
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

        with_locale_encoding(Encoding::US_ASCII) do
          with_default_external(Encoding::US_ASCII) do
            expect { generate_locales_if_needed }.not_to raise_error
          end
        end

        # Without a forced UTF-8 locale, the spawned `bundle exec` dies parsing a Gemfile with
        # non-ASCII bytes ("invalid byte sequence in US-ASCII"), aborting the whole precompile.
        expect(captured_env).to include("RUBYOPT" => a_string_matching(/-EUTF-8/))
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

        with_locale_encoding(Encoding::US_ASCII) do
          with_default_external(Encoding::US_ASCII) do
            expect { generate_packs_if_needed }.not_to raise_error
          end
        end

        expect(captured_env).to include("RUBYOPT" => a_string_matching(/-EUTF-8/))
        expect(self).to have_received(:system).with(hash_including("RUBYOPT"), "bundle", "exec", "rails",
                                                    "react_on_rails:generate_packs", exception: true)
      end
    end
  end

  describe "#utf8_subprocess_env" do
    # Functional env keys (skip-validation, bundle-only toggles) are always applied; the difference
    # between locales is only whether we *also* inject a UTF-8 locale/encoding to widen the child.
    context "when the locale encoding is US-ASCII (bare C/POSIX locale)" do
      it "widens the child to UTF-8 via LANG/LC_ALL and an -EUTF-8 RUBYOPT pin" do
        with_locale_encoding(Encoding::US_ASCII) do
          with_env("RUBYOPT" => nil) do
            env = utf8_subprocess_env
            expect(env["LANG"]).to match(/UTF-8/i)
            expect(env["LC_ALL"]).to match(/UTF-8/i)
            expect(env["RUBYOPT"]).to eq("-EUTF-8")
          end
        end
      end

      it "prepends the UTF-8 pin before existing non-encoding RUBYOPT flags" do
        with_locale_encoding(Encoding::US_ASCII) do
          with_env("RUBYOPT" => "-W0") do
            expect(utf8_subprocess_env["RUBYOPT"]).to eq("-EUTF-8 -W0")
          end
        end
      end

      it "honors an encoding already pinned in RUBYOPT rather than overriding or duplicating it" do
        # A deliberate -EUS-ASCII is the user's explicit choice. Prepending -EUTF-8 would both
        # disrespect it and make Ruby raise "default_external already set" on the conflicting -E.
        with_locale_encoding(Encoding::US_ASCII) do
          with_env("RUBYOPT" => "-EUS-ASCII -W0") do
            expect(utf8_subprocess_env["RUBYOPT"]).to eq("-EUS-ASCII -W0")
          end
        end
      end

      it "honors an encoding pinned inside a short-option cluster (no double -E crash)" do
        # -E/-K can be embedded in a cluster like -wEUS-ASCII or -W0EUS-ASCII (no whitespace before
        # E). Prepending -EUTF-8 there would make Ruby raise "default_external already set", so these
        # must be detected and left untouched too.
        with_locale_encoding(Encoding::US_ASCII) do
          ["-wEUS-ASCII", "-W0EUS-ASCII", "-wKs", "-dEUS-ASCII"].each do |rubyopt|
            with_env("RUBYOPT" => rubyopt) do
              expect(utf8_subprocess_env["RUBYOPT"]).to eq(rubyopt)
            end
          end
        end
      end

      it "honors long-form encoding options" do
        ["--encoding=US-ASCII", "--encoding US-ASCII",
         "--external-encoding=US-ASCII", "--external-encoding US-ASCII",
         "--internal-encoding=US-ASCII", "--internal-encoding US-ASCII"].each do |rubyopt|
          with_locale_encoding(Encoding::US_ASCII) do
            with_env("RUBYOPT" => rubyopt) do
              expect(utf8_subprocess_env["RUBYOPT"]).to eq(rubyopt)
            end
          end
        end
      end

      it "still pins UTF-8 for argument-taking flags whose operand begins with E/K" do
        # -r/-I consume their operand, so -rEnglish / -rKconv / -IEpath are NOT encoding requests.
        # The pin must still be added (a regex that matched any E/K after - would wrongly skip these).
        with_locale_encoding(Encoding::US_ASCII) do
          ["-rEnglish", "-rKconv", "-IEpath"].each do |rubyopt|
            with_env("RUBYOPT" => rubyopt) do
              expect(utf8_subprocess_env["RUBYOPT"]).to eq("-EUTF-8 #{rubyopt}")
            end
          end
        end
      end

      it "also widens when the locale encoding is ASCII-8BIT (musl/empty C charmap)" do
        # Some libc/Ruby combinations report a binary/empty locale charmap as ASCII-8BIT rather than
        # US-ASCII; that still means "no real charset", so it must widen the same way.
        with_locale_encoding(Encoding::ASCII_8BIT) do
          with_env("RUBYOPT" => nil) do
            env = utf8_subprocess_env
            expect(env["LANG"]).to match(/UTF-8/i)
            expect(env["RUBYOPT"]).to eq("-EUTF-8")
          end
        end
      end

      it "still applies caller-supplied functional env keys while widening" do
        with_locale_encoding(Encoding::US_ASCII) do
          with_env("RUBYOPT" => nil) do
            expect(utf8_subprocess_env("REACT_ON_RAILS_SKIP_VALIDATION" => "true")).to include(
              "REACT_ON_RAILS_SKIP_VALIDATION" => "true",
              "RUBYOPT" => "-EUTF-8"
            )
          end
        end
      end

      it "keeps the UTF-8 pin even when a caller passes RUBYOPT in extra" do
        # The widening is applied last (authoritative), so an extra RUBYOPT key cannot silently drop
        # the pin and leave the child on US-ASCII.
        with_locale_encoding(Encoding::US_ASCII) do
          with_env("RUBYOPT" => "-W0") do
            expect(utf8_subprocess_env("RUBYOPT" => nil)["RUBYOPT"]).to eq("-EUTF-8 -W0")
          end
        end
      end
    end

    context "when the locale is a real UTF-8 locale" do
      it "leaves LANG/LC_ALL/RUBYOPT untouched so the child inherits the working locale" do
        with_locale_encoding(Encoding::UTF_8) do
          with_env("LANG" => "en_US.UTF-8", "LC_ALL" => "en_US.UTF-8", "RUBYOPT" => "-W0") do
            env = utf8_subprocess_env("FOO" => "bar")
            expect(env).to eq("FOO" => "bar")
            expect(env).not_to have_key("RUBYOPT")
            expect(env).not_to have_key("LANG")
            expect(env).not_to have_key("LC_ALL")
          end
        end
      end
    end

    context "when the locale is a real non-UTF-8 national locale (e.g. pt_BR.ISO8859-1)" do
      # Regression: a developer with an ISO-8859-1/CP1252 locale reads their latin-1 source files
      # correctly as-is. The previous approach force-pinned -EUTF-8 on every subprocess, which
      # re-decoded those files as UTF-8 and raised "invalid byte sequence in UTF-8" — an obscure
      # failure that broke a working setup. US-ASCII is a subset of UTF-8 so widening it is safe;
      # a national encoding is not, so we must leave it alone.
      it "does NOT force UTF-8 and passes the caller env through untouched" do
        with_locale_encoding(Encoding::ISO_8859_1) do
          with_env("LANG" => "pt_BR.ISO8859-1", "LC_ALL" => "pt_BR.ISO8859-1", "RUBYOPT" => nil) do
            env = utf8_subprocess_env("REACT_ON_RAILS_SKIP_VALIDATION" => "true")
            expect(env).to eq("REACT_ON_RAILS_SKIP_VALIDATION" => "true")
            expect(env).not_to have_key("RUBYOPT")
            expect(env).not_to have_key("LANG")
            expect(env).not_to have_key("LC_ALL")
          end
        end
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

      with_locale_encoding(Encoding::US_ASCII) do
        with_env(
          "CLIENT_BUNDLE_ONLY" => "true",
          "SERVER_BUNDLE_ONLY" => "true",
          "RSC_REFERENCE_DISCOVERY_BUILD" => nil
        ) do
          generate_rsc_manifest_client_references_if_needed
        end
      end

      expect(self).to have_received(:system).with(
        hash_including(
          "CLIENT_BUNDLE_ONLY" => nil,
          "SERVER_BUNDLE_ONLY" => nil,
          "RSC_BUNDLE_ONLY" => "true",
          "RSC_REFERENCE_DISCOVERY_BUILD" => "true",
          # Under a bare C/POSIX locale the discovery build widens the shakapacker child to UTF-8 so
          # it does not crash parsing bundle files with non-ASCII bytes (see utf8_subprocess_env).
          "RUBYOPT" => a_string_matching(/-EUTF-8/)
        ),
        "/rails/root/bin/shakapacker",
        exception: true
      )
    end
  end
end

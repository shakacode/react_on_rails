# frozen_string_literal: true

require_relative "spec_helper"

# rubocop:disable Metrics/ModuleLength
module ReactOnRails
  describe PackerUtils do
    describe ".shakapacker_version_requirement_met?" do
      minimum_version = "6.5.3"

      it "returns false when version is lower than minimum_version" do
        allow(described_class).to receive(:shakapacker_version).and_return("6.5.0")

        expect(described_class.shakapacker_version_requirement_met?(minimum_version)).to be(false)

        allow(described_class).to receive(:shakapacker_version).and_return("6.4.7")
        expect(described_class.shakapacker_version_requirement_met?(minimum_version)).to be(false)

        allow(described_class).to receive(:shakapacker_version).and_return("5.7.7")
        expect(described_class.shakapacker_version_requirement_met?(minimum_version)).to be(false)
      end

      it "returns true when version is equal to minimum_version" do
        allow(described_class).to receive(:shakapacker_version).and_return("6.5.3")
        expect(described_class.shakapacker_version_requirement_met?(minimum_version)).to be(true)
      end

      it "returns true when version is greater than minimum_version" do
        allow(described_class).to receive(:shakapacker_version).and_return("6.6.0")
        expect(described_class.shakapacker_version_requirement_met?(minimum_version)).to be(true)

        allow(described_class).to receive(:shakapacker_version).and_return("6.5.4")
        expect(described_class.shakapacker_version_requirement_met?(minimum_version)).to be(true)

        allow(described_class).to receive(:shakapacker_version).and_return("7.0.0")
        expect(described_class.shakapacker_version_requirement_met?(minimum_version)).to be(true)
      end
    end

    describe ".asset_uri_from_packer" do
      let(:asset_name) { "test-asset.js" }
      let(:public_output_path) { "/path/to/public/webpack/dev" }

      context "when dev server is running" do
        before do
          allow(::Shakapacker).to receive(:dev_server).and_return(
            instance_double(
              ::Shakapacker::DevServer,
              running?: true,
              protocol: "http",
              host_with_port: "localhost:3035"
            )
          )

          allow(::Shakapacker).to receive_message_chain("config.public_output_path")
            .and_return(Pathname.new(public_output_path))
          allow(::Shakapacker).to receive_message_chain("config.public_path")
            .and_return(Pathname.new("/path/to/public"))
        end

        it "returns asset URL with dev server path" do
          expected_url = "http://localhost:3035/webpack/dev/test-asset.js"
          expect(described_class.asset_uri_from_packer(asset_name)).to eq(expected_url)
        end
      end

      context "when dev server is not running" do
        before do
          allow(::Shakapacker).to receive_message_chain("dev_server.running?").and_return(false)
          allow(::Shakapacker).to receive_message_chain("config.public_output_path")
            .and_return(Pathname.new(public_output_path))
        end

        it "returns file path to the asset" do
          expected_path = File.join(public_output_path, asset_name)
          expect(described_class.asset_uri_from_packer(asset_name)).to eq(expected_path)
        end
      end
    end

    describe ".supports_async_loading?" do
      it "returns true when ::Shakapacker >= 8.2.0" do
        allow(described_class).to receive(:shakapacker_version_requirement_met?).with("8.2.0").and_return(true)

        expect(described_class.supports_async_loading?).to be(true)
      end

      it "returns false when ::Shakapacker < 8.2.0" do
        allow(described_class).to receive(:shakapacker_version_requirement_met?).with("8.2.0").and_return(false)

        expect(described_class.supports_async_loading?).to be(false)
      end
    end

    describe ".supports_autobundling?" do
      let(:mock_config) { instance_double("::Shakapacker::Config") } # rubocop:disable RSpec/VerifiedDoubleReference
      let(:mock_packer) { instance_double("::Shakapacker", config: mock_config) } # rubocop:disable RSpec/VerifiedDoubleReference

      before do
        allow(::Shakapacker).to receive(:config).and_return(mock_config)
      end

      it "returns true when ::Shakapacker >= 7.0.0 with nested_entries support" do
        allow(mock_config).to receive(:respond_to?).with(:nested_entries?).and_return(true)
        allow(described_class).to receive(:shakapacker_version_requirement_met?)
          .with(ReactOnRails::PacksGenerator::MINIMUM_SHAKAPACKER_VERSION_FOR_AUTO_BUNDLING).and_return(true)

        expect(described_class.supports_autobundling?).to be(true)
      end

      it "returns false when ::Shakapacker < 7.0.0" do
        allow(mock_config).to receive(:respond_to?).with(:nested_entries?).and_return(true)
        allow(described_class).to receive(:shakapacker_version_requirement_met?)
          .with(ReactOnRails::PacksGenerator::MINIMUM_SHAKAPACKER_VERSION_FOR_AUTO_BUNDLING).and_return(false)

        expect(described_class.supports_autobundling?).to be(false)
      end

      it "returns false when nested_entries method is not available" do
        allow(mock_config).to receive(:respond_to?).with(:nested_entries?).and_return(false)
        allow(described_class).to receive(:shakapacker_version_requirement_met?)
          .with(ReactOnRails::PacksGenerator::MINIMUM_SHAKAPACKER_VERSION_FOR_AUTO_BUNDLING).and_return(true)

        expect(described_class.supports_autobundling?).to be(false)
      end
    end

    describe ".extract_precompile_hook" do
      let(:mock_config) { instance_double("::Shakapacker::Config") } # rubocop:disable RSpec/VerifiedDoubleReference

      before do
        allow(::Shakapacker).to receive(:config).and_return(mock_config)
      end

      it "prefers the public precompile_hook API when available" do
        hook_value = "bin/shakapacker-precompile-hook"
        allow(mock_config).to receive(:respond_to?).with(:precompile_hook).and_return(true)
        allow(mock_config).to receive(:precompile_hook).and_return(hook_value)
        expect(mock_config).not_to receive(:send).with(:data)

        expect(described_class.extract_precompile_hook).to eq(hook_value)
      end

      it "falls back to private config data when public API is not available" do
        hook_value = "bundle exec rake react_on_rails:locale"
        allow(mock_config).to receive(:respond_to?).with(:precompile_hook).and_return(false)
        allow(mock_config).to receive(:send).with(:data).and_return({ precompile_hook: hook_value })

        expect(described_class.extract_precompile_hook).to eq(hook_value)
      end

      it "falls back to string key in private config data" do
        hook_value = "bin/shakapacker-precompile-hook"
        allow(mock_config).to receive(:respond_to?).with(:precompile_hook).and_return(false)
        allow(mock_config).to receive(:send).with(:data).and_return({ "precompile_hook" => hook_value })

        expect(described_class.extract_precompile_hook).to eq(hook_value)
      end
    end

    describe ".shakapacker_precompile_hook_configured?" do
      let(:mock_config) { instance_double("::Shakapacker::Config") } # rubocop:disable RSpec/VerifiedDoubleReference

      before do
        allow(::Shakapacker).to receive(:config).and_return(mock_config)
        allow(mock_config).to receive(:respond_to?).with(:precompile_hook).and_return(false)
      end

      context "when precompile_hook is configured" do
        it "returns true when hook command contains generate_packs rake task" do
          hook_value = "bundle exec rake react_on_rails:generate_packs"
          allow(mock_config).to receive(:send).with(:data)
                                              .and_return({ precompile_hook: hook_value })
          expect(described_class.shakapacker_precompile_hook_configured?).to be true
        end

        it "returns true when hook command contains generate_packs_if_stale method" do
          hook_value = "ruby -e 'ReactOnRails::PacksGenerator.instance.generate_packs_if_stale'"
          allow(mock_config).to receive(:send).with(:data)
                                              .and_return({ precompile_hook: hook_value })
          expect(described_class.shakapacker_precompile_hook_configured?).to be true
        end

        it "returns false when hook command doesn't contain generate_packs" do
          allow(mock_config).to receive(:send).with(:data)
                                              .and_return({ precompile_hook: "bin/some-other-command" })
          expect(described_class.shakapacker_precompile_hook_configured?).to be false
        end
      end

      context "when precompile_hook points to a script file" do
        let(:hook_path) { "bin/shakapacker-precompile-hook" }
        let(:script_full_path) { instance_double(Pathname) }
        let(:rails_root) { instance_double(Pathname) }

        before do
          allow(mock_config).to receive(:send).with(:data)
                                              .and_return({ precompile_hook: hook_path })
          allow(Rails).to receive(:root).and_return(rails_root)
          allow(Rails).to receive(:respond_to?).with(:root).and_return(true)
          allow(rails_root).to receive(:join).with(hook_path).and_return(script_full_path)
        end

        it "returns true when script contains generate_packs_if_stale" do
          allow(script_full_path).to receive(:file?).and_return(true)
          allow(File).to receive(:exist?).with(script_full_path).and_return(true)
          allow(File).to receive(:read).with(script_full_path).and_return(<<~RUBY)
            #!/usr/bin/env ruby
            require_relative "../config/environment"
            ReactOnRails::PacksGenerator.instance.generate_packs_if_stale
          RUBY

          expect(described_class.shakapacker_precompile_hook_configured?).to be true
        end

        it "returns true when script contains react_on_rails:generate_packs rake task" do
          allow(script_full_path).to receive(:file?).and_return(true)
          allow(File).to receive(:exist?).with(script_full_path).and_return(true)
          allow(File).to receive(:read).with(script_full_path).and_return(<<~BASH)
            #!/bin/bash
            bundle exec rake react_on_rails:generate_packs
          BASH

          expect(described_class.shakapacker_precompile_hook_configured?).to be true
        end

        it "returns false when script doesn't contain generate_packs" do
          allow(script_full_path).to receive(:file?).and_return(true)
          allow(File).to receive(:exist?).with(script_full_path).and_return(true)
          allow(File).to receive(:read).with(script_full_path).and_return(<<~BASH)
            #!/bin/bash
            echo "Some other precompile hook"
          BASH

          expect(described_class.shakapacker_precompile_hook_configured?).to be false
        end

        it "returns false when script file doesn't exist" do
          allow(script_full_path).to receive(:file?).and_return(false)

          expect(described_class.shakapacker_precompile_hook_configured?).to be false
        end
      end

      context "when precompile_hook is not configured" do
        it "returns false for nil" do
          allow(mock_config).to receive(:send).with(:data).and_return({ precompile_hook: nil })
          expect(described_class.shakapacker_precompile_hook_configured?).to be false
        end

        it "returns false for empty string" do
          allow(mock_config).to receive(:send).with(:data).and_return({ precompile_hook: "" })
          expect(described_class.shakapacker_precompile_hook_configured?).to be false
        end
      end

      context "when Shakapacker is not available" do
        before { hide_const("::Shakapacker") }

        it "returns false" do
          expect(described_class.shakapacker_precompile_hook_configured?).to be false
        end
      end

      context "when config.send raises an error" do
        it "returns false" do
          allow(mock_config).to receive(:send).and_raise(NoMethodError)
          expect(described_class.shakapacker_precompile_hook_configured?).to be false
        end
      end
    end

    describe ".hook_script_has_self_guard?" do
      let(:hook_path) { "bin/shakapacker-precompile-hook" }
      let(:script_full_path) { instance_double(Pathname) }
      let(:rails_root) { instance_double(Pathname) }

      before do
        allow(Rails).to receive(:root).and_return(rails_root)
        allow(Rails).to receive(:respond_to?).with(:root).and_return(true)
        allow(rails_root).to receive(:join).with(hook_path).and_return(script_full_path)
      end

      it "returns true when script contains SHAKAPACKER_SKIP_PRECOMPILE_HOOK" do
        allow(script_full_path).to receive(:file?).and_return(true)
        allow(File).to receive(:read).with(script_full_path).and_return(<<~RUBY)
          #!/usr/bin/env ruby
          exit 0 if ENV["SHAKAPACKER_SKIP_PRECOMPILE_HOOK"] == "true"
          ReactOnRails::PacksGenerator.instance.generate_packs_if_stale
        RUBY

        expect(described_class.hook_script_has_self_guard?(hook_path)).to be true
      end

      it "returns false when script does not contain the self-guard" do
        allow(script_full_path).to receive(:file?).and_return(true)
        allow(File).to receive(:read).with(script_full_path).and_return(<<~RUBY)
          #!/usr/bin/env ruby
          ReactOnRails::PacksGenerator.instance.generate_packs_if_stale
        RUBY

        expect(described_class.hook_script_has_self_guard?(hook_path)).to be false
      end

      it "returns false when script checks the variable but does not exit or return" do
        allow(script_full_path).to receive(:file?).and_return(true)
        allow(File).to receive(:read).with(script_full_path).and_return(<<~RUBY)
          # SHAKAPACKER_SKIP_PRECOMPILE_HOOK should be set by bin/dev
          puts "SHAKAPACKER_SKIP_PRECOMPILE_HOOK"
          if ENV["SHAKAPACKER_SKIP_PRECOMPILE_HOOK"] == "true"
            puts "would skip, but no early exit/return guard"
          end
        RUBY

        expect(described_class.hook_script_has_self_guard?(hook_path)).to be false
      end

      it "returns false when hook value is a direct command (not a script file)" do
        direct_command = "bundle exec rake react_on_rails:locale"
        allow(rails_root).to receive(:join).with(direct_command).and_return(Pathname.new(direct_command))
        allow(Pathname).to receive(:new).and_call_original

        expect(described_class.hook_script_has_self_guard?(direct_command)).to be false
      end

      it "returns false for blank hook value" do
        expect(described_class.hook_script_has_self_guard?("")).to be false
        expect(described_class.hook_script_has_self_guard?(nil)).to be false
      end

      it "returns false when file read raises an error" do
        allow(script_full_path).to receive(:file?).and_return(true)
        allow(File).to receive(:read).with(script_full_path).and_raise(Errno::EACCES)

        expect(described_class.hook_script_has_self_guard?(hook_path)).to be false
      end
    end
  end

  describe "version constants validation" do
    it "ensures autobundling minimum version constant is properly defined" do
      expect(ReactOnRails::PacksGenerator::MINIMUM_SHAKAPACKER_VERSION_FOR_AUTO_BUNDLING).to eq("7.0.0")
    end

    it "validates version checks are cached properly" do
      # Mock the shakapacker_version to avoid dependency on actual version
      allow(ReactOnRails::PackerUtils).to receive(:shakapacker_version).and_return("7.1.0")

      # First call should compute and cache
      result1 = ReactOnRails::PackerUtils.shakapacker_version_requirement_met?("6.5.1")

      # Second call should use cached result
      result2 = ReactOnRails::PackerUtils.shakapacker_version_requirement_met?("6.5.1")

      expect(result1).to eq(result2)
      expect(result1).to be true # 7.1.0 >= 6.5.1
    end
  end
end
# rubocop:enable Metrics/ModuleLength

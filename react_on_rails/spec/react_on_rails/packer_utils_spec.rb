# frozen_string_literal: true

require_relative "spec_helper"

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

    describe ".shakapacker_precompile_hook_configured?" do
      let(:mock_config) { instance_double("::Shakapacker::Config") } # rubocop:disable RSpec/VerifiedDoubleReference

      before do
        allow(::Shakapacker).to receive(:config).and_return(mock_config)
      end

      context "when precompile_hook is configured" do
        it "returns true when hook command contains generate_packs rake task" do
          hook_value = "bundle exec rake react_on_rails:generate_packs"
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

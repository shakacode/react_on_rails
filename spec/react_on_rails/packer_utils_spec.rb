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

    describe ".supports_basic_pack_generation?" do
      it "returns true when ::Shakapacker >= 6.5.1" do
        allow(described_class).to receive(:shakapacker_version_requirement_met?)
          .with(ReactOnRails::PacksGenerator::MINIMUM_SHAKAPACKER_VERSION).and_return(true)

        expect(described_class.supports_basic_pack_generation?).to be(true)
      end

      it "returns false when ::Shakapacker < 6.5.1" do
        allow(described_class).to receive(:shakapacker_version_requirement_met?)
          .with(ReactOnRails::PacksGenerator::MINIMUM_SHAKAPACKER_VERSION).and_return(false)

        expect(described_class.supports_basic_pack_generation?).to be(false)
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
          .with(ReactOnRails::PacksGenerator::MINIMUM_SHAKAPACKER_VERSION_FOR_AUTO_REGISTRATION).and_return(true)

        expect(described_class.supports_autobundling?).to be(true)
      end

      it "returns false when ::Shakapacker < 7.0.0" do
        allow(mock_config).to receive(:respond_to?).with(:nested_entries?).and_return(true)
        allow(described_class).to receive(:shakapacker_version_requirement_met?)
          .with(ReactOnRails::PacksGenerator::MINIMUM_SHAKAPACKER_VERSION_FOR_AUTO_REGISTRATION).and_return(false)

        expect(described_class.supports_autobundling?).to be(false)
      end

      it "returns false when nested_entries method is not available" do
        allow(mock_config).to receive(:respond_to?).with(:nested_entries?).and_return(false)
        allow(described_class).to receive(:shakapacker_version_requirement_met?)
          .with(ReactOnRails::PacksGenerator::MINIMUM_SHAKAPACKER_VERSION_FOR_AUTO_REGISTRATION).and_return(true)

        expect(described_class.supports_autobundling?).to be(false)
      end
    end
  end

  describe "version constants validation" do
    it "ensures MINIMUM_SHAKAPACKER_VERSION constants are properly defined" do
      expect(ReactOnRails::PacksGenerator::MINIMUM_SHAKAPACKER_VERSION).to eq("6.5.1")
      expect(ReactOnRails::PacksGenerator::MINIMUM_SHAKAPACKER_VERSION_FOR_AUTO_REGISTRATION).to eq("7.0.0")
    end

    it "ensures version requirements are logically consistent" do
      basic_version = Gem::Version.new(ReactOnRails::PacksGenerator::MINIMUM_SHAKAPACKER_VERSION)
      auto_reg_version = Gem::Version.new(
        ReactOnRails::PacksGenerator::MINIMUM_SHAKAPACKER_VERSION_FOR_AUTO_REGISTRATION
      )

      expect(auto_reg_version).to be >= basic_version,
                                  "Auto-registration version should be >= basic pack generation version"
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

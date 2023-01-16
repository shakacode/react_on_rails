# frozen_string_literal: true

require_relative "rails_helper"

# rubocop:disable Metrics/ModuleLength
module ReactOnRails
  # rubocop:disable Metrics/BlockLength
  describe PacksGenerator do
    let(:webpacker_source_path) { File.expand_path("fixtures/automated_packs_generation", __dir__) }
    let(:webpacker_source_entry_path) { File.expand_path("fixtures/automated_packs_generation/packs", __dir__) }
    let(:generated_directory) { File.expand_path("fixtures/automated_packs_generation/packs/generated", __dir__) }
    let(:server_bundle_js_file) { "server-bundle.js" }
    let(:server_bundle_js_file_path) do
      File.expand_path("fixtures/automated_packs_generation/packs/#{server_bundle_js_file}", __dir__)
    end
    let(:generated_assets_full_path) do
      File.expand_path("fixtures/automated_packs_generation/packs", __dir__)
    end
    let(:webpack_generated_files) { %w[manifest.json] }

    before do
      ReactOnRails.configuration.server_bundle_js_file = server_bundle_js_file
      ReactOnRails.configuration.components_subdirectory = "ror_components"
      ReactOnRails.configuration.webpack_generated_files = webpack_generated_files

      allow(ReactOnRails::WebpackerUtils).to receive(:manifest_exists?).and_return(true)
      allow(ReactOnRails::WebpackerUtils).to receive(:using_webpacker?).and_return(true)
      allow(ReactOnRails::WebpackerUtils).to receive(:nested_entries?).and_return(true)
      allow(ReactOnRails::WebpackerUtils).to receive(:webpacker_source_entry_path)
        .and_return(webpacker_source_entry_path)
      allow(ReactOnRails::WebpackerUtils).to receive(:shakapacker_version).and_return("6.5.1")
      allow(ReactOnRails::Utils).to receive(:generated_assets_full_path).and_return(generated_assets_full_path)
      allow(ReactOnRails::Utils).to receive(:server_bundle_js_file_path).and_return(server_bundle_js_file_path)
    end

    after do
      ReactOnRails.configuration.server_bundle_js_file = nil
      ReactOnRails.configuration.components_subdirectory = nil

      FileUtils.rm_rf "#{webpacker_source_entry_path}/generated"
      FileUtils.rm_rf generated_server_bundle_file_path
      File.truncate("#{webpacker_source_entry_path}/#{server_bundle_js_file}", 0)
    end

    context "when webpacker is not installed" do
      before do
        allow(ReactOnRails::WebpackerUtils).to receive(:using_webpacker?).and_return(false)
      end

      it "raises an error" do
        msg = <<~MSG
          **ERROR** ReactOnRails: Missing Shakapacker gem. Please upgrade to use Shakapacker \
          6.5.1 or above to use the \
          automated bundle generation feature.
        MSG

        expect { described_class.generate }.to raise_error(ReactOnRails::Error, msg)
      end
    end

    context "when shakapacker version requirements not met" do
      before do
        allow(ReactOnRails::WebpackerUtils).to receive(:shakapacker_version).and_return("6.5.0")
      end

      after do
        allow(ReactOnRails::WebpackerUtils).to receive(:shakapacker_version).and_return("6.5.1")
      end

      it "raises an error" do
        msg = <<~MSG
          **ERROR** ReactOnRails: Please upgrade Shakapacker to version 6.5.1 or \
          above to use the automated bundle generation feature. The currently installed version is \
          6.5.0.
        MSG

        expect { described_class.generate }.to raise_error(ReactOnRails::Error, msg)
      end
    end

    context "when nested_entries not enabled" do
      before do
        allow(ReactOnRails::WebpackerUtils).to receive(:nested_entries?).and_return(false)
      end

      after do
        allow(ReactOnRails::WebpackerUtils).to receive(:nested_entries?).and_return(true)
      end

      it "raises an error" do
        msg = <<~MSG
          **ERROR** ReactOnRails: `nested_entries` is configured to be disabled in shakapacker. Please update \
          webpacker.yml to enable nested entries. for more information read
          https://www.shakacode.com/react-on-rails/docs/guides/file-system-based-automated-bundle-generation.md#enable-nested_entries-for-shakapacker
        MSG

        expect { described_class.generate }.to raise_error(ReactOnRails::Error, msg)
      end
    end

    context "when component with common file only" do
      let(:component_name) { "ComponentWithCommonOnly" }
      let(:component_pack) { "#{generated_directory}/#{component_name}.js" }

      before do
        stub_webpacker_source_path(component_name: component_name,
                                   webpacker_source_path: webpacker_source_path)
        described_class.generate
      end

      it "creates generated pack directory" do
        expect(Pathname.new(generated_directory)).to be_directory
      end

      it "creates generated server bundle file" do
        expect(File.exist?(generated_server_bundle_file_path)).to eq(true)
      end

      it "creates pack for ComponentWithCommonOnly" do
        expect(File.exist?(component_pack)).to eq(true)
      end

      it "generated pack for ComponentWithCommonOnly uses common file for pack" do
        pack_content = File.read(component_pack)

        expect(pack_content).to include("#{component_name}.jsx")
        expect(pack_content).not_to include("#{component_name}.client.jsx")
        expect(pack_content).not_to include("#{component_name}.server.jsx")
      end

      it "generated server bundle uses common file" do
        generated_server_bundle_content = File.read(generated_server_bundle_file_path)

        expect(generated_server_bundle_content).to include("#{component_name}.jsx")
        expect(generated_server_bundle_content).not_to include("#{component_name}.client.jsx")
        expect(generated_server_bundle_content).not_to include("#{component_name}.server.jsx")
      end
    end

    context "when component with client and common File" do
      let(:component_name) { "ComponentWithClientAndCommon" }
      let(:component_pack) { "#{generated_directory}/#{component_name}.js" }

      before do
        stub_webpacker_source_path(component_name: component_name,
                                   webpacker_source_path: webpacker_source_path)
      end

      it "raises an error for definition override" do
        msg = <<~MSG
          **ERROR** ReactOnRails: client specific definition for Component '#{component_name}' overrides the \
          common definition. Please delete the common definition and have separate server and client files. For more \
          information, please see https://www.shakacode.com/react-on-rails/docs/guides/file-system-based-automated-bundle-generation.md
        MSG

        expect { described_class.generate }.to raise_error(ReactOnRails::Error, msg)
      end
    end

    context "when component with server and common file" do
      let(:component_name) { "ComponentWithServerAndCommon" }
      let(:component_pack) { "#{generated_directory}/#{component_name}.js" }

      before do
        allow(ReactOnRails::WebpackerUtils).to receive(:webpacker_source_path)
          .and_return("#{webpacker_source_path}/components/#{component_name}")
      end

      it "raises an error for definition override" do
        msg = <<~MSG
          **ERROR** ReactOnRails: server specific definition for Component '#{component_name}' overrides the \
          common definition. Please delete the common definition and have separate server and client files. For more \
          information, please see https://www.shakacode.com/react-on-rails/docs/guides/file-system-based-automated-bundle-generation.md
        MSG

        expect { described_class.generate }.to raise_error(ReactOnRails::Error, msg)
      end
    end

    context "when component with server, client and common file" do
      let(:component_name) { "ComponentWithCommonClientAndServer" }
      let(:component_pack) { "#{generated_directory}/#{component_name}.js" }

      before do
        stub_webpacker_source_path(component_name: component_name,
                                   webpacker_source_path: webpacker_source_path)
      end

      it "raises an error for definition override" do
        msg =  /Please delete the common definition and have separate server and client files/
        expect { described_class.generate }.to raise_error(ReactOnRails::Error, msg)
      end
    end

    context "when component with server only" do
      let(:component_name) { "ComponentWithServerOnly" }
      let(:component_pack) { "#{generated_directory}/#{component_name}.js" }

      before do
        stub_webpacker_source_path(component_name: component_name,
                                   webpacker_source_path: webpacker_source_path)
      end

      it "raises missing client file error" do
        msg = <<~MSG
          **ERROR** ReactOnRails: Component '#{component_name}' is missing a client specific file. For more \
          information, please see https://www.shakacode.com/react-on-rails/docs/guides/file-system-based-automated-bundle-generation.md
        MSG

        expect { described_class.generate }.to raise_error(ReactOnRails::Error, msg)
      end
    end

    context "when component with client only" do
      let(:component_name) { "ComponentWithClientOnly" }
      let(:component_pack) { "#{generated_directory}/#{component_name}.js" }

      before do
        stub_webpacker_source_path(component_name: component_name,
                                   webpacker_source_path: webpacker_source_path)
        described_class.generate
      end

      it "creates generated pack directory" do
        expect(Pathname.new(generated_directory)).to be_directory
      end

      it "creates generated server bundle file" do
        expect(File.exist?(generated_server_bundle_file_path)).to eq(true)
      end

      it "creates pack for ComponentWithClientOnly" do
        expect(File.exist?(component_pack)).to eq(true)
      end

      it "generated pack for ComponentWithClientOnly uses client file for pack" do
        pack_content = File.read(component_pack)

        expect(pack_content).to include("#{component_name}.client.jsx")
        expect(pack_content).not_to include("#{component_name}.jsx")
        expect(pack_content).not_to include("#{component_name}.server.jsx")
      end

      it "generated server bundle do not have ComponentWithClientOnly registered" do
        generated_server_bundle_content = File.read(generated_server_bundle_file_path)

        expect(generated_server_bundle_content).not_to include("#{component_name}.jsx")
        expect(generated_server_bundle_content).not_to include("#{component_name}.client.jsx")
        expect(generated_server_bundle_content).not_to include("#{component_name}.server.jsx")
      end
    end

    def generated_server_bundle_file_path
      "#{webpacker_source_entry_path}/server-bundle-generated.js"
    end

    def stub_webpacker_source_path(webpacker_source_path:, component_name:)
      allow(ReactOnRails::WebpackerUtils).to receive(:webpacker_source_path)
        .and_return("#{webpacker_source_path}/components/#{component_name}")
    end
  end
  # rubocop:enable Metrics/BlockLength
end
# rubocop:enable Metrics/ModuleLength

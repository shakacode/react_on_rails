# frozen_string_literal: true

require_relative "spec_helper"

module ReactOnRails
  describe PacksGenerator do
    let(:webpacker_source_path) { File.expand_path("fixtures/automated_packs_generation", __dir__) }
    let(:webpacker_source_entry_path) { File.expand_path("fixtures/automated_packs_generation/packs", __dir__) }
    let(:generated_directory) { File.expand_path("fixtures/automated_packs_generation/packs/generated", __dir__) }
    let(:server_bundle_js_file) { "server-bundle.js" }

    before do
      ReactOnRails.configuration.server_bundle_js_file = server_bundle_js_file
      ReactOnRails.configuration.components_directory = "ror_components"
      allow(ReactOnRails::WebpackerUtils).to receive(:using_webpacker?).and_return(true)
      allow(ReactOnRails::WebpackerUtils).to receive(:webpacker_source_path).and_return(webpacker_source_path)
      allow(ReactOnRails::WebpackerUtils).to receive(:webpacker_source_entry_path)
        .and_return(webpacker_source_entry_path)

      described_class.generate
    end

    after do
      ReactOnRails.configuration.server_bundle_js_file = nil
      ReactOnRails.configuration.components_directory = nil

      FileUtils.rm_rf("#{webpacker_source_entry_path}/generated")
      FileUtils.rm(generated_server_bundle_file_path)
      File.truncate("#{webpacker_source_entry_path}/#{server_bundle_js_file}", 0)
    end

    it "creates generated pack directory" do
      expect(Pathname.new(generated_directory)).to be_directory
    end

    it "creates generated server bundle file" do
      expect(File.exist?(generated_server_bundle_file_path)).to eq(true)
    end

    it "imports generated server bundle to original server bundle" do
      server_bundle_file_path = "#{webpacker_source_entry_path}/#{server_bundle_js_file}"
      server_bundle_content = File.read(server_bundle_file_path)

      expect(server_bundle_content).to include("import \"./server-bundle-generated.js\"")
    end

    context "when component with common file only" do
      let(:component_name) { "ComponentWithCommonOnly" }
      let(:component_pack) { "#{generated_directory}/#{component_name}.jsx" }

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
      let(:component_pack) { "#{generated_directory}/#{component_name}.jsx" }

      it "creates pack for ComponentWithClientAndCommon" do
        expect(File.exist?(component_pack)).to eq(true)
      end

      it "generated pack for ComponentWithClientAndCommon uses client specific file for pack" do
        pack_content = File.read(component_pack)

        expect(pack_content).to include("#{component_name}.client.jsx")
        expect(pack_content).not_to include("#{component_name}.server.jsx")
        expect(pack_content).not_to include("#{component_name}.jsx")
      end

      it "generated server bundle uses common file" do
        generated_server_bundle_content = File.read(generated_server_bundle_file_path)

        expect(generated_server_bundle_content).to include("#{component_name}.jsx")
        expect(generated_server_bundle_content).not_to include("#{component_name}.client.jsx")
        expect(generated_server_bundle_content).not_to include("#{component_name}.server.jsx")
      end
    end

    context "when component with server and common file" do
      let(:component_name) { "ComponentWithServerAndCommon" }
      let(:component_pack) { "#{generated_directory}/#{component_name}.jsx" }

      it "creates pack for ComponentWithServerAndCommon" do
        expect(File.exist?(component_pack)).to eq(true)
      end

      it "generated pack for ComponentWithServerAndCommon uses the common file for pack" do
        pack_content = File.read(component_pack)

        expect(pack_content).to include("#{component_name}.jsx")
        expect(pack_content).not_to include("#{component_name}.client.jsx")
        expect(pack_content).not_to include("#{component_name}.server.jsx")
      end

      it "generated server bundle uses server specific file" do
        generated_server_bundle_content = File.read(generated_server_bundle_file_path)

        expect(generated_server_bundle_content).to include("#{component_name}.server.jsx")
        expect(generated_server_bundle_content).not_to include("#{component_name}.jsx")
        expect(generated_server_bundle_content).not_to include("#{component_name}.client.jsx")
      end
    end

    context "when component with server, client and common file" do
      let(:component_name) { "ComponentWithCommonClientAndServer" }
      let(:component_pack) { "#{generated_directory}/#{component_name}.jsx" }

      it "creates pack for ComponentWithCommonClientAndServer" do
        expect(File.exist?(component_pack)).to eq(true)
      end

      it "generated pack for ComponentWithCommonClientAndServer uses client file for pack" do
        pack_content = File.read(component_pack)

        expect(pack_content).to include("#{component_name}.client.jsx")
        expect(pack_content).not_to include("#{component_name}.jsx")
        expect(pack_content).not_to include("#{component_name}.server.jsx")
      end

      it "generated server bundle uses server specific file" do
        generated_server_bundle_content = File.read(generated_server_bundle_file_path)

        expect(generated_server_bundle_content).to include("#{component_name}.server.jsx")
        expect(generated_server_bundle_content).not_to include("#{component_name}.jsx")
        expect(generated_server_bundle_content).not_to include("#{component_name}.client.jsx")
      end
    end

    def generated_server_bundle_file_path
      "#{webpacker_source_entry_path}/server-bundle-generated.js"
    end
  end
end

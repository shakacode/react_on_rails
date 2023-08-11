# frozen_string_literal: true

require "rails_helper"

# rubocop:disable Metrics/ModuleLength
module ReactOnRails
  GENERATED_PACKS_CONSOLE_OUTPUT_REGEX = /Generated Packs:/.freeze

  # rubocop:disable Metrics/BlockLength
  describe PacksGenerator do
    let(:webpacker_source_path) { File.expand_path("./fixtures/automated_packs_generation", __dir__) }
    let(:webpacker_source_entry_path) { File.expand_path("./fixtures/automated_packs_generation/packs", __dir__) }
    let(:generated_directory) { File.expand_path("./fixtures/automated_packs_generation/packs/generated", __dir__) }
    let(:server_bundle_js_file) { "server-bundle.js" }
    let(:server_bundle_js_file_path) do
      File.expand_path("./fixtures/automated_packs_generation/packs/#{server_bundle_js_file}", __dir__)
    end
    let(:webpack_generated_files) { %w[manifest.json] }

    let(:old_server_bundle) { ReactOnRails.configuration.server_bundle_js_file }
    let(:old_subdirectory) { ReactOnRails.configuration.components_subdirectory }
    let(:old_auto_load_bundle) { ReactOnRails.configuration.auto_load_bundle }

    before do
      ReactOnRails.configuration.server_bundle_js_file = server_bundle_js_file
      ReactOnRails.configuration.components_subdirectory = "ror_components"
      ReactOnRails.configuration.webpack_generated_files = webpack_generated_files

      allow(ReactOnRails::WebpackerUtils).to receive_messages(
        manifest_exists?: true,
        using_webpacker?: true,
        nested_entries?: true,
        webpacker_source_entry_path: webpacker_source_entry_path, shakapacker_version: "7.0.0"
      )
      allow(ReactOnRails::Utils).to receive_messages(generated_assets_full_path: webpacker_source_entry_path,
                                                     server_bundle_js_file_path: server_bundle_js_file_path)
    end

    after do
      ReactOnRails.configuration.server_bundle_js_file = old_server_bundle
      ReactOnRails.configuration.components_subdirectory = old_subdirectory

      FileUtils.rm_rf "#{webpacker_source_entry_path}/generated"
      FileUtils.rm_rf generated_server_bundle_file_path
      File.truncate(server_bundle_js_file_path, 0)
    end

    context "when the generated server bundle is configured as ReactOnRails.configuration.server_bundle_js_file" do
      it "generates the server bundle within the source_entry_point" do
        FileUtils.mv(server_bundle_js_file_path, "./temp")
        FileUtils.rm_rf server_bundle_js_file_path
        ReactOnRails.configuration.make_generated_server_bundle_the_entrypoint = true
        described_class.instance.generate_packs_if_stale
        expect(File.exist?(server_bundle_js_file_path)).to equal(true)
        expect(File.exist?("#{Pathname(webpacker_source_entry_path).parent}/server-bundle-generated.js"))
          .to equal(false)
        FileUtils.mv("./temp", server_bundle_js_file_path)
        ReactOnRails.configuration.make_generated_server_bundle_the_entrypoint = false
      end
    end

    context "when component with common file only" do
      let(:component_name) { "ComponentWithCommonOnly" }
      let(:component_pack) { "#{generated_directory}/#{component_name}.js" }

      before do
        stub_webpacker_source_path(component_name: component_name,
                                   webpacker_source_path: webpacker_source_path)
        described_class.instance.generate_packs_if_stale
      end

      it "creates generated pack directory" do
        expect(Pathname.new(generated_directory)).to be_directory
      end

      it "creates generated server bundle file" do
        expect(File.exist?(generated_server_bundle_file_path)).to equal(true)
      end

      it "creates pack for ComponentWithCommonOnly" do
        expect(File.exist?(component_pack)).to be(true)
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

        expect { described_class.instance.generate_packs_if_stale }.to raise_error(ReactOnRails::Error, msg)
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

        expect { described_class.instance.generate_packs_if_stale }.to raise_error(ReactOnRails::Error, msg)
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
        expect { described_class.instance.generate_packs_if_stale }.to raise_error(ReactOnRails::Error, msg)
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

        expect { described_class.instance.generate_packs_if_stale }.to raise_error(ReactOnRails::Error, msg)
      end
    end

    context "when component with client only" do
      let(:component_name) { "ComponentWithClientOnly" }
      let(:component_pack) { "#{generated_directory}/#{component_name}.js" }

      before do
        stub_webpacker_source_path(component_name: component_name,
                                   webpacker_source_path: webpacker_source_path)
        described_class.instance.generate_packs_if_stale
      end

      it "creates generated pack directory" do
        expect(Pathname.new(generated_directory)).to be_directory
      end

      it "creates generated server bundle file" do
        expect(File.exist?(generated_server_bundle_file_path)).to be(true)
      end

      it "creates pack for ComponentWithClientOnly" do
        expect(File.exist?(component_pack)).to be(true)
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

    context "when pack generator is called" do
      let(:component_name) { "ComponentWithCommonOnly" }
      let(:component_pack) { "#{generated_directory}/#{component_name}.js" }

      before do
        stub_webpacker_source_path(component_name: component_name,
                                   webpacker_source_path: webpacker_source_path)
        FileUtils.mkdir_p(generated_directory)
        File.write(component_pack, "wat")
        File.write(generated_server_bundle_file_path, "wat")
      end

      after do
        FileUtils.rm_rf generated_directory
        FileUtils.rm generated_server_bundle_file_path
      end

      it "does not generate packs if there are no new components or stale files" do
        expect do
          described_class.instance.generate_packs_if_stale
        end.not_to output(GENERATED_PACKS_CONSOLE_OUTPUT_REGEX).to_stdout
      end

      it "generate packs if a new component is added" do
        create_new_component("NewComponent")

        expect do
          described_class.instance.generate_packs_if_stale
        end.to output(GENERATED_PACKS_CONSOLE_OUTPUT_REGEX).to_stdout
        FileUtils.rm "#{webpacker_source_path}/components/ComponentWithCommonOnly/ror_components/NewComponent.jsx"
      end

      it "generate packs if an old component is updated" do
        FileUtils.rm component_pack
        create_new_component(component_name)

        expect do
          described_class.instance.generate_packs_if_stale
        end.to output(GENERATED_PACKS_CONSOLE_OUTPUT_REGEX).to_stdout
      end

      def create_new_component(name)
        components_subdirectory = ReactOnRails.configuration.components_subdirectory
        path = "#{webpacker_source_path}/components/#{component_name}/#{components_subdirectory}/#{name}.jsx"

        File.write(path, "// Empty Test Component\n")
      end
    end

    context "when components subdirectory is not set & auto_load_bundle is false" do
      it "does not generate packs" do
        old_sub = old_subdirectory
        old_auto = old_auto_load_bundle
        ReactOnRails.configuration.components_subdirectory = nil
        ReactOnRails.configuration.auto_load_bundle = false
        expect do
          described_class.instance.generate_packs_if_stale
        end.not_to output(GENERATED_PACKS_CONSOLE_OUTPUT_REGEX).to_stdout
        ReactOnRails.configuration.components_subdirectory = old_sub
        ReactOnRails.configuration.auto_load_bundle = old_auto
      end
    end

    def generated_server_bundle_file_path
      described_class.instance.send(:generated_server_bundle_file_path)
    end

    def stub_webpacker_source_path(webpacker_source_path:, component_name:)
      allow(ReactOnRails::WebpackerUtils).to receive(:webpacker_source_path)
        .and_return("#{webpacker_source_path}/components/#{component_name}")
    end
  end
  # rubocop:enable Metrics/BlockLength
end
# rubocop:enable Metrics/ModuleLength

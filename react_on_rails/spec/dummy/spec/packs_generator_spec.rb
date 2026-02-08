# frozen_string_literal: true

require "rails_helper"

# rubocop:disable Metrics/ModuleLength
module ReactOnRails
  GENERATED_PACKS_CONSOLE_OUTPUT_REGEX = /Generated Packs:/

  # rubocop:disable Metrics/BlockLength
  describe PacksGenerator do
    let(:packer_source_path) { File.expand_path("./fixtures/automated_packs_generation", __dir__) }
    let(:packer_source_entry_path) { File.expand_path("./fixtures/automated_packs_generation/packs", __dir__) }
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
      stub_const("ReactOnRailsPro", Class.new do
        def self.configuration
          @configuration ||= Struct.new(:enable_rsc_support).new(false)
        end
      end)
      ReactOnRails.configuration.server_bundle_js_file = server_bundle_js_file
      ReactOnRails.configuration.components_subdirectory = "ror_components"
      ReactOnRails.configuration.webpack_generated_files = webpack_generated_files
      allow(ReactOnRails::PackerUtils).to receive_messages(
        manifest_exists?: true,
        nested_entries?: true,
        packer_source_entry_path: packer_source_entry_path
      )
      allow(ReactOnRails::Utils).to receive_messages(generated_assets_full_path: packer_source_entry_path,
                                                     server_bundle_js_file_path: server_bundle_js_file_path)
      if ReactOnRails::Utils.instance_variable_defined?(:@rsc_support_enabled)
        ReactOnRails::Utils.remove_instance_variable(:@rsc_support_enabled)
      end
    end

    after do
      ReactOnRails.configuration.server_bundle_js_file = old_server_bundle
      ReactOnRails.configuration.components_subdirectory = old_subdirectory

      FileUtils.rm_rf "#{packer_source_entry_path}/generated"
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
        expect(File.exist?("#{Pathname(packer_source_entry_path).parent}/server-bundle-generated.js"))
          .to equal(false)
        FileUtils.mv("./temp", server_bundle_js_file_path)
        ReactOnRails.configuration.make_generated_server_bundle_the_entrypoint = false
      end
    end

    context "when component with common file only" do
      let(:component_name) { "ComponentWithCommonOnly" }
      let(:component_pack) { "#{generated_directory}/#{component_name}.js" }

      before do
        stub_packer_source_path(component_name: component_name,
                                packer_source_path: packer_source_path)
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

      it "uses react-on-rails package when pro is not available" do
        generated_server_bundle_content = File.read(generated_server_bundle_file_path)
        pack_content = File.read(component_pack)

        expect(generated_server_bundle_content).to include("import ReactOnRails from 'react-on-rails';")
        expect(generated_server_bundle_content).not_to include("import ReactOnRails from 'react-on-rails-pro';")
        expect(pack_content).to include("import ReactOnRails from 'react-on-rails/client';")
        expect(pack_content).not_to include("import ReactOnRails from 'react-on-rails-pro/client';")
      end
    end

    context "when component with client and common File" do
      let(:component_name) { "ComponentWithClientAndCommon" }
      let(:component_pack) { "#{generated_directory}/#{component_name}.js" }

      before do
        stub_packer_source_path(component_name: component_name,
                                packer_source_path: packer_source_path)
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
        allow(ReactOnRails::PackerUtils).to receive(:packer_source_path)
          .and_return("#{packer_source_path}/components/#{component_name}")
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
        stub_packer_source_path(component_name: component_name,
                                packer_source_path: packer_source_path)
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
        stub_packer_source_path(component_name: component_name,
                                packer_source_path: packer_source_path)
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
        stub_packer_source_path(component_name: component_name,
                                packer_source_path: packer_source_path)
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

    context "when RSC support is enabled" do
      let(:components_directory) { "ReactServerComponents" }

      before do
        stub_packer_source_path(component_name: components_directory,
                                packer_source_path: packer_source_path)
        allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(true)
        stub_const("ReactOnRailsPro::Utils", Class.new do
          def self.rsc_support_enabled?
            true
          end
        end)
        allow(ReactOnRailsPro::Utils).to receive_messages(
          rsc_support_enabled?: true
        )
      end

      context "when common component is not a client entrypoint" do
        before do
          described_class.instance.generate_packs_if_stale
        end

        it "creates pack with server component registration" do
          component_name = "ReactServerComponent"
          component_pack = "#{generated_directory}/#{component_name}.js"
          pack_content = File.read(component_pack)
          expected_content = <<~CONTENT.strip
            import registerServerComponent from 'react-on-rails-pro/registerServerComponent/client';

            registerServerComponent("#{component_name}");
          CONTENT

          expect(pack_content).to eq(expected_content)
        end
      end

      context "when client component is not a client entrypoint" do
        before do
          described_class.instance.generate_packs_if_stale
        end

        it "creates pack with client component registration" do
          component_name = "ReactClientComponentWithClientAndServer"
          component_pack = "#{generated_directory}/#{component_name}.js"
          pack_content = File.read(component_pack)
          expect(pack_content).to include("import ReactOnRails from 'react-on-rails-pro/client';")
          expect(pack_content).to include("ReactOnRails.register({#{component_name}});")
          expect(pack_content).not_to include("registerServerComponent")
        end
      end

      context "when server component is a client entrypoint" do
        before do
          described_class.instance.generate_packs_if_stale
        end

        it "creates pack with server component registration" do
          component_name = "ReactServerComponentWithClientAndServer"
          component_pack = "#{generated_directory}/#{component_name}.js"
          pack_content = File.read(component_pack)
          expected_content = <<~CONTENT.strip
            import registerServerComponent from 'react-on-rails-pro/registerServerComponent/client';

            registerServerComponent("#{component_name}");
          CONTENT

          expect(pack_content).to eq(expected_content)
        end
      end

      context "when common component is a client entrypoint" do
        before do
          described_class.instance.generate_packs_if_stale
        end

        it "creates pack with client component registration" do
          component_name = "ReactClientComponent"
          component_pack = "#{generated_directory}/#{component_name}.js"
          pack_content = File.read(component_pack)
          expect(pack_content).to include("import ReactOnRails from 'react-on-rails-pro/client';")
          expect(pack_content).to include("ReactOnRails.register({#{component_name}});")
          expect(pack_content).not_to include("registerServerComponent")
        end
      end

      context "when RSC support is disabled" do
        before do
          allow(ReactOnRailsPro::Utils).to receive(:rsc_support_enabled?).and_return(false)
          described_class.instance.generate_packs_if_stale
        end

        it "creates pack with client component registration" do
          component_name = "ReactServerComponent"
          component_pack = "#{generated_directory}/#{component_name}.js"
          pack_content = File.read(component_pack)
          expect(pack_content).to include("import ReactOnRails from 'react-on-rails-pro/client';")
          expect(pack_content).to include("ReactOnRails.register({#{component_name}});")
          expect(pack_content).not_to include("registerServerComponent")
        end
      end

      context "when not using ReactOnRailsPro" do
        before do
          allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(false)
          described_class.instance.generate_packs_if_stale
        end

        it "creates pack with client component registration" do
          component_name = "ReactServerComponent"
          component_pack = "#{generated_directory}/#{component_name}.js"
          pack_content = File.read(component_pack)
          expect(pack_content).to include("import ReactOnRails from 'react-on-rails/client';")
          expect(pack_content).to include("ReactOnRails.register({#{component_name}});")
          expect(pack_content).not_to include("registerServerComponent")
        end
      end

      context "when registered on server bundle" do
        before do
          described_class.instance.generate_packs_if_stale
        end

        it "register server components using registerServerComponent" do
          generated_server_bundle_path = File.join(
            Pathname(packer_source_entry_path).parent,
            "generated/server-bundle-generated.js"
          )
          generated_server_bundle_content = File.read(generated_server_bundle_path)
          expected_content = <<~CONTENT.strip
            import ReactOnRails from 'react-on-rails-pro';

            import ReactClientComponent from '../components/ReactServerComponents/ror_components/ReactClientComponent.jsx';
            import ReactServerComponent from '../components/ReactServerComponents/ror_components/ReactServerComponent.jsx';
            import ReactClientComponentWithClientAndServer from '../components/ReactServerComponents/ror_components/ReactClientComponentWithClientAndServer.server.jsx';
            import ReactServerComponentWithClientAndServer from '../components/ReactServerComponents/ror_components/ReactServerComponentWithClientAndServer.server.jsx';

            import registerServerComponent from 'react-on-rails-pro/registerServerComponent/server';
            registerServerComponent({ReactServerComponent,
            ReactServerComponentWithClientAndServer});

            ReactOnRails.register({ReactClientComponent,
            ReactClientComponentWithClientAndServer});
          CONTENT

          expect(generated_server_bundle_content.strip).to eq(expected_content.strip)
        end
      end
    end

    context "when pack generator is called" do
      let(:component_name) { "ComponentWithCommonOnly" }
      let(:component_pack) { "#{generated_directory}/#{component_name}.js" }

      before do
        stub_packer_source_path(component_name: component_name,
                                packer_source_path: packer_source_path)
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

      it "adds a single import statement to the server bundle" do
        test_string = "// import statement added by react_on_rails:generate_packs"
        same_instance = described_class.instance
        File.truncate(server_bundle_js_file_path, 0)
        same_instance.generate_packs_if_stale
        expect(File.read(server_bundle_js_file_path).scan(/(?=#{test_string})/).count).to equal(1)
        # the following expectation checks that an additional import statement is not added if one already exists
        same_instance.generate_packs_if_stale
        expect(File.read(server_bundle_js_file_path).scan(/(?=#{test_string})/).count).to equal(1)
      end

      it "generate packs if a new component is added" do
        create_new_component("NewComponent")

        # Set verbose mode to see pack generation output
        ENV["REACT_ON_RAILS_VERBOSE"] = "true"
        expect do
          described_class.instance.generate_packs_if_stale
        end.to output(GENERATED_PACKS_CONSOLE_OUTPUT_REGEX).to_stdout
        ENV.delete("REACT_ON_RAILS_VERBOSE")
        FileUtils.rm "#{packer_source_path}/components/ComponentWithCommonOnly/ror_components/NewComponent.jsx"
      end

      it "generate packs if an old component is updated" do
        FileUtils.rm component_pack
        create_new_component(component_name)

        # Set verbose mode to see pack generation output
        ENV["REACT_ON_RAILS_VERBOSE"] = "true"
        expect do
          described_class.instance.generate_packs_if_stale
        end.to output(GENERATED_PACKS_CONSOLE_OUTPUT_REGEX).to_stdout
        ENV.delete("REACT_ON_RAILS_VERBOSE")
      end

      def create_new_component(name)
        components_subdirectory = ReactOnRails.configuration.components_subdirectory
        path = "#{packer_source_path}/components/#{component_name}/#{components_subdirectory}/#{name}.jsx"

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

    context "when react_on_rails_pro? is explicitly false" do
      let(:component_name) { "ComponentWithCommonOnly" }
      let(:component_pack) { "#{generated_directory}/#{component_name}.js" }

      before do
        allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(false)
        stub_packer_source_path(component_name: component_name,
                                packer_source_path: packer_source_path)
        described_class.instance.generate_packs_if_stale
      end

      it "imports from react-on-rails in server bundle" do
        generated_server_bundle_content = File.read(generated_server_bundle_file_path)
        expect(generated_server_bundle_content).to include("import ReactOnRails from 'react-on-rails';")
        expect(generated_server_bundle_content).not_to include("import ReactOnRails from 'react-on-rails-pro';")
      end

      it "imports from react-on-rails/client in component pack" do
        pack_content = File.read(component_pack)
        expect(pack_content).to include("import ReactOnRails from 'react-on-rails/client';")
        expect(pack_content).not_to include("import ReactOnRails from 'react-on-rails-pro/client';")
      end

      it "does not import registerServerComponent" do
        pack_content = File.read(component_pack)
        expect(pack_content).not_to include("registerServerComponent")
      end
    end

    context "when component with CSS module" do
      let(:component_name) { "ComponentWithCSSModule" }
      let(:component_pack) { "#{generated_directory}/#{component_name}.js" }
      let(:css_module_pack_glob_pattern) { "#{generated_directory}/#{component_name}.module*" }

      before do
        stub_packer_source_path(component_name: component_name,
                                packer_source_path: packer_source_path)
        described_class.instance.generate_packs_if_stale
      end

      it "generates a pack with valid JavaScript variable names" do
        expect(File.exist?(component_pack)).to be(true)
        pack_content = File.read(component_pack)

        # Check that the generated pack content is valid JavaScript
        expect(pack_content).to include("import ReactOnRails from 'react-on-rails/client';")
        expect(pack_content).to include("import #{component_name} from")
        expect(pack_content).to include("ReactOnRails.register({#{component_name}});")

        # Verify that variable names don't contain dots (invalid in JS)
        expect(pack_content).not_to match(/ComponentWithCSSModule\.module/)
        expect(pack_content).not_to match(/import .+\.module/)
      end

      it "generates valid JavaScript that can be parsed without syntax errors" do
        pack_content = File.read(component_pack)

        # This would fail if the generated JavaScript has syntax errors
        # rubocop:disable Security/Eval
        sanitized_content = pack_content.gsub(/import.*from.*['"];/, "")
                                        .gsub(/ReactOnRails\.register.*/, "")
        expect { eval(sanitized_content) }.not_to raise_error
        # rubocop:enable Security/Eval
      end

      it "does not generate a pack for a CSS module file" do
        expect(Dir.glob(css_module_pack_glob_pattern)).to be_empty
      end

      it "only generates the js pack" do
        generated_files = Dir.entries(generated_directory).reject { |f| f.start_with?(".") }
        expect(generated_files).to eq([File.basename(component_pack)])
      end
    end

    context "when stores_subdirectory is configured" do
      before do
        @old_stores_subdirectory = ReactOnRails.configuration.stores_subdirectory
        ReactOnRails.configuration.stores_subdirectory = "ror_stores"
      end

      after do
        ReactOnRails.configuration.stores_subdirectory = @old_stores_subdirectory
      end

      context "with store files in stores_subdirectory" do
        before do
          stores_fixture_path = File.expand_path("./fixtures/automated_packs_generation/stores", __dir__)
          allow(ReactOnRails::PackerUtils).to receive(:packer_source_path)
            .and_return("#{stores_fixture_path}/StoreWithAutoRegistration")
          described_class.instance.generate_packs_if_stale
        end

        it "creates pack for the store" do
          store_pack = "#{generated_directory}/commentsStore.js"
          expect(File.exist?(store_pack)).to be(true)
        end

        it "generated store pack registers the store" do
          store_pack = "#{generated_directory}/commentsStore.js"
          pack_content = File.read(store_pack)

          expect(pack_content).to include("import ReactOnRails from 'react-on-rails/client';")
          expect(pack_content).to include("import commentsStore from")
          expect(pack_content).to include("ReactOnRails.registerStore({commentsStore});")
        end

        it "includes store in the server bundle" do
          generated_server_bundle_content = File.read(generated_server_bundle_file_path)

          expect(generated_server_bundle_content).to include("ReactOnRails.registerStore")
          expect(generated_server_bundle_content).to include("commentsStore")
        end

        it "generates packs for TypeScript store files too" do
          ts_store_pack = "#{generated_directory}/routerStore.js"
          expect(File.exist?(ts_store_pack)).to be(true)
        end
      end

      context "when component and store have the same name" do
        before do
          stores_fixture_path = File.expand_path("./fixtures/automated_packs_generation/stores", __dir__)
          allow(ReactOnRails::PackerUtils).to receive(:packer_source_path)
            .and_return("#{stores_fixture_path}/StoreWithNameConflict")
        end

        it "raises an error for name conflict" do
          expect { described_class.instance.generate_packs_if_stale }
            .to raise_error(ReactOnRails::Error, /names are used for both components and stores/)
        end
      end
    end

    context "when stores_subdirectory is not set" do
      before do
        @old_stores_subdirectory = ReactOnRails.configuration.stores_subdirectory
        ReactOnRails.configuration.stores_subdirectory = nil
      end

      after do
        ReactOnRails.configuration.stores_subdirectory = @old_stores_subdirectory
      end

      it "does not attempt to generate store packs" do
        component_name = "ComponentWithCommonOnly"
        stub_packer_source_path(component_name: component_name, packer_source_path: packer_source_path)

        # Should not raise any errors even without stores
        expect { described_class.instance.generate_packs_if_stale }.not_to raise_error
      end
    end

    def generated_server_bundle_file_path
      described_class.instance.send(:generated_server_bundle_file_path)
    end

    def stub_packer_source_path(packer_source_path:, component_name:)
      allow(ReactOnRails::PackerUtils).to receive(:packer_source_path)
        .and_return("#{packer_source_path}/components/#{component_name}")
    end

    describe "#first_js_statement_in_code" do
      subject { described_class.instance.send(:first_js_statement_in_code, content) }

      context "with simple content" do
        let(:content) { "const x = 1;" }

        it { is_expected.to eq "const x = 1;" }
      end

      context "with single-line comments" do
        let(:content) do
          <<~JS
            // First comment
            // Second comment
            const x = 1;
            const y = 2;
          JS
        end

        it { is_expected.to eq "const x = 1;" }
      end

      context "with multi-line comments" do
        let(:content) do
          <<~JS
            /* This is a
               multiline comment */
            const x = 1;
          JS
        end

        it { is_expected.to eq "const x = 1;" }
      end

      context "with mixed comments" do
        let(:content) do
          <<~JS
            // Single line comment
            /* Multi-line
               comment */
            // Another single line
            const x = 1;
          JS
        end

        it { is_expected.to eq "const x = 1;" }
      end

      context "with mixed comments and whitespace" do
        let(:content) do
          <<~JS

            // First comment
            #{'  '}
            /*
              multiline comment
            */

                // comment with preceding whitespace

            // Another single line


            const x = 1;
          JS
        end

        it { is_expected.to eq "const x = 1;" }
      end

      context "with only comments" do
        let(:content) do
          <<~JS
            // Just a comment
            /* Another comment */
          JS
        end

        it { is_expected.to eq "" }
      end

      context "with comment at end of file" do
        let(:content) { "const x = 1;\n// Final comment" }

        it { is_expected.to eq "const x = 1;" }
      end

      context "with empty content" do
        let(:content) { "" }

        it { is_expected.to eq "" }
      end

      context "with only whitespace" do
        let(:content) { "   \n  \t  " }

        it { is_expected.to eq "" }
      end

      context "with statement containing comment-like strings" do
        let(:content) { 'const url = "http://example.com"; // Real comment' }

        # it returns the statement starting from non-space character until the next line even if it contains a comment
        it { is_expected.to eq 'const url = "http://example.com"; // Real comment' }
      end

      context "with unclosed multi-line comment" do
        let(:content) do
          <<~JS
            /* This comment
               never ends
            const x = 1;
          JS
        end

        it { is_expected.to eq "" }
      end

      context "with nested comments" do
        let(:content) do
          <<~JS
            // /* This is still a single line comment */
            const x = 1;
          JS
        end

        it { is_expected.to eq "const x = 1;" }
      end

      context "with one line comment with no space after //" do
        let(:content) { "//const x = 1;" }

        it { is_expected.to eq "" }
      end

      context "with one line comment with no new line after it" do
        let(:content) { "// const x = 1" }

        it { is_expected.to eq "" }
      end

      context "with string directive" do
        context "when on top of the file" do
          let(:content) do
            <<~JS
              "use client";
              // const x = 1
              const b = 2;
            JS
          end

          it { is_expected.to eq '"use client";' }
        end

        context "when on top of the file and one line comment" do
          let(:content) { '"use client"; // const x = 1' }

          it { is_expected.to eq '"use client"; // const x = 1' }
        end

        context "when after some one-line comments" do
          let(:content) do
            <<~JS
              // First comment
              // Second comment
              "use client";
            JS
          end

          it { is_expected.to eq '"use client";' }
        end

        context "when after some multi-line comments" do
          let(:content) do
            <<~JS
              /* First comment */
              /*
                multiline comment
              */
              "use client";
            JS
          end

          it { is_expected.to eq '"use client";' }
        end

        context "when after some mixed comments" do
          let(:content) do
            <<~JS
              // First comment
              /*
                multiline comment
              */
              "use client";
            JS
          end

          it { is_expected.to eq '"use client";' }
        end

        context "when after any non-comment code" do
          let(:content) do
            <<~JS
              // First comment
              const x = 1;
              "use client";
            JS
          end

          it { is_expected.to eq "const x = 1;" }
        end
      end
    end

    describe "#component_name" do
      subject(:component_name) { described_class.instance.send(:component_name, file_path) }

      context "with regular component file" do
        let(:file_path) { "/path/to/MyComponent.jsx" }

        it { is_expected.to eq "MyComponent" }
      end

      context "with client component file" do
        let(:file_path) { "/path/to/MyComponent.client.jsx" }

        it { is_expected.to eq "MyComponent" }
      end

      context "with server component file" do
        let(:file_path) { "/path/to/MyComponent.server.jsx" }

        it { is_expected.to eq "MyComponent" }
      end

      context "with CSS module file" do
        let(:file_path) { "/path/to/HeavyMarkdownEditor.module.css" }

        # CSS modules should still work with component_name method, but they
        # should not be processed as React components by the generator
        it "returns name with dot for CSS modules" do
          expect(component_name).to eq "HeavyMarkdownEditor.module"
        end
      end

      context "with TypeScript component file" do
        let(:file_path) { "/path/to/MyComponent.tsx" }

        it { is_expected.to eq "MyComponent" }
      end
    end

    describe "#relative_path" do
      subject { described_class.instance.send(:relative_path, from, to).to_s }

      context "when target is one directory up from generated pack" do
        let(:from) { "/app/javascript/packs/generated/MyComponent.js" }
        let(:to) { "/app/javascript/packs/components/MyComponent.jsx" }

        it { is_expected.to eq "../components/MyComponent.jsx" }
      end

      context "when target is multiple directories up from generated pack" do
        let(:from) { "/app/javascript/packs/generated/MyComponent.js" }
        let(:to) { "/app/javascript/src/deep/components/MyComponent.jsx" }

        it { is_expected.to eq "../../src/deep/components/MyComponent.jsx" }
      end

      context "when target is deeply nested relative to generated pack" do
        let(:from) { "/app/javascript/packs/generated/MyComponent.js" }
        let(:to) { "/app/src/nested/deeply/components/MyComponent.jsx" }

        it { is_expected.to eq "../../../src/nested/deeply/components/MyComponent.jsx" }
      end

      context "when from and to are in sibling directories" do
        let(:from) { "/app/packs/server-bundle.js" }
        let(:to) { "/app/generated/server-bundle-generated.js" }

        it { is_expected.to eq "../generated/server-bundle-generated.js" }
      end

      context "when from and to are in the same directory" do
        let(:from) { "/app/generated/server-bundle.js" }
        let(:to) { "/app/generated/server-bundle-generated.js" }

        it { is_expected.to eq "server-bundle-generated.js" }
      end
    end

    describe "#client_entrypoint?" do
      subject { described_class.instance.send(:client_entrypoint?, "dummy_path.js") }

      before do
        allow(File).to receive(:read).with("dummy_path.js").and_return(content)
      end

      context "when file has 'use client' directive" do
        context "with double quotes" do
          let(:content) { '"use client";' }

          it { is_expected.to be true }
        end

        context "with single quotes" do
          let(:content) { "'use client';" }

          it { is_expected.to be true }
        end

        context "without semicolon" do
          let(:content) { '"use client"' }

          it { is_expected.to be true }
        end

        context "with trailing whitespace" do
          let(:content) { '"use client"  ' }

          it { is_expected.to be true }
        end

        context "with comments before directive" do
          let(:content) do
            <<~JS
              // some comment
              /* multi-line
                 comment */
              "use client";
            JS
          end

          it { is_expected.to be true }
        end
      end

      context "when file does not have 'use client' directive" do
        context "with empty file" do
          let(:content) { "" }

          it { is_expected.to be false }
        end

        context "with regular JS code" do
          let(:content) { "const x = 1;" }

          it { is_expected.to be false }
        end

        context "with 'use client' in a comment" do
          let(:content) { "// 'use client'" }

          it { is_expected.to be false }
        end

        context "with 'use client' in middle of file" do
          let(:content) do
            <<~JS
              const x = 1;
              "use client";
            JS
          end

          it { is_expected.to be false }
        end

        context "with similar but incorrect directive" do
          let(:content) { "use client;" } # without quotes

          it { is_expected.to be false }
        end
      end
    end
  end
  # rubocop:enable Metrics/BlockLength
end
# rubocop:enable Metrics/ModuleLength

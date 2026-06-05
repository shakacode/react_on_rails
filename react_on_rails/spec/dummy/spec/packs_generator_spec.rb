# frozen_string_literal: true

require "rails_helper"
require "tmpdir"

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
      ReactOnRails.configuration.auto_load_bundle = old_auto_load_bundle

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

      it "keeps generated output at the configured file when a matching TypeScript source exists" do
        typescript_server_bundle_path = server_bundle_js_file_path.sub(/\.js\z/, ".ts")
        FileUtils.mv(server_bundle_js_file_path, "./temp")
        FileUtils.rm_rf server_bundle_js_file_path
        File.write(typescript_server_bundle_path, "export default {};\n")
        ReactOnRails.configuration.make_generated_server_bundle_the_entrypoint = true

        described_class.instance.generate_packs_if_stale

        expect(File.exist?(server_bundle_js_file_path)).to equal(true)
        expect(File.read(typescript_server_bundle_path)).to eq("export default {};\n")
      ensure
        ReactOnRails.configuration.make_generated_server_bundle_the_entrypoint = false
        FileUtils.rm_f(typescript_server_bundle_path)
        FileUtils.mv("./temp", server_bundle_js_file_path) if File.exist?("./temp")
      end
    end

    context "when computing the nonentrypoints directory path" do
      it "is a pure accessor that does not create the directory as a side effect" do
        generator = described_class.instance
        nonentrypoints_dir = generator.send(:generated_nonentrypoints_directory_path)
        FileUtils.rm_rf(nonentrypoints_dir)

        # The path accessor must not touch the filesystem; the mkdir lives in
        # ensure_nonentrypoints_directory!, called only before writes. This locks the behavior so
        # read-only callers (staleness checks, cleanup enumeration) never create the directory.
        expect(generator.send(:generated_nonentrypoints_directory_path)).to eq(nonentrypoints_dir)
        expect(Dir.exist?(nonentrypoints_dir)).to be(false)

        # ensure_nonentrypoints_directory! is the only thing that creates it.
        generator.send(:ensure_nonentrypoints_directory!)
        expect(Dir.exist?(nonentrypoints_dir)).to be(true)

        FileUtils.rm_rf(nonentrypoints_dir)
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
          information, please see https://reactonrails.com/docs/core-concepts/auto-bundling/
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
          information, please see https://reactonrails.com/docs/core-concepts/auto-bundling/
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
          information, please see https://reactonrails.com/docs/core-concepts/auto-bundling/
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
          expect(pack_content).not_to include("registerDefaultRSCProvider")
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
          expect(pack_content).to include("import 'react-on-rails-pro/registerDefaultRSCProvider/client';")
          expect(pack_content).to include("import ReactOnRails from 'react-on-rails-pro/client';")
          expect(pack_content).to include("ReactOnRails.register({#{component_name}});")
          expect(pack_content).not_to include("registerServerComponent")
          expect(pack_content.index("registerDefaultRSCProvider/client"))
            .to be < pack_content.index("react-on-rails-pro/client")
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
          expect(pack_content).not_to include("registerDefaultRSCProvider")
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
          expect(pack_content).to include("import 'react-on-rails-pro/registerDefaultRSCProvider/client';")
          expect(pack_content).to include("import ReactOnRails from 'react-on-rails-pro/client';")
          expect(pack_content).to include("ReactOnRails.register({#{component_name}});")
          expect(pack_content).not_to include("registerServerComponent")
          expect(pack_content.index("registerDefaultRSCProvider/client"))
            .to be < pack_content.index("react-on-rails-pro/client")
        end
      end

      it "regenerates client packs when generated contents no longer match the current template" do
        described_class.instance.generate_packs_if_stale
        component_name = "ReactClientComponent"
        component_pack = "#{generated_directory}/#{component_name}.js"
        component_source =
          "#{packer_source_path}/components/#{components_directory}/ror_components/#{component_name}.jsx"
        stale_pack_content = File.read(component_pack)
                                 .delete_prefix("import 'react-on-rails-pro/registerDefaultRSCProvider/client';\n")
        fresh_mtime = File.mtime(component_source) + 60
        File.write(component_pack, stale_pack_content)
        File.utime(fresh_mtime, fresh_mtime, component_pack)

        ENV["REACT_ON_RAILS_VERBOSE"] = "true"
        expect do
          described_class.instance.generate_packs_if_stale
        end.to output(GENERATED_PACKS_CONSOLE_OUTPUT_REGEX).to_stdout
        expect(File.read(component_pack))
          .to include("import 'react-on-rails-pro/registerDefaultRSCProvider/client';")
      ensure
        ENV.delete("REACT_ON_RAILS_VERBOSE")
      end

      it "regenerates server artifacts when a server-only component source is newer" do
        described_class.instance.generate_packs_if_stale
        generator = described_class.instance
        server_component_source =
          "#{packer_source_path}/components/#{components_directory}/ror_components/" \
          "ReactServerComponentWithClientAndServer.server.jsx"
        registration_entry = generator.send(:server_component_registration_entry_file_path)
        original_source_mtime = File.mtime(server_component_source)

        stale_generated_time = Time.now - 60
        fresh_source_time = Time.now - 30
        FileUtils.touch(generated_server_bundle_file_path, mtime: stale_generated_time)
        FileUtils.touch(registration_entry, mtime: stale_generated_time)
        FileUtils.touch(server_component_source, mtime: fresh_source_time)

        ENV["REACT_ON_RAILS_VERBOSE"] = "true"
        expect do
          described_class.instance.generate_packs_if_stale
        end.to output(GENERATED_PACKS_CONSOLE_OUTPUT_REGEX).to_stdout

        expect(File.mtime(generated_server_bundle_file_path)).to be > fresh_source_time
        expect(File.mtime(registration_entry)).to be > fresh_source_time
      ensure
        FileUtils.touch(server_component_source, mtime: original_source_mtime) if original_source_mtime
        ENV.delete("REACT_ON_RAILS_VERBOSE")
      end

      it "regenerates the registration entry when its content is stale but its mtime is current" do
        described_class.instance.generate_packs_if_stale
        generator = described_class.instance
        registration_entry = generator.send(:server_component_registration_entry_file_path)
        expect(File.exist?(registration_entry)).to be(true)

        # A fresh mtime keeps generated_file_older_than_sources? false, so this exercises the
        # content-equality branch of server_component_registration_entry_stale? specifically
        # (the mtime branch is covered by the preceding example). This is the branch that catches an
        # added/removed/renamed server component when no source mtime happens to be newer.
        File.write(registration_entry, "// stale registration entry\n")
        fresh_mtime = Time.now + 60
        File.utime(fresh_mtime, fresh_mtime, registration_entry)

        described_class.instance.generate_packs_if_stale

        expect(File.read(registration_entry)).not_to include("stale registration entry")
        expect(File.read(registration_entry)).to include("registerServerComponent")
      end

      it "checks generated pack contents without emitting likely-client warnings" do
        described_class.instance.generate_packs_if_stale
        component_name = "ReactServerComponent"
        component_pack = "#{generated_directory}/#{component_name}.js"
        component_source =
          "#{packer_source_path}/components/#{components_directory}/ror_components/#{component_name}.jsx"
        original_source = File.read(component_source)
        stale_pack_content = File.read(component_pack).sub("registerServerComponent", "staleRegisterServerComponent")

        File.write(component_source, <<~JS)
          export default function #{component_name}() {
            useState(false);
            return null;
          }
        JS

        fresh_mtime = File.mtime(component_source) + 60
        File.write(component_pack, stale_pack_content)
        File.utime(fresh_mtime, fresh_mtime, component_pack)

        expect do
          expect(described_class.instance.send(:stale_or_missing_packs?)).to be(true)
        end.not_to output(/WARNING.*#{component_name}/).to_stdout
      ensure
        File.write(component_source, original_source) if original_source
      end

      it "does not write a registration entry when there are no server components to register" do
        generator = described_class.instance
        allow(generator).to receive(:server_component_registration_entries).and_return({})
        entry_path = generator.send(:server_component_registration_entry_file_path)
        FileUtils.rm_f(entry_path)

        generator.send(:create_server_component_registration_entry)

        expect(File.exist?(entry_path)).to be(false)
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
          expect(pack_content).not_to include("registerDefaultRSCProvider")
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
          expect(pack_content).not_to include("registerDefaultRSCProvider")
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

        it "classifies server and client components without rescanning component paths" do
          generator = described_class.new
          components = {
            "ReactClientComponent" =>
              "#{packer_source_path}/components/ReactServerComponents/ror_components/ReactClientComponent.jsx",
            "ReactServerComponent" =>
              "#{packer_source_path}/components/ReactServerComponents/ror_components/ReactServerComponent.jsx"
          }

          # Guard the no-rescan optimization: generated_server_pack_file_content must fetch the
          # component map exactly once (components_for_server_registration runs an un-memoized
          # Dir.glob). `expect ... .once` verifies the count; `allow ... .once` would not.
          expect(generator).to receive(:components_for_server_registration).once.and_return(components)
          generated_server_bundle_path = File.join(
            Pathname(packer_source_entry_path).parent,
            "generated/server-bundle-generated.js"
          )
          allow(generator).to receive_messages(
            store_to_path: {},
            generated_server_bundle_file_path: generated_server_bundle_path
          )
          allow(generator).to receive(:client_entrypoint?) do |path|
            path.end_with?("ReactClientComponent.jsx")
          end

          generated_server_bundle_content = generator.send(:generated_server_pack_file_content)

          expect(generated_server_bundle_content).to include("registerServerComponent({ReactServerComponent});")
          expect(generated_server_bundle_content).to include("ReactOnRails.register({ReactClientComponent});")
        end

        it "reuses precomputed components when checking generated server bundle freshness" do
          generator = described_class.new
          components = {
            "ReactServerComponent" =>
              "#{packer_source_path}/components/ReactServerComponents/ror_components/ReactServerComponent.jsx"
          }
          generated_server_bundle_path = File.join(
            Pathname(packer_source_entry_path).parent,
            "generated/server-bundle-generated.js"
          )

          allow(generator).to receive(:components_for_server_registration).and_return(components)
          allow(generator).to receive_messages(
            generated_server_bundle_file_path: generated_server_bundle_path,
            store_to_path: {}
          )
          allow(generator).to receive(:generated_file_older_than_sources?)
            .with(generated_server_bundle_path, components.values)
            .and_return(false)
          allow(generator).to receive(:generated_server_pack_file_content).with(components).and_return("fresh")
          allow(File).to receive(:exist?).and_call_original
          allow(File).to receive(:exist?).with(generated_server_bundle_path).and_return(true)
          allow(File).to receive(:read).with(generated_server_bundle_path).and_return("fresh")

          expect(generator.send(:generated_server_bundle_stale?)).to be(false)
          expect(generator).to have_received(:components_for_server_registration).once
          expect(generator).to have_received(:generated_server_pack_file_content).with(components)
        end

        it "reuses precomputed entries when writing and checking the RSC registration entry" do
          generator = described_class.new
          entries = {
            "ReactServerComponent" =>
              "#{packer_source_path}/components/ReactServerComponents/ror_components/ReactServerComponent.jsx"
          }
          registration_entry_path = File.join(
            Pathname(packer_source_entry_path).parent,
            "generated/server-component-registration-entry.js"
          )

          allow(generator).to receive_messages(
            server_component_registration_entries: entries,
            server_component_registration_entry_file_path: registration_entry_path
          )
          allow(generator).to receive(:server_component_registration_entry_content)
            .with(entries)
            .and_return("fresh")
          allow(generator).to receive(:ensure_nonentrypoints_directory!)
          expect(File).to receive(:write).with(registration_entry_path, "fresh")

          generator.send(:create_server_component_registration_entry)

          allow(generator).to receive(:generated_file_older_than_sources?)
            .with(registration_entry_path, entries.values)
            .and_return(false)
          allow(File).to receive(:exist?).and_call_original
          allow(File).to receive(:exist?).with(registration_entry_path).and_return(true)
          allow(File).to receive(:read).with(registration_entry_path).and_return("fresh")

          expect(generator.send(:server_component_registration_entry_stale?)).to be(false)
          expect(generator).to have_received(:server_component_registration_entries).twice
          expect(generator).to have_received(:server_component_registration_entry_content).with(entries).twice
        end

        it "reuses server registration components across the staleness fast path" do
          generator = described_class.new
          components = {
            "ReactServerComponent" =>
              "#{packer_source_path}/components/ReactServerComponents/ror_components/ReactServerComponent.jsx"
          }
          generated_server_bundle_path = File.join(
            Pathname(packer_source_entry_path).parent,
            "generated/server-bundle-generated.js"
          )
          registration_entry_path = File.join(
            Pathname(packer_source_entry_path).parent,
            "generated/server-component-registration-entry.js"
          )

          allow(generator).to receive_messages(
            common_component_to_path: {},
            client_component_to_path: {},
            store_to_path: {},
            generated_server_bundle_file_path: generated_server_bundle_path,
            server_component_registration_entry_file_path: registration_entry_path,
            client_entrypoint?: false
          )
          allow(generator).to receive(:components_for_server_registration).and_return(components)
          allow(generator).to receive(:generated_file_older_than_sources?)
            .with(generated_server_bundle_path, components.values)
            .and_return(false)
          allow(generator).to receive(:generated_file_older_than_sources?)
            .with(registration_entry_path, components.values)
            .and_return(false)
          allow(generator).to receive(:generated_server_pack_file_content).with(components).and_return("fresh")
          allow(generator)
            .to receive(:server_component_registration_entry_content)
            .with(components)
            .and_return("fresh")
          allow(File).to receive(:exist?).and_call_original
          allow(File).to receive(:exist?).with(generated_server_bundle_path).and_return(true)
          allow(File).to receive(:exist?).with(registration_entry_path).and_return(true)
          allow(File).to receive(:read).with(generated_server_bundle_path).and_return("fresh")
          allow(File).to receive(:read).with(registration_entry_path).and_return("fresh")

          expect(generator.send(:stale_or_missing_packs?)).to be(false)
          expect(generator).to have_received(:components_for_server_registration).once
        end

        it "creates a server component registration entry for RSC reference discovery" do
          generated_entry_path = File.join(
            Pathname(packer_source_entry_path).parent,
            "generated/server-component-registration-entry.js"
          )
          generated_entry_content = File.read(generated_entry_path)
          expected_content = <<~CONTENT.strip
            import ReactServerComponent from '../components/ReactServerComponents/ror_components/ReactServerComponent.jsx';
            import ReactServerComponentWithClientAndServer from '../components/ReactServerComponents/ror_components/ReactServerComponentWithClientAndServer.server.jsx';

            import registerServerComponent from 'react-on-rails-pro/registerServerComponent/server';
            registerServerComponent({ ReactServerComponent, ReactServerComponentWithClientAndServer });
          CONTENT

          expect(generated_entry_content.strip).to eq(expected_content.strip)
          expect(generated_entry_content).not_to include("ReactOnRails.register")
          expect(generated_entry_content).not_to include("ReactClientComponent")
        end

        it "preserves the registration entry while removing stray files during cleanup" do
          generated_dir = File.join(Pathname(packer_source_entry_path).parent, "generated")
          entry_path = File.join(generated_dir, "server-component-registration-entry.js")
          stray_path = File.join(generated_dir, "stray-orphan.js")
          File.write(stray_path, "// stray\n")
          expect(File.exist?(entry_path)).to be(true)

          described_class.instance.generate_packs_if_stale

          expect(File.exist?(stray_path)).to be(false)
          expect(File.exist?(entry_path)).to be(true)
        end

        it "regenerates the registration entry when only it is missing" do
          entry_path = File.join(
            Pathname(packer_source_entry_path).parent,
            "generated/server-component-registration-entry.js"
          )
          expect(File.exist?(entry_path)).to be(true)
          File.delete(entry_path)

          described_class.instance.generate_packs_if_stale

          expect(File.exist?(entry_path)).to be(true)
        end

        it "scans the nonentrypoints directory for cleanup even when the server bundle is the entrypoint" do
          generator = described_class.instance
          ReactOnRails.configuration.make_generated_server_bundle_the_entrypoint = true
          nonentrypoints_dir = generator.send(:generated_nonentrypoints_directory_path)

          # generated_server_bundle_directory_path is nil in entrypoint mode, so without the explicit
          # add the registration entry's directory would never be enumerated for cleanup.
          expect(generator.send(:directories_to_clean)).to include(nonentrypoints_dir)
        ensure
          ReactOnRails.configuration.make_generated_server_bundle_the_entrypoint = false
        end

        it "treats the registration entry as expected and stray files as unexpected" do
          generator = described_class.instance
          nonentrypoints_dir = generator.send(:generated_nonentrypoints_directory_path)
          entry = generator.send(:server_component_registration_entry_file_path)
          stray = File.join(nonentrypoints_dir, "stray-orphan.js")
          expected_files = generator.send(:build_expected_files_set)

          unexpected = generator.send(:find_unexpected_files, [entry, stray], nonentrypoints_dir, expected_files)

          expect(unexpected).to include(stray)
          expect(unexpected).not_to include(entry)
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

      it "does not require a generated server bundle when server bundle output is not configured" do
        generator = described_class.new
        server_bundle_path = generated_server_bundle_file_path
        old_server_bundle = ReactOnRails.configuration.server_bundle_js_file
        ReactOnRails.configuration.server_bundle_js_file = nil
        FileUtils.mkdir_p(generated_directory)
        FileUtils.rm_f(server_bundle_path)
        allow(generator).to receive(:stale_or_missing_packs?).and_return(false)

        expect(generator.send(:generated_files_present_and_up_to_date?)).to be(true)
      ensure
        ReactOnRails.configuration.server_bundle_js_file = old_server_bundle
        FileUtils.touch(server_bundle_path) if server_bundle_path
      end

      it "adds a single import statement to the server bundle" do
        test_string = "// import statement added by react_on_rails:generate_packs"
        generated_import = "import '../generated/server-bundle-generated';"
        same_instance = described_class.instance
        File.truncate(server_bundle_js_file_path, 0)
        same_instance.generate_packs_if_stale
        server_bundle_content = File.read(server_bundle_js_file_path)
        expect(server_bundle_content.scan(/(?=#{test_string})/).count).to equal(1)
        expect(server_bundle_content).to include(generated_import)
        expect(server_bundle_content).not_to include("import '../generated/server-bundle-generated.js';")
        # the following expectation checks that an additional import statement is not added if one already exists
        same_instance.generate_packs_if_stale
        expect(File.read(server_bundle_js_file_path).scan(/(?=#{test_string})/).count).to equal(1)
      end

      it "adds a lint-safe import statement to a TypeScript server bundle source entrypoint" do
        same_instance = described_class.instance
        backup_server_bundle_js_file_path = "#{server_bundle_js_file_path}.bak"
        server_bundle_ts_file_path = server_bundle_js_file_path.sub(/\.js\z/, ".ts")

        FileUtils.mv(server_bundle_js_file_path, backup_server_bundle_js_file_path)
        File.write(server_bundle_ts_file_path, "")
        same_instance.generate_packs_if_stale

        generated_import = "import '../generated/server-bundle-generated.js'; " \
                           "// eslint-disable-line import/extensions"
        expect(File.read(server_bundle_ts_file_path)).to include(generated_import)

        same_instance.generate_packs_if_stale
        generated_import_count = File.read(server_bundle_ts_file_path)
                                     .scan(%r{import '../generated/server-bundle-generated\.js'}).count
        expect(generated_import_count).to equal(1)
      ensure
        FileUtils.rm_f(server_bundle_ts_file_path)
        if backup_server_bundle_js_file_path && File.exist?(backup_server_bundle_js_file_path)
          FileUtils.mv(backup_server_bundle_js_file_path, server_bundle_js_file_path)
        end
      end

      it "adds a lint-safe import statement to a JSX server bundle source entrypoint" do
        same_instance = described_class.instance
        backup_server_bundle_js_file_path = "#{server_bundle_js_file_path}.bak"
        server_bundle_jsx_file_path = server_bundle_js_file_path.sub(/\.js\z/, ".jsx")

        FileUtils.mv(server_bundle_js_file_path, backup_server_bundle_js_file_path)
        File.write(server_bundle_jsx_file_path, "")
        same_instance.generate_packs_if_stale

        generated_import = "import '../generated/server-bundle-generated.js'; " \
                           "// eslint-disable-line import/extensions"
        expect(File.read(server_bundle_jsx_file_path)).to include(generated_import)
      ensure
        FileUtils.rm_f(server_bundle_jsx_file_path)
        if backup_server_bundle_js_file_path && File.exist?(backup_server_bundle_js_file_path)
          FileUtils.mv(backup_server_bundle_js_file_path, server_bundle_js_file_path)
        end
      end

      %w[.mjs .cjs].each do |extension|
        it "adds a lint-safe import statement to a #{extension} server bundle source entrypoint" do
          same_instance = described_class.instance
          backup_server_bundle_js_file_path = "#{server_bundle_js_file_path}.bak"
          server_bundle_source_file_path = server_bundle_js_file_path.sub(/\.js\z/, extension)

          FileUtils.mv(server_bundle_js_file_path, backup_server_bundle_js_file_path)
          File.write(server_bundle_source_file_path, "")
          same_instance.generate_packs_if_stale

          generated_import = "import '../generated/server-bundle-generated.js'; " \
                             "// eslint-disable-line import/extensions"
          expect(File.read(server_bundle_source_file_path)).to include(generated_import)

          same_instance.generate_packs_if_stale
          generated_import_count = File.read(server_bundle_source_file_path)
                                       .scan(%r{import '../generated/server-bundle-generated\.js'}).count
          expect(generated_import_count).to equal(1)
        ensure
          FileUtils.rm_f(server_bundle_source_file_path)
          if backup_server_bundle_js_file_path && File.exist?(backup_server_bundle_js_file_path)
            FileUtils.mv(backup_server_bundle_js_file_path, server_bundle_js_file_path)
          end
        end
      end

      it "serializes concurrent generation and rechecks staleness after waiting" do
        generator = nil
        first_thread = nil
        second_thread = nil
        old_auto = old_auto_load_bundle

        generator = described_class.new
        generation_started = Queue.new
        release_generation = Queue.new
        second_about_to_lock = Queue.new
        second_completed = Queue.new
        generation_count = 0

        allow(generator).to receive(:with_generated_packs_lock).and_wrap_original do |original, *args, **kwargs, &block|
          second_about_to_lock << true if Thread.current[:packs_generator_spec_thread] == :second
          original.call(*args, **kwargs, &block)
        end
        allow(generator).to receive(:add_generated_pack_to_server_bundle)
        allow(generator).to receive(:clean_non_generated_files_with_feedback)
        allow(generator).to receive(:clean_generated_directories_with_feedback)
        allow(generator).to receive(:generated_files_present_and_up_to_date?).and_return(false, true)
        allow(generator).to receive(:generate_packs) do
          generation_count += 1
          generation_started << true
          release_generation.pop
        end

        ReactOnRails.configuration.auto_load_bundle = true
        first_thread = Thread.new { generator.generate_packs_if_stale }
        expect(generation_started.pop(timeout: 5)).to be(true)

        second_thread = Thread.new do
          Thread.current[:packs_generator_spec_thread] = :second
          generator.generate_packs_if_stale
          second_completed << true
        end

        expect(second_about_to_lock.pop(timeout: 5)).to be(true)
        expect { second_completed.pop(true) }.to raise_error(ThreadError)

        release_generation << true
        expect(first_thread.join(5)).to eq(first_thread)
        expect(second_thread.join(5)).to eq(second_thread)

        expect(generation_count).to eq(1)
      ensure
        first_thread&.kill if first_thread&.alive?
        second_thread&.kill if second_thread&.alive?
        if generator
          lock_path = generator.send(:generated_packs_lock_path)
          FileUtils.rm_f(lock_path) if lock_path
        end
        ReactOnRails.configuration.auto_load_bundle = old_auto
      end

      it "clears stale lock contents without unlinking the lock file" do
        generator = described_class.new
        lock_path = generator.send(:generated_packs_lock_path)
        FileUtils.mkdir_p(lock_path.dirname)
        File.write(lock_path, "pid=stale\n")
        FileUtils.touch(lock_path, mtime: Time.now - described_class::GENERATED_PACKS_LOCK_TTL_SECONDS - 1)

        original_inode = File.stat(lock_path).ino

        generator.send(:clear_stale_generated_packs_lock, lock_path)

        expect(File.exist?(lock_path)).to be(true)
        expect(File.stat(lock_path).ino).to eq(original_inode)
        expect(File.read(lock_path)).to eq("")
      ensure
        FileUtils.rm_f(lock_path) if lock_path
      end

      it "ignores inaccessible stale lock files" do
        generator = described_class.new
        lock_path = generator.send(:generated_packs_lock_path)
        FileUtils.mkdir_p(lock_path.dirname)
        File.write(lock_path, "pid=stale\n")
        FileUtils.touch(lock_path, mtime: Time.now - described_class::GENERATED_PACKS_LOCK_TTL_SECONDS - 1)
        allow(File).to receive(:open).with(lock_path, File::RDWR).and_raise(Errno::EACCES)

        expect { generator.send(:clear_stale_generated_packs_lock, lock_path) }.not_to raise_error
      ensure
        FileUtils.rm_f(lock_path) if lock_path
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
      subject(:computed_relative_path) { described_class.instance.send(:relative_path, from, to).to_s }

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

    describe "#relative_import_path" do
      subject(:computed_relative_import_path) { described_class.instance.send(:relative_import_path, from, to) }

      context "when target is outside the entrypoint directory" do
        let(:from) { "/app/packs/server-bundle.ts" }
        let(:to) { "/app/generated/server-bundle-generated.js" }

        it { is_expected.to eq "../generated/server-bundle-generated.js" }
      end

      context "when target is in the same directory" do
        let(:from) { "/app/generated/server-bundle.ts" }
        let(:to) { "/app/generated/server-bundle-generated.js" }

        it { is_expected.to eq "./server-bundle-generated.js" }
      end
    end

    describe "CLIENT_API_PATTERN" do
      subject { content.match?(described_class::CLIENT_API_PATTERN) }

      context "with React hooks" do
        %w[useState useEffect useReducer useCallback useMemo useRef useLayoutEffect
           useImperativeHandle useContext useSyncExternalStore useTransition useDeferredValue].each do |hook|
          context "with #{hook}" do
            let(:content) { "const value = #{hook}();" }

            it { is_expected.to be true }
          end
        end
      end

      context "with event handlers" do
        %w[onClick onChange onSubmit onFocus onBlur onKeyDown onKeyUp onKeyPress
           onMouseDown onMouseUp onMouseEnter onMouseLeave].each do |handler|
          context "with #{handler} as JSX prop" do
            let(:content) { "<button #{handler}={handleClick} />" }

            it { is_expected.to be true }
          end
        end
      end

      context "with class components" do
        context "with extends Component" do
          let(:content) { "class MyComp extends Component {" }

          it { is_expected.to be true }
        end

        context "with extends PureComponent" do
          let(:content) { "class MyComp extends PureComponent {" }

          it { is_expected.to be true }
        end

        context "with extends React.Component" do
          let(:content) { "class MyComp extends React.Component {" }

          it { is_expected.to be true }
        end

        context "with extends React.PureComponent" do
          let(:content) { "class MyComp extends React.PureComponent {" }

          it { is_expected.to be true }
        end
      end

      context "with non-matching content" do
        context "with server-only code" do
          let(:content) { "export default function ServerComponent() { return <div />; }" }

          it { is_expected.to be false }
        end

        context "with custom hook name not in the list" do
          let(:content) { "const value = useCustomHook();" }

          it { is_expected.to be false }
        end

        context "with empty content" do
          let(:content) { "" }

          it { is_expected.to be false }
        end
      end
    end

    describe "#warn_if_likely_client_component" do
      let(:file_path) { "dummy_component.jsx" }
      let(:component_name) { "DummyComponent" }

      before do
        allow(File).to receive(:read).with(file_path).and_return(content)
      end

      context "when file contains client APIs" do
        let(:content) { "const [state, setState] = useState(false);" }

        it "prints a warning to stdout" do
          expect { described_class.instance.send(:warn_if_likely_client_component, file_path, component_name) }
            .to output(/WARNING.*DummyComponent.*useState.*missing the 'use client' directive/).to_stdout
        end
      end

      context "when file contains multiple client APIs" do
        let(:content) { "useState(); useEffect(); useCallback(); useMemo(); useRef();" }

        it "shows at most 3 matches with ellipsis" do
          expect { described_class.instance.send(:warn_if_likely_client_component, file_path, component_name) }
            .to output(/\(useState, useEffect, useCallback, \.\.\.\)/).to_stdout
        end
      end

      context "when file has no client APIs" do
        let(:content) { "export default function ServerComponent() { return <div />; }" }

        it "does not print anything" do
          expect { described_class.instance.send(:warn_if_likely_client_component, file_path, component_name) }
            .not_to output.to_stdout
        end
      end
    end

    describe "#log_rsc_classification_summary" do
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
        allow(ReactOnRailsPro::Utils).to receive_messages(rsc_support_enabled?: true)
        # Force re-computation of component maps
        described_class.instance.generate_packs_if_stale
      end

      it "prints classification summary to stdout" do
        expect { described_class.instance.send(:log_rsc_classification_summary) }
          .to output(/RSC component classification/).to_stdout
      end

      it "lists server components" do
        expect { described_class.instance.send(:log_rsc_classification_summary) }
          .to output(/Server components.*ReactServerComponent/).to_stdout
      end

      it "lists client components" do
        expect { described_class.instance.send(:log_rsc_classification_summary) }
          .to output(/Client components.*ReactClientComponent/).to_stdout
      end
    end

    describe "#resolve_server_bundle_source_entrypoint" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          @tmpdir = tmpdir
          example.run
        end
      end

      it "uses the configured server bundle entrypoint when it exists" do
        configured_entrypoint = File.join(@tmpdir, "server-bundle.js")
        File.write(configured_entrypoint, "")

        resolved_entrypoint = described_class.instance.send(:resolve_server_bundle_source_entrypoint,
                                                            configured_entrypoint)

        expect(resolved_entrypoint).to eq(configured_entrypoint)
      end

      it "uses a TypeScript source entrypoint when the configured JavaScript output filename is missing" do
        configured_entrypoint = File.join(@tmpdir, "server-bundle.js")
        typescript_entrypoint = File.join(@tmpdir, "server-bundle.ts")
        File.write(typescript_entrypoint, "")

        expect(Rails.logger).to receive(:debug).with(
          "[react_on_rails] server bundle source entrypoint resolved to #{typescript_entrypoint} " \
          "(configured: #{configured_entrypoint})"
        )
        resolved_entrypoint = described_class.instance.send(:resolve_server_bundle_source_entrypoint,
                                                            configured_entrypoint)

        expect(resolved_entrypoint).to eq(typescript_entrypoint)
      end

      it "uses a JSX source entrypoint before TypeScript when both could match a missing JavaScript output" do
        configured_entrypoint = File.join(@tmpdir, "server-bundle.js")
        jsx_entrypoint = File.join(@tmpdir, "server-bundle.jsx")
        typescript_entrypoint = File.join(@tmpdir, "server-bundle.ts")
        File.write(jsx_entrypoint, "")
        File.write(typescript_entrypoint, "")

        resolved_entrypoint = described_class.instance.send(:resolve_server_bundle_source_entrypoint,
                                                            configured_entrypoint)

        expect(resolved_entrypoint).to eq(jsx_entrypoint)
      end

      it "uses a TSX source entrypoint when the configured TypeScript entrypoint is missing" do
        configured_entrypoint = File.join(@tmpdir, "server-bundle.ts")
        tsx_entrypoint = File.join(@tmpdir, "server-bundle.tsx")
        File.write(tsx_entrypoint, "")

        resolved_entrypoint = described_class.instance.send(:resolve_server_bundle_source_entrypoint,
                                                            configured_entrypoint)

        expect(resolved_entrypoint).to eq(tsx_entrypoint)
      end

      it "uses a TypeScript ESM source entrypoint when the configured JavaScript output filename is missing" do
        configured_entrypoint = File.join(@tmpdir, "server-bundle.js")
        mts_entrypoint = File.join(@tmpdir, "server-bundle.mts")
        File.write(mts_entrypoint, "")

        resolved_entrypoint = described_class.instance.send(:resolve_server_bundle_source_entrypoint,
                                                            configured_entrypoint)

        expect(resolved_entrypoint).to eq(mts_entrypoint)
      end

      it "uses a TypeScript CommonJS source entrypoint when the configured JavaScript output filename is missing" do
        configured_entrypoint = File.join(@tmpdir, "server-bundle.js")
        cts_entrypoint = File.join(@tmpdir, "server-bundle.cts")
        File.write(cts_entrypoint, "")

        resolved_entrypoint = described_class.instance.send(:resolve_server_bundle_source_entrypoint,
                                                            configured_entrypoint)

        expect(resolved_entrypoint).to eq(cts_entrypoint)
      end

      it "returns the configured entrypoint when no source file exists for any extension" do
        configured_entrypoint = File.join(@tmpdir, "server-bundle.js")

        resolved_entrypoint = described_class.instance.send(:resolve_server_bundle_source_entrypoint,
                                                            configured_entrypoint)

        expect(resolved_entrypoint).to eq(configured_entrypoint)
      end

      it "checks all server bundle source extensions when the configured entrypoint has no extension" do
        configured_entrypoint = File.join(@tmpdir, "server-bundle")

        source_extensions = described_class.instance.send(:server_bundle_source_extensions_for,
                                                          configured_entrypoint)

        expect(source_extensions).to eq(described_class::SERVER_BUNDLE_SOURCE_EXTENSIONS)
      end

      it "uses the first matching source extension when the configured entrypoint has no extension" do
        configured_entrypoint = File.join(@tmpdir, "server-bundle")
        javascript_entrypoint = File.join(@tmpdir, "server-bundle.js")
        typescript_entrypoint = File.join(@tmpdir, "server-bundle.ts")
        File.write(javascript_entrypoint, "")
        File.write(typescript_entrypoint, "")

        resolved_entrypoint = described_class.instance.send(:resolve_server_bundle_source_entrypoint,
                                                            configured_entrypoint)

        expect(resolved_entrypoint).to eq(javascript_entrypoint)
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

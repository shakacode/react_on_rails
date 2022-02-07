# frozen_string_literal: true

require_relative "spec_helper"

# rubocop:disable Metrics/ModuleLength, Metrics/BlockLength
module ReactOnRails
  RSpec.describe Utils do
    context "when server_bundle_path cleared" do
      before do
        allow(Rails).to receive(:root).and_return(File.expand_path("."))
        described_class.instance_variable_set(:@server_bundle_path, nil)
      end

      after do
        described_class.instance_variable_set(:@server_bundle_path, nil)
      end

      describe ".bundle_js_file_path" do
        subject do
          described_class.bundle_js_file_path("webpack-bundle.js")
        end

        context "with Webpacker enabled", :webpacker do
          let(:webpacker_public_output_path) do
            File.expand_path(File.join(Rails.root, "public/webpack/dev"))
          end

          before do
            allow(ReactOnRails).to receive_message_chain(:configuration, :generated_assets_dir)
              .and_return("")
            allow(Webpacker).to receive_message_chain("dev_server.running?")
              .and_return(false)
            allow(Webpacker).to receive_message_chain("config.public_output_path")
              .and_return(webpacker_public_output_path)
            allow(ReactOnRails::WebpackerUtils).to receive(:using_webpacker?).and_return(true)
          end

          context "when file in manifest", :webpacker do
            before do
              # Note Webpacker manifest lookup is inside of the public_output_path
              # [2] (pry) ReactOnRails::WebpackerUtils: 0> Webpacker.manifest.lookup("app-bundle.js")
              # "/webpack/development/app-bundle-c1d2b6ab73dffa7d9c0e.js"
              allow(Webpacker).to receive_message_chain("manifest.lookup!")
                .with("webpack-bundle.js")
                .and_return("/webpack/dev/webpack-bundle-0123456789abcdef.js")
              allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_js_file")
                .and_return("server-bundle.js")
            end

            it { is_expected.to eq("#{webpacker_public_output_path}/webpack-bundle-0123456789abcdef.js") }
          end

          context "with manifest.json" do
            subject do
              described_class.bundle_js_file_path("manifest.json")
            end

            it { is_expected.to eq("#{webpacker_public_output_path}/manifest.json") }
          end
        end

        context "without Webpacker enabled" do
          before do
            allow(ReactOnRails).to receive_message_chain(:configuration, :generated_assets_dir)
              .and_return("public/webpack/dev")
            allow(ReactOnRails::WebpackerUtils).to receive(:using_webpacker?).and_return(false)
          end

          it { is_expected.to eq(File.expand_path(File.join(Rails.root, "public/webpack/dev/webpack-bundle.js"))) }
        end
      end

      describe ".source_path_is_not_defined_and_custom_node_modules?" do
        it "returns false if node_modules is blank" do
          allow(ReactOnRails).to receive_message_chain("configuration.node_modules_location")
            .and_return("")
          allow(Webpacker).to receive_message_chain("config.send").with(:data)
                                                                  .and_return({})

          expect(described_class.using_webpacker_source_path_is_not_defined_and_custom_node_modules?).to eq(false)
        end

        it "returns false if source_path is defined in the config/webpacker.yml and node_modules defined" do
          allow(ReactOnRails).to receive_message_chain("configuration.node_modules_location")
            .and_return("client")
          allow(Webpacker).to receive_message_chain("config.send").with(:data)
                                                                  .and_return(source_path: "client/app")

          expect(described_class.using_webpacker_source_path_is_not_defined_and_custom_node_modules?).to eq(false)
        end

        it "returns true if node_modules is not blank and the source_path is not defined in config/webpacker.yml" do
          allow(ReactOnRails).to receive_message_chain("configuration.node_modules_location")
            .and_return("node_modules")
          allow(Webpacker).to receive_message_chain("config.send").with(:data)
                                                                  .and_return({})

          expect(described_class.using_webpacker_source_path_is_not_defined_and_custom_node_modules?).to eq(true)
        end
      end

      describe ".server_bundle_js_file_path" do
        before do
          allow(Rails).to receive(:root).and_return(Pathname.new("."))
          allow(ReactOnRails::WebpackerUtils).to receive(:using_webpacker?).and_return(true)
          allow(Webpacker).to receive_message_chain("config.public_output_path")
            .and_return(Pathname.new("public/webpack/development"))
        end

        context "with Webpacker enabled and server file not in manifest", :webpacker do
          it "returns the unhashed server path" do
            server_bundle_name = "server-bundle.js"
            allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_js_file")
              .and_return(server_bundle_name)
            allow(Webpacker).to receive_message_chain("manifest.lookup!")
              .with(server_bundle_name)
              .and_raise(Webpacker::Manifest::MissingEntryError)

            path = described_class.server_bundle_js_file_path

            expect(path).to end_with("public/webpack/development/#{server_bundle_name}")
          end
        end

        context "with Webpacker enabled and server file in the manifest, used for client", :webpacker do
          it "returns the correct path hashed server path" do
            allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_js_file")
              .and_return("webpack-bundle.js")
            allow(ReactOnRails).to receive_message_chain("configuration.same_bundle_for_client_and_server")
              .and_return(true)
            allow(Webpacker).to receive_message_chain("manifest.lookup!")
              .with("webpack-bundle.js")
              .and_return("webpack/development/webpack-bundle-123456.js")

            path = described_class.server_bundle_js_file_path
            expect(path).to end_with("public/webpack/development/webpack-bundle-123456.js")
            expect(path).to start_with("/")
          end
        end

        context "with Webpacker enabled and server file in the manifest, used for client, "\
                " and webpack-dev-server running, and same file used for server and client", :webpacker do
          it "returns the correct path hashed server path" do
            allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_js_file")
              .and_return("webpack-bundle.js")
            allow(ReactOnRails).to receive_message_chain("configuration.same_bundle_for_client_and_server")
              .and_return(true)
            allow(Webpacker).to receive_message_chain("dev_server.running?")
              .and_return(true)
            allow(Webpacker).to receive_message_chain("dev_server.protocol")
              .and_return("http")
            allow(Webpacker).to receive_message_chain("dev_server.host_with_port")
              .and_return("localhost:3035")
            allow(Webpacker).to receive_message_chain("manifest.lookup!")
              .with("webpack-bundle.js")
              .and_return("/webpack/development/webpack-bundle-123456.js")

            path = described_class.server_bundle_js_file_path

            expect(path).to eq("http://localhost:3035/webpack/development/webpack-bundle-123456.js")
          end
        end

        context "with Webpacker enabled, dev-server running, and server file in the manifest, and "\
                " separate client/server files", :webpacker do
          it "returns the correct path hashed server path" do
            allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_js_file")
              .and_return("server-bundle.js")
            allow(ReactOnRails).to receive_message_chain("configuration.same_bundle_for_client_and_server")
              .and_return(false)
            allow(Webpacker).to receive_message_chain("manifest.lookup!")
              .with("server-bundle.js")
              .and_return("webpack/development/server-bundle-123456.js")
            allow(Webpacker).to receive_message_chain("dev_server.running?")
              .and_return(true)

            path = described_class.server_bundle_js_file_path

            expect(path).to end_with("/public/webpack/development/server-bundle-123456.js")
          end
        end
      end

      describe ".wrap_message" do
        subject(:stripped_heredoc) do
          <<-MSG.strip_heredoc
          Something to wrap
          with 2 lines
          MSG
        end

        let(:expected) do
          msg = <<-MSG.strip_heredoc
          ================================================================================
          Something to wrap
          with 2 lines
          ================================================================================
          MSG
          Rainbow(msg).red
        end

        it "outputs the correct text" do
          expect(described_class.wrap_message(stripped_heredoc)).to eq(expected)
        end
      end

      describe ".truthy_presence" do
        context "with non-empty string" do
          subject(:simple_string) { "foobar" }

          it "returns subject (same value as presence) for a non-empty string" do
            expect(described_class.truthy_presence(simple_string)).to eq(simple_string.presence)

            # Blank strings are nil for presence
            expect(described_class.truthy_presence(simple_string)).to eq(simple_string)
          end
        end

        context "with empty string" do
          it "returns \"\" for an empty string" do
            expect(described_class.truthy_presence("")).to eq("")
          end
        end

        context "with nil object" do
          it "returns nil (same value as presence)" do
            expect(described_class.truthy_presence(nil)).to eq(nil.presence)

            # Blank strings are nil for presence
            expect(described_class.truthy_presence(nil)).to eq(nil)
          end
        end

        context "with pathname pointing to empty dir (obj.empty? is true)" do
          subject(:empty_dir) { Pathname.new(Dir.mktmpdir) }

          it "returns Pathname object" do
            # Blank strings are nil for presence
            expect(described_class.truthy_presence(empty_dir)).to eq(empty_dir)
          end
        end

        context "with pathname pointing to empty file" do
          subject(:empty_file) do
            File.basename(Tempfile.new("tempfile",
                                       empty_dir))
          end

          let(:empty_dir) { Pathname.new(Dir.mktmpdir) }

          it "returns Pathname object" do
            expect(described_class.truthy_presence(empty_file)).to eq(empty_file)
          end
        end
      end

      describe ".rails_version_less_than" do
        subject { described_class.rails_version_less_than("4") }

        describe ".rails_version_less_than" do
          before { described_class.instance_variable_set :@rails_version_less_than, nil }

          context "with Rails 3" do
            before { allow(Rails).to receive(:version).and_return("3") }

            it { is_expected.to eq(true) }
          end

          context "with Rails 3.2" do
            before { allow(Rails).to receive(:version).and_return("3.2") }

            it { is_expected.to eq(true) }
          end

          context "with Rails 4" do
            before { allow(Rails).to receive(:version).and_return("4") }

            it { is_expected.to eq(false) }
          end

          context "with Rails 4.2" do
            before { allow(Rails).to receive(:version).and_return("4.2") }

            it { is_expected.to eq(false) }
          end

          context "with Rails 10.0" do
            before { allow(Rails).to receive(:version).and_return("10.0") }

            it { is_expected.to eq(false) }
          end

          context "when called twice" do
            before do
              allow(Rails).to receive(:version).and_return("4.2")
            end

            it "memoizes the result" do
              2.times { described_class.rails_version_less_than("4") }

              expect(Rails).to have_received(:version).once
            end
          end
        end

        describe ".rails_version_less_than_4_1_1" do
          subject { described_class.rails_version_less_than_4_1_1 }

          before { described_class.instance_variable_set :@rails_version_less_than, nil }

          context "with Rails 4.1.0" do
            before { allow(Rails).to receive(:version).and_return("4.1.0") }

            it { is_expected.to eq(true) }
          end

          context "with Rails 4.1.1" do
            before { allow(Rails).to receive(:version).and_return("4.1.1") }

            it { is_expected.to eq(false) }
          end
        end
      end

      describe ".smart_trim" do
        it "trims smartly" do
          s = "1234567890"

          expect(described_class.smart_trim(s, -1)).to eq("1234567890")
          expect(described_class.smart_trim(s, 0)).to eq("1234567890")
          expect(described_class.smart_trim(s, 1)).to eq("1#{Utils::TRUNCATION_FILLER}")
          expect(described_class.smart_trim(s, 2)).to eq("1#{Utils::TRUNCATION_FILLER}0")
          expect(described_class.smart_trim(s, 3)).to eq("1#{Utils::TRUNCATION_FILLER}90")
          expect(described_class.smart_trim(s, 4)).to eq("12#{Utils::TRUNCATION_FILLER}90")
          expect(described_class.smart_trim(s, 5)).to eq("12#{Utils::TRUNCATION_FILLER}890")
          expect(described_class.smart_trim(s, 6)).to eq("123#{Utils::TRUNCATION_FILLER}890")
          expect(described_class.smart_trim(s, 7)).to eq("123#{Utils::TRUNCATION_FILLER}7890")
          expect(described_class.smart_trim(s, 8)).to eq("1234#{Utils::TRUNCATION_FILLER}7890")
          expect(described_class.smart_trim(s, 9)).to eq("1234#{Utils::TRUNCATION_FILLER}67890")
          expect(described_class.smart_trim(s, 10)).to eq("1234567890")
          expect(described_class.smart_trim(s, 11)).to eq("1234567890")
        end

        it "trims handles a hash" do
          s = { a: "1234567890" }

          expect(described_class.smart_trim(s, 9)).to eq(
            "{:a=#{Utils::TRUNCATION_FILLER}890\"}"
          )
        end
      end

      describe ".react_on_rails_pro?" do
        subject { described_class.react_on_rails_pro? }

        it { is_expected.to(eq(false)) }
      end

      describe ".react_on_rails_pro_version?" do
        subject { described_class.react_on_rails_pro_version }

        it { is_expected.to eq("") }
      end
    end
  end
end
# rubocop:enable Metrics/ModuleLength, Metrics/BlockLength

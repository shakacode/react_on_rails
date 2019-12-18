# frozen_string_literal: true

require_relative "spec_helper"

# rubocop:disable Metrics/ModuleLength, Metrics/BlockLength
module ReactOnRails
  RSpec.describe Utils do
    before do
      allow(Rails).to receive(:root).and_return(File.expand_path("."))
      ReactOnRails::Utils.instance_variable_set(:@server_bundle_path, nil)
    end

    after do
      ReactOnRails::Utils.instance_variable_set(:@server_bundle_path, nil)
    end

    describe ".bundle_js_file_path" do
      subject do
        Utils.bundle_js_file_path("webpack-bundle.js")
      end

      context "With Webpacker enabled", :webpacker do
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

        context "and file in manifest", :webpacker do
          before do
            # Note Webpacker manifest lookup is inside of the public_output_path
            # [2] (pry) ReactOnRails::WebpackerUtils: 0> Webpacker.manifest.lookup("app-bundle.js")
            # "/webpack/development/app-bundle-c1d2b6ab73dffa7d9c0e.js"
            allow(Webpacker).to receive_message_chain("manifest.lookup!")
              .with("webpack-bundle.js")
              .and_return("/webpack/dev/webpack-bundle-0123456789abcdef.js")
          end

          it { expect(subject).to eq("#{webpacker_public_output_path}/webpack-bundle-0123456789abcdef.js") }
        end

        context "manifest.json" do
          subject do
            Utils.bundle_js_file_path("manifest.json")
          end

          it { expect(subject).to eq("#{webpacker_public_output_path}/manifest.json") }
        end
      end

      context "Without Webpacker enabled" do
        before do
          allow(ReactOnRails).to receive_message_chain(:configuration, :generated_assets_dir)
            .and_return("public/webpack/dev")
          allow(ReactOnRails::WebpackerUtils).to receive(:using_webpacker?).and_return(false)
        end

        it {
          expect(subject).to eq(File.expand_path(
                                  File.join(Rails.root,
                                            "public/webpack/dev/webpack-bundle.js")
                                ))
        }
      end
    end

    if ReactOnRails::WebpackerUtils.using_webpacker?
      describe ".source_path_is_not_defined_and_custom_node_modules?" do
        it "returns false if node_modules is blank" do
          allow(ReactOnRails).to receive_message_chain("configuration.node_modules_location")
            .and_return("")
          allow(Webpacker).to receive_message_chain("config.send").with(:data)
                                                                  .and_return({})

          expect(ReactOnRails::Utils.using_webpacker_source_path_is_not_defined_and_custom_node_modules?).to eq(false)
        end

        it "returns false if source_path is defined in the config/webpacker.yml and node_modules defined" do
          allow(ReactOnRails).to receive_message_chain("configuration.node_modules_location")
            .and_return("client")
          allow(Webpacker).to receive_message_chain("config.send").with(:data)
                                                                  .and_return(source_path: "client/app")

          expect(ReactOnRails::Utils.using_webpacker_source_path_is_not_defined_and_custom_node_modules?).to eq(false)
        end

        it "returns true if node_modules is not blank and the source_path is not defined in config/webpacker.yml" do
          allow(ReactOnRails).to receive_message_chain("configuration.node_modules_location")
            .and_return("node_modules")
          allow(Webpacker).to receive_message_chain("config.send").with(:data)
                                                                  .and_return({})

          expect(ReactOnRails::Utils.using_webpacker_source_path_is_not_defined_and_custom_node_modules?).to eq(true)
        end
      end
    end

    describe ".server_bundle_js_file_path" do
      before do
        allow(Rails).to receive(:root).and_return(Pathname.new("."))
        allow(ReactOnRails::WebpackerUtils).to receive(:using_webpacker?).and_return(true)
        allow(Webpacker).to receive_message_chain("config.public_output_path")
          .and_return(Pathname.new("public/webpack/development"))
      end

      context "With Webpacker enabled and server file not in manifest", :webpacker do
        it "returns the unhashed server path" do
          server_bundle_name = "server-bundle.js"
          allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_js_file")
            .and_return(server_bundle_name)
          allow(Webpacker).to receive_message_chain("manifest.lookup!")
            .with(server_bundle_name)
            .and_raise(Webpacker::Manifest::MissingEntryError)

          path = Utils.server_bundle_js_file_path

          expect(path).to end_with("public/webpack/development/#{server_bundle_name}")
        end
      end

      context "With Webpacker enabled and server file in the manifest", :webpacker do
        it "returns the correct path hashed server path" do
          allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_js_file")
            .and_return("webpack-bundle.js")
          allow(Webpacker).to receive_message_chain("manifest.lookup!")
            .with("webpack-bundle.js")
            .and_return("webpack/development/webpack-bundle-123456.js")

          path = Utils.server_bundle_js_file_path

          expect(path).to end_with("public/webpack/development/webpack-bundle-123456.js")
        end
      end
    end

    describe ".wrap_message" do
      subject do
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
        expect(Utils.wrap_message(subject)).to eq(expected)
      end
    end

    describe ".truthy_presence" do
      context "With non-empty string" do
        subject { "foobar" }
        it "returns subject (same value as presence) for a non-empty string" do
          expect(Utils.truthy_presence(subject)).to eq(subject.presence)

          # Blank strings are nil for presence
          expect(Utils.truthy_presence(subject)).to eq(subject)
        end
      end

      context "With empty string" do
        subject { "" }
        it "returns \"\" for an empty string" do
          expect(Utils.truthy_presence(subject)).to eq(subject)
        end
      end

      context "With nil object" do
        subject { nil }
        it "returns nil (same value as presence)" do
          expect(Utils.truthy_presence(subject)).to eq(subject.presence)

          # Blank strings are nil for presence
          expect(Utils.truthy_presence(subject)).to eq(nil)
        end
      end

      context "With pathname pointing to empty dir (obj.empty? is true)" do
        subject(:empty_dir) { Pathname.new(Dir.mktmpdir) }
        it "returns Pathname object" do
          # Blank strings are nil for presence
          expect(Utils.truthy_presence(empty_dir)).to eq(empty_dir)
        end
      end

      context "With pathname pointing to empty file" do
        let(:empty_dir) { Pathname.new(Dir.mktmpdir) }
        subject(:empty_file) do
          File.basename(Tempfile.new("tempfile",
                                     empty_dir))
        end
        it "returns Pathname object" do
          expect(Utils.truthy_presence(empty_file)).to eq(empty_file)
        end
      end
    end

    describe ".rails_version_less_than" do
      subject { Utils.rails_version_less_than("4") }

      describe ".rails_version_less_than" do
        before(:each) { Utils.instance_variable_set :@rails_version_less_than, nil }

        context "with Rails 3" do
          before { allow(Rails).to receive(:version).and_return("3") }

          it { expect(subject).to eq(true) }
        end

        context "with Rails 3.2" do
          before { allow(Rails).to receive(:version).and_return("3.2") }

          it { expect(subject).to eq(true) }
        end

        context "with Rails 4" do
          before { allow(Rails).to receive(:version).and_return("4") }

          it { expect(subject).to eq(false) }
        end

        context "with Rails 4.2" do
          before { allow(Rails).to receive(:version).and_return("4.2") }

          it { expect(subject).to eq(false) }
        end

        context "with Rails 10.0" do
          before { allow(Rails).to receive(:version).and_return("10.0") }

          it { expect(subject).to eq(false) }
        end

        context "called twice" do
          before do
            allow(Rails).to receive(:version).and_return("4.2")
          end

          it "should memoize the result" do
            2.times { Utils.rails_version_less_than("4") }

            expect(Rails).to have_received(:version).once
          end
        end
      end

      describe ".rails_version_less_than_4_1_1" do
        subject { Utils.rails_version_less_than_4_1_1 }

        before(:each) { Utils.instance_variable_set :@rails_version_less_than, nil }

        context "with Rails 4.1.0" do
          before { allow(Rails).to receive(:version).and_return("4.1.0") }

          it { expect(subject).to eq(true) }
        end

        context "with Rails 4.1.1" do
          before { allow(Rails).to receive(:version).and_return("4.1.1") }

          it { expect(subject).to eq(false) }
        end
      end
    end

    describe ".smart_trim" do
      it "trims smartly" do
        s = "1234567890"

        expect(Utils.smart_trim(s, -1)).to eq("1234567890")
        expect(Utils.smart_trim(s, 0)).to eq("1234567890")
        expect(Utils.smart_trim(s, 1)).to eq("1#{Utils::TRUNCATION_FILLER}")
        expect(Utils.smart_trim(s, 2)).to eq("1#{Utils::TRUNCATION_FILLER}0")
        expect(Utils.smart_trim(s, 3)).to eq("1#{Utils::TRUNCATION_FILLER}90")
        expect(Utils.smart_trim(s, 4)).to eq("12#{Utils::TRUNCATION_FILLER}90")
        expect(Utils.smart_trim(s, 5)).to eq("12#{Utils::TRUNCATION_FILLER}890")
        expect(Utils.smart_trim(s, 6)).to eq("123#{Utils::TRUNCATION_FILLER}890")
        expect(Utils.smart_trim(s, 7)).to eq("123#{Utils::TRUNCATION_FILLER}7890")
        expect(Utils.smart_trim(s, 8)).to eq("1234#{Utils::TRUNCATION_FILLER}7890")
        expect(Utils.smart_trim(s, 9)).to eq("1234#{Utils::TRUNCATION_FILLER}67890")
        expect(Utils.smart_trim(s, 10)).to eq("1234567890")
        expect(Utils.smart_trim(s, 11)).to eq("1234567890")
      end

      it "trims handles a hash" do
        s = { a: "1234567890" }

        expect(Utils.smart_trim(s, 9)).to eq(
          "{:a=#{Utils::TRUNCATION_FILLER}890\"}"
        )
      end
    end
  end
end
# rubocop:enable Metrics/ModuleLength, Metrics/BlockLength

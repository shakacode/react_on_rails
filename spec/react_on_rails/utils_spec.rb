# frozen_string_literal: true

require_relative "spec_helper"
require "webpacker"

module ReactOnRails
  RSpec.describe Utils do
    describe ".bundle_js_file_path" do
      before do
        allow(ReactOnRails).to receive_message_chain(:configuration, :generated_assets_dir)
          .and_return("public/webpack/development")
      end

      subject do
        Utils.bundle_js_file_path("webpack-bundle.js")
      end

      context "With Webpacker enabled and file in manifest" do
        before do
          allow(Rails).to receive(:root).and_return(Pathname.new("."))
          allow(Webpacker).to receive_message_chain("dev_server.running?")
            .and_return(false)
          allow(Webpacker).to receive_message_chain("config.public_output_path")
            .and_return("/webpack/development")
          allow(Webpacker).to receive_message_chain("manifest.lookup")
            .with("webpack-bundle.js")
            .and_return("/webpack/development/webpack-bundle-0123456789abcdef.js")
          allow(Utils).to receive(:using_webpacker?).and_return(true)
        end

        it { expect(subject).to eq("public/webpack/development/webpack-bundle-0123456789abcdef.js") }
      end

      context "Without Webpacker enabled" do
        before { allow(Utils).to receive(:using_webpacker?).and_return(false) }

        it { expect(subject).to eq("public/webpack/development/webpack-bundle.js") }
      end
    end

    describe ".server_bundle_js_file_path" do
      subject do
        Utils.server_bundle_js_file_path
      end

      context "With Webpacker enabled and server file not in manifest" do
        before do
          allow(Rails).to receive(:root).and_return(Pathname.new("."))
          allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_js_file")
            .and_return("webpack-bundle.js")
          allow(Webpacker).to receive_message_chain("config.public_output_path")
            .and_return("public/webpack/development")
          allow(Webpacker).to receive_message_chain("manifest.lookup")
            .with("webpack-bundle.js")
            .and_raise(Webpacker::Manifest::MissingEntryError)
          allow(Utils).to receive(:using_webpacker?).and_return(true)
        end

        it { expect(subject).to eq("public/webpack/development/webpack-bundle.js") }
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
  end
end

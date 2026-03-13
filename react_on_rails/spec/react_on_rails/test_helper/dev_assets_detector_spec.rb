# frozen_string_literal: true

require_relative "../spec_helper"
require "tmpdir"
require "json"
require "fileutils"

# rubocop:disable RSpec/SubjectStub
describe ReactOnRails::TestHelper::DevAssetsDetector do
  let(:tmpdir) { Dir.mktmpdir }
  let(:source_dir) { File.join(tmpdir, "app", "javascript") }
  let(:dev_output_dir) { File.join(tmpdir, "public", "packs") }

  before do
    FileUtils.mkdir_p(source_dir)
    FileUtils.mkdir_p(dev_output_dir)
    FileUtils.mkdir_p(File.join(tmpdir, "config"))
  end

  after do
    FileUtils.rm_rf(tmpdir)
  end

  def write_shakapacker_yml(dev_output: "packs", test_output: "packs-test", dev_root: "public", test_root: nil)
    config = {
      "default" => {
        "source_path" => "app/javascript",
        "public_root_path" => dev_root,
        "public_output_path" => dev_output
      },
      "development" => {},
      "test" => {
        "public_root_path" => test_root,
        "public_output_path" => test_output,
        "compile" => false
      },
      "production" => {}
    }
    config["test"].compact!
    File.write(File.join(tmpdir, "config", "shakapacker.yml"), YAML.dump(config))
  end

  def write_shakapacker_yml_with_aliases(dev_output: "packs", test_output: "packs-test")
    File.write(File.join(tmpdir, "config", "shakapacker.yml"), <<~YAML)
      default: &default
        source_path: app/javascript
        public_root_path: public
        public_output_path: #{dev_output}
      development:
        <<: *default
      test:
        <<: *default
        public_output_path: #{test_output}
        compile: false
      production:
        <<: *default
    YAML
  end

  def write_manifest(dir, entries: { "application.js" => "/packs/application.js" })
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, "manifest.json"), JSON.generate(entries))
  end

  def write_source_file(name = "app.js", age_offset: 10)
    path = File.join(source_dir, name)
    File.write(path, "console.log('hello')")
    FileUtils.touch(path, mtime: Time.now - age_offset)
    path
  end

  describe "#check" do
    subject(:detector) { described_class.new }

    before do
      allow(detector).to receive(:project_root).and_return(Pathname.new(tmpdir))
      allow(ReactOnRails::Utils).to receive(:source_path).and_return(source_dir)
    end

    context "when shakapacker.yml is missing" do
      it "returns nil" do
        expect(detector.check).to be_nil
      end
    end

    context "when dev and test output paths are the same" do
      before do
        write_shakapacker_yml(dev_output: "packs", test_output: "packs")
        write_manifest(dev_output_dir)
        write_source_file
      end

      it "returns nil (no override needed)" do
        expect(detector.check).to be_nil
      end
    end

    context "when dev manifest doesn't exist" do
      before do
        write_shakapacker_yml
        write_source_file
      end

      it "returns nil" do
        FileUtils.rm_f(File.join(dev_output_dir, "manifest.json"))
        expect(detector.check).to be_nil
      end
    end

    context "when dev manifest contains HMR URLs" do
      before do
        write_shakapacker_yml
        write_manifest(dev_output_dir, entries: {
                         "application.js" => "http://localhost:3035/packs/application.js"
                       })
        write_source_file
      end

      it "returns nil (HMR assets not usable)" do
        expect(detector.check).to be_nil
      end
    end

    context "when dev assets are stale (source newer than manifest)" do
      before do
        write_shakapacker_yml
        write_manifest(dev_output_dir)
        FileUtils.touch(File.join(dev_output_dir, "manifest.json"), mtime: Time.now - 20)
        write_source_file(age_offset: 5)
      end

      it "returns nil" do
        expect(detector.check).to be_nil
      end
    end

    context "when dev static assets are fresh" do
      before do
        write_shakapacker_yml
        write_source_file(age_offset: 10)
        write_manifest(dev_output_dir)
      end

      it "returns info hash with dev output details" do
        result = detector.check
        expect(result).not_to be_nil
        expect(result[:dev_output_relative]).to eq("packs")
        expect(result[:dev_public_root_relative]).to eq("public")
        expect(result[:dev_full_path]).to eq(Pathname.new(dev_output_dir))
        expect(result[:manifest_path]).to eq(
          Pathname.new(File.join(dev_output_dir, "manifest.json"))
        )
      end
    end

    context "when no source files exist" do
      before do
        write_shakapacker_yml
        write_manifest(dev_output_dir)
      end

      it "considers dev assets fresh (nothing to compare against)" do
        result = detector.check
        expect(result).not_to be_nil
        expect(result[:dev_output_relative]).to eq("packs")
      end
    end

    context "when public roots differ but output names match" do
      let(:alt_dev_output_dir) { File.join(tmpdir, "frontend-public", "packs") }

      before do
        FileUtils.mkdir_p(alt_dev_output_dir)
        write_shakapacker_yml(
          dev_output: "packs",
          test_output: "packs",
          dev_root: "frontend-public",
          test_root: "public"
        )
        write_source_file(age_offset: 10)
        write_manifest(alt_dev_output_dir)
      end

      it "still returns dev output details because the full paths differ" do
        result = detector.check
        expect(result).not_to be_nil
        expect(result[:dev_output_relative]).to eq("packs")
        expect(result[:dev_public_root_relative]).to eq("frontend-public")
        expect(result[:dev_full_path]).to eq(Pathname.new(alt_dev_output_dir))
      end
    end

    context "when shakapacker.yml uses YAML aliases" do
      before do
        write_shakapacker_yml_with_aliases
        write_source_file(age_offset: 10)
        write_manifest(dev_output_dir)
      end

      it "parses aliases and returns reusable dev output details" do
        result = detector.check
        expect(result).not_to be_nil
        expect(result[:dev_output_relative]).to eq("packs")
      end
    end

    context "when manifest has nested HMR URLs" do
      before do
        write_shakapacker_yml
        write_source_file(age_offset: 10)
        write_manifest(dev_output_dir, entries: {
                         "entrypoints" => {
                           "application" => {
                             "js" => ["http://localhost:3035/packs/application.js"]
                           }
                         }
                       })
      end

      it "returns nil (nested HMR assets are not usable)" do
        expect(detector.check).to be_nil
      end
    end
  end

  describe ".try_activate_dev_assets!" do
    let(:mock_config) do
      instance_double(Shakapacker::Configuration,
                      instance_variable_set: nil,
                      send: frozen_data)
    end
    let(:mock_instance) do
      instance_double(Shakapacker::Instance,
                      instance_variable_defined?: true,
                      remove_instance_variable: nil)
    end
    let(:frozen_data) { { public_output_path: "packs-test" }.freeze }

    before do
      allow(Shakapacker).to receive_messages(config: mock_config, instance: mock_instance)
      allow(mock_config).to receive(:respond_to?).with(:data, true).and_return(true)
      allow(mock_config).to receive(:send).with(:data).and_return(frozen_data)
    end

    context "when dev assets are reusable" do
      let(:dev_result) do
        {
          dev_public_root_relative: "public",
          dev_output_relative: "packs",
          dev_full_path: Pathname.new(dev_output_dir),
          manifest_path: Pathname.new(File.join(dev_output_dir, "manifest.json"))
        }
      end

      before do
        detector = instance_double(described_class)
        allow(described_class).to receive(:new).and_return(detector)
        allow(detector).to receive(:check).and_return(dev_result)
      end

      it "returns true" do
        expect(described_class.try_activate_dev_assets!).to be true
      end

      it "overrides Shakapacker data with dev output path" do
        expect(mock_config).to receive(:instance_variable_set).with(:@data, anything) do |_name, new_data|
          expect(new_data[:public_root_path]).to eq("public")
          expect(new_data[:public_output_path]).to eq("packs")
          expect(new_data).to be_frozen
        end
        described_class.try_activate_dev_assets!
      end

      it "overrides string-keyed Shakapacker data with dev output path" do
        string_keyed_data = {
          "public_root_path" => "test-public",
          "public_output_path" => "packs-test"
        }.freeze

        allow(mock_config).to receive(:send).with(:data).and_return(string_keyed_data)
        expect(mock_config).to receive(:instance_variable_set).with(:@data, anything) do |_name, new_data|
          expect(new_data["public_root_path"]).to eq("public")
          expect(new_data["public_output_path"]).to eq("packs")
        end
        described_class.try_activate_dev_assets!
      end

      it "clears the manifest cache" do
        expect(mock_instance).to receive(:remove_instance_variable).with(:@manifest)
        described_class.try_activate_dev_assets!
      end
    end

    context "when dev assets are not reusable" do
      before do
        detector = instance_double(described_class)
        allow(described_class).to receive(:new).and_return(detector)
        allow(detector).to receive(:check).and_return(nil)
      end

      it "returns false" do
        expect(described_class.try_activate_dev_assets!).to be false
      end

      it "does not modify Shakapacker config" do
        expect(mock_config).not_to receive(:instance_variable_set)
        described_class.try_activate_dev_assets!
      end
    end

    context "when an error occurs" do
      before do
        allow(described_class).to receive(:new).and_raise(StandardError, "unexpected error")
      end

      it "returns false without raising" do
        expect(described_class.try_activate_dev_assets!).to be false
      end
    end

    context "when shakapacker config data is unavailable" do
      before do
        allow(mock_config).to receive(:send).with(:data).and_return(nil)
        detector = instance_double(described_class)
        allow(described_class).to receive(:new).and_return(detector)
        allow(detector).to receive(:check).and_return(
          dev_public_root_relative: "public",
          dev_output_relative: "packs",
          dev_full_path: Pathname.new(dev_output_dir),
          manifest_path: Pathname.new(File.join(dev_output_dir, "manifest.json"))
        )
      end

      it "returns false without mutating shakapacker config" do
        expect(mock_config).not_to receive(:instance_variable_set)
        expect(described_class.try_activate_dev_assets!).to be false
      end
    end

    it "resets the HMR warning flag before each activation attempt" do
      described_class.instance_variable_set(described_class::HMR_WARNING_PRINTED, true)
      detector = instance_double(described_class)
      allow(described_class).to receive(:new).and_return(detector)
      allow(detector).to receive(:check).and_return(nil)

      described_class.try_activate_dev_assets!

      expect(described_class.instance_variable_defined?(described_class::HMR_WARNING_PRINTED)).to be(false)
    end
  end
end
# rubocop:enable RSpec/SubjectStub

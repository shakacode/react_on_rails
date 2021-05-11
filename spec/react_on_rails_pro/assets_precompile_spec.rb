# frozen_string_literal: true

require_relative "./spec_helper"
require_relative "../../lib/react_on_rails_pro/assets_precompile"

describe ReactOnRailsPro::AssetsPrecompile do # rubocop:disable Metrics/BlockLength
  describe ".zipped_bundles_filename" do
    it "returns a string dependant on bundles_cache_key" do
      instance = described_class.instance
      allow(instance).to receive(:bundles_cache_key).and_return("bundles_cache_key")

      expect(instance.zipped_bundles_filename).to eq("precompile-cache.bundles_cache_key.production.gz")
      expect(instance).to have_received(:bundles_cache_key).once
    end
  end

  describe ".zipped_bundles_filepath" do
    it "returns a pathname dependant on Rails.root & zipped_bundles_filename" do
      rails_stub = Module.new do
        def self.root
          Pathname.new(Dir.pwd)
        end
      end
      stub_const("Rails", rails_stub)

      instance = described_class.instance
      allow(instance).to receive(:zipped_bundles_filename).and_return("zipped_bundles_filename")

      expect(instance.zipped_bundles_filepath).to eq(Rails.root.join("tmp", "bundle_cache", "zipped_bundles_filename"))
      expect(instance).to have_received(:zipped_bundles_filename).once
    end
  end

  describe ".bundles_cache_key" do
    it "calls ReactOnRailsPro::Utils.digest_of_globs with the union of " \
    "Webpacker.config.source_path & ReactOnRailsPro.configuration.dependency_globs" do
      expected_parameters = %w[source_path dependency_globs]

      source_path = instance_double(Pathname)
      allow(source_path).to receive(:join).and_return(expected_parameters.first)

      webpacker_config = instance_double(Webpacker::Configuration)
      allow(webpacker_config).to receive(:source_path).and_return(source_path)

      allow(Webpacker).to receive(:config).and_return(webpacker_config)

      ror_pro_config = instance_double(ReactOnRailsPro::Configuration)

      allow(ror_pro_config).to receive(:dependency_globs).and_return([expected_parameters.last])

      allow(ReactOnRailsPro).to receive(:configuration).and_return(ror_pro_config)

      expect(ReactOnRailsPro::Utils).to receive(:digest_of_globs).with(expected_parameters)

      described_class.instance.bundles_cache_key
    end
  end

  describe ".remote_bundle_cache_adapter" do
    it "raises an error if not assigned a module" do
      error_message = "config.remote_bundle_cache_adapter must have a module assigned"
      expect do
        described_class.instance.remote_bundle_cache_adapter
      end.to raise_error(ReactOnRailsPro::Error,
                         error_message)
    end

    it "returns configuration.remote_bundle_cache_adapter" do
      adapter = Module.new do
        def self.build(_filename)
          true
        end
      end

      ror_pro_config = instance_double(ReactOnRailsPro::Configuration)
      allow(ror_pro_config).to receive(:remote_bundle_cache_adapter).and_return(adapter)
      allow(ReactOnRailsPro).to receive(:configuration).and_return(ror_pro_config)

      expect(described_class.instance.remote_bundle_cache_adapter).to equal(adapter)
    end
  end

  describe ".build_bundles" do
    it "triggers build without any parameters" do
      adapter = Module.new do
        def self.build(_filename)
          true
        end
      end

      allow(described_class.instance).to receive(:remote_bundle_cache_adapter).and_return(adapter)

      expect do
        described_class.instance.build_bundles
      end.to raise_error(ArgumentError,
                         "wrong number of arguments (given 0, expected 1)")
    end
  end

  describe ".build_or_fetch_bundles" do
    context "when ENV['DISABLE_PRECOMPILE_CACHE'] is not present" do
      before do
        ENV["DISABLE_PRECOMPILE_CACHE"] = nil
      end

      it "tries to fetch cached bundles" do
        instance = described_class.instance

        expect(instance).to receive(:fetch_and_unzip_cached_bundles).once.and_return(true)
        expect(instance).not_to receive(:build_bundles)
        expect(instance).not_to receive(:cache_bundles)

        instance.build_or_fetch_bundles
      end

      it "calls build_bundles & cache_bundles if cached bundles can't be fetched" do
        instance = described_class.instance

        allow(instance).to receive(:fetch_and_unzip_cached_bundles).and_return(false)
        expect(instance).to receive(:fetch_and_unzip_cached_bundles).once
        allow(instance).to receive(:build_bundles).and_return(nil)
        expect(instance).to receive(:build_bundles).once
        allow(instance).to receive(:cache_bundles).and_return(nil)
        expect(instance).to receive(:cache_bundles).once

        instance.build_or_fetch_bundles
      end
    end

    context "when ENV['DISABLE_PRECOMPILE_CACHE'] is present" do
      before do
        ENV["DISABLE_PRECOMPILE_CACHE"] = "true"
      end

      it "doesn't check for cached bundles" do
        instance = described_class.instance

        allow(instance).to receive(:build_bundles).and_return(nil)
        expect(instance).to receive(:build_bundles).once
        expect(instance).not_to receive(:cache_bundles)
        expect(instance).not_to receive(:fetch_and_unzip_cached_bundles)

        instance.build_or_fetch_bundles
      end
    end
  end

  describe ".fetch_bundles" do
    it "calls remote_bundle_cache_adapter.fetch with zipped_bundles_filename" do
      adapter = Class.new do
        def self.fetch(*)
          true
        end
      end

      adapter_double = class_double(adapter)
      allow(adapter_double).to receive(:fetch).and_return(true)

      unique_variable = { unique_key: "a unique value" }

      instance = described_class.instance
      allow(instance).to receive(:remote_bundle_cache_adapter).and_return(adapter_double)
      allow(instance).to receive(:zipped_bundles_filename).and_return(unique_variable)
      allow(instance).to receive(:zipped_bundles_filepath).and_return("zipped_bundles_filepath")

      allow(File).to receive(:open).and_return(true)
      expect(File).to receive(:open).once

      expect(instance.fetch_bundles).to be_truthy

      expect(adapter_double).to have_received(:fetch).with({ zipped_bundles_filename: unique_variable })
    end
  end

  describe ".fetch_and_unzip_cached_bundles" do
    it "tries to fetch bundles if local cache is not detected" do
      allow(File).to receive(:exist?).and_return(false)

      instance = described_class.instance
      allow(instance).to receive(:fetch_bundles).and_return(false)
      allow(instance).to receive(:zipped_bundles_filepath).and_return("a")

      expect(instance.fetch_and_unzip_cached_bundles).to eq(false)
    end

    it "does not try to fetch remote cache if local cache exists" do
      allow(File).to receive(:exist?).and_return(true, false)

      instance = described_class.instance
      expect(instance).not_to receive(:fetch_bundles)
      allow(instance).to receive(:zipped_bundles_filepath).and_return("a")

      expect(instance.fetch_and_unzip_cached_bundles).to eq(true)
    end

    it "returns the same value as fetch_bundles" do
      allow(File).to receive(:exist?).and_return(false)

      instance = described_class.instance
      allow(instance).to receive(:zipped_bundles_filepath).and_return("a")
      expect(instance).to receive(:fetch_bundles).once.and_return(true)

      expect(instance.fetch_and_unzip_cached_bundles).to eq(true)
    end
  end

  describe ".cache_bundles" do
    it "calls remote_bundle_cache_adapter.upload with zipped_bundles_filepath" do
      webpacker_stub = Module.new do
        def self.public_output_path
          "a"
        end

        def self.config
          self
        end
      end
      stub_const("Webpacker", webpacker_stub)

      rake_stub = Module.new do
        def self.sh(_string)
          true
        end
      end
      stub_const("Rake", rake_stub)

      adapter = Class.new do
        def self.upload(*)
          true
        end
      end

      adapter_double = class_double(adapter)
      allow(adapter_double).to receive(:upload).and_return(true)

      unique_variable = { another_unique_key: "another unique value" }

      instance = described_class.instance
      allow(instance).to receive(:remote_bundle_cache_adapter).and_return(adapter_double)
      allow(instance).to receive(:zipped_bundles_filename).and_return("zipped_bundles_filename")
      allow(instance).to receive(:zipped_bundles_filepath).and_return(unique_variable)

      expect(instance.cache_bundles).to be_truthy

      expect(adapter_double).to have_received(:upload).with({ zipped_bundles_filepath: unique_variable })
    end
  end
end

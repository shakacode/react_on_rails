# frozen_string_literal: true

require_relative "./spec_helper"

describe ReactOnRailsPro::Cache, :caching do
  describe ".fetch_react_component" do
    let(:logger_mock) { instance_double("Rails.logger").as_null_object }

    before do
      allow(Rails).to receive(:logger).and_return(logger_mock)
    end

    it "fetches the value from the cache" do
      result = "<div>Something</div>"
      create_component_code = instance_double("create_component_code")
      allow(create_component_code).to receive(:call) { result }

      react_component_string1 = described_class.fetch_react_component("MyComponent",
                                                                      if: true,
                                                                      cache_key: "the_cache_key") do
        create_component_code.call
      end
      react_component_string2 = described_class.fetch_react_component("MyComponent",
                                                                      if: true,
                                                                      cache_key: "the_cache_key") do
        create_component_code.call
      end

      expect(react_component_string1).to eq(result)
      expect(react_component_string2).to eq(result)
      expect(create_component_code).to have_received(:call).once
      expect(cache_data.keys.first)
        .to eq("ror_component/#{ReactOnRails::VERSION}/#{ReactOnRailsPro::VERSION}/MyComponent/the_cache_key")
      expect(cache_data.values.first.value).to eq(result)
    end

    it "fetches the value from the cache if cache_key is a lambda" do
      result = "<div>Something</div>"
      create_component_code = instance_double("create_component_code")
      allow(create_component_code).to receive(:call) { result }

      react_component_string1 = described_class.fetch_react_component("MyComponent",
                                                                      unless: false,
                                                                      cache_key: -> { "the_cache_key" }) do
        create_component_code.call
      end
      react_component_string2 = described_class.fetch_react_component("MyComponent",
                                                                      unless: false,
                                                                      cache_key: -> { "the_cache_key" }) do
        create_component_code.call
      end

      expect(react_component_string1).to eq(result)
      expect(react_component_string2).to eq(result)
      expect(create_component_code).to have_received(:call).once
      expect(cache_data.keys.first)
        .to eq("ror_component/#{ReactOnRails::VERSION}/#{ReactOnRailsPro::VERSION}/MyComponent/the_cache_key")
      expect(cache_data.values.first.value).to eq(result)
    end

    it "skips the cache if option :if is false" do
      result = "<div>Something</div>"
      create_component_code = instance_double("create_component_code")
      allow(create_component_code).to receive(:call) { result }

      react_component_string1 = described_class.fetch_react_component("MyComponent",
                                                                      if: false,
                                                                      cache_key: -> { "the_cache_key" }) do
        create_component_code.call
      end
      react_component_string2 = described_class.fetch_react_component("MyComponent",
                                                                      if: false,
                                                                      cache_key: -> { "the_cache_key" }) do
        create_component_code.call
      end

      expect(react_component_string1).to eq(result)
      expect(react_component_string2).to eq(result)
      expect(create_component_code).to have_received(:call).twice
      expect(cache_data.keys.size).to eq(0)
    end

    it "skips the cache if option :unless is true" do
      result = "<div>Something</div>"
      create_component_code = instance_double("create_component_code")
      allow(create_component_code).to receive(:call) { result }

      react_component_string1 = described_class.fetch_react_component("MyComponent",
                                                                      unless: true,
                                                                      cache_key: -> { "the_cache_key" }) do
        create_component_code.call
      end
      react_component_string2 = described_class.fetch_react_component("MyComponent",
                                                                      unless: true,
                                                                      cache_key: -> { "the_cache_key" }) do
        create_component_code.call
      end

      expect(react_component_string1).to eq(result)
      expect(react_component_string2).to eq(result)
      expect(create_component_code).to have_received(:call).twice
      expect(cache_data.keys.size).to eq(0)
    end
  end

  describe ".base_cache_key" do
    it "has the basic values" do
      result = described_class.base_cache_key("foobar")

      expect(result).to eq(["foobar", ReactOnRails::VERSION, ReactOnRailsPro::VERSION])
    end

    it "has the bundle_hash if prerender is true" do
      allow(ReactOnRailsPro::Utils).to receive(:bundle_hash).and_return("123456")

      result = described_class.base_cache_key("foobar", prerender: true)

      expect(result).to eq(["foobar", ReactOnRails::VERSION, ReactOnRailsPro::VERSION, "123456"])
    end
  end

  describe ".react_component_cache_key" do
    it "properly expands cache keys without the serializers" do
      cacheable = instance_double("cacheable")
      allow(cacheable).to receive(:cache_key).and_return("the_cache_key")
      allow(ReactOnRailsPro::Utils).to receive(:bundle_hash).and_return("123456")

      result = described_class.react_component_cache_key("Foobar",
                                                         cache_key: cacheable, prerender: true)

      expect(result).to eq(["ror_component", ReactOnRails::VERSION, ReactOnRailsPro::VERSION, "123456", "Foobar",
                            cacheable])
    end

    it "properly expands cache keys with the serializers" do
      cacheable = instance_double("cacheable")
      allow(cacheable).to receive(:cache_key).and_return("the_cache_key")
      allow(ReactOnRailsPro::Utils).to receive(:bundle_hash).and_return("123456")
      allow(described_class).to receive(:serializers_cache_key).and_return("abc")

      result = described_class.react_component_cache_key("Foobar", cache_key: cacheable,
                                                                   prerender: true)

      expect(result).to eq(["ror_component", ReactOnRails::VERSION, ReactOnRailsPro::VERSION,
                            "123456", "abc", "Foobar", cacheable])
    end
  end

  describe ".serializers_cache_key" do
    let(:md5_instance) { instance_double(Digest::MD5) }

    context "when serializer_files is defined" do
      it "returns an MD5 based on the files" do
        serializer_glob = File.join(FixturesHelper.fixtures_dir, "app", "views", "**", "*.jbuilder")
        allow(ReactOnRailsPro.configuration).to receive(:serializer_globs).and_return(serializer_glob)
        allow(Digest::MD5).to receive(:new).and_return(md5_instance)
        allow(md5_instance).to receive(:file)
        allow(md5_instance).to receive(:hexdigest).and_return("eb3dc8ec96886ec81203c9e13f0277a7")

        result = described_class.serializers_cache_key

        expect(result).to eq("eb3dc8ec96886ec81203c9e13f0277a7")
      end
    end

    context "when serializer_files is not defined" do
      it "returns nil" do
        allow(ReactOnRailsPro.configuration).to receive(:serializer_globs).and_return(nil)

        result = described_class.serializers_cache_key

        expect(result).to be_nil
      end
    end
  end
end

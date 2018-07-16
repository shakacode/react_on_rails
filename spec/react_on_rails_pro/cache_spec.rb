# frozen_string_literal: true

require_relative "./spec_helper"

describe ReactOnRailsPro::Cache, :caching do
  describe ".fetch_react_component" do
    it "fetches the value from the cache" do
      result = "<div>Something</div>"
      create_component_code = double("create_component_code")
      allow(create_component_code).to receive(:call) { result }

      react_component_string1 = ReactOnRailsPro::Cache.fetch_react_component("MyComponent",
                                                                             cache_key: "the_cache_key") do
        create_component_code.call
      end
      react_component_string2 = ReactOnRailsPro::Cache.fetch_react_component("MyComponent",
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
  end

  describe ".base_cache_key" do
    it "has the basic values" do
      result = ReactOnRailsPro::Cache.base_cache_key("foobar")

      expect(result).to eq(["foobar", ReactOnRails::VERSION, ReactOnRailsPro::VERSION])
    end

    it "has the bundle_hash if prerender is true" do
      allow(ReactOnRailsPro::Utils).to receive(:bundle_hash).and_return("123456")

      result = ReactOnRailsPro::Cache.base_cache_key("foobar", prerender: true)

      expect(result).to eq(["foobar", ReactOnRails::VERSION, ReactOnRailsPro::VERSION, "123456"])
    end
  end

  describe ".react_component_cache_key" do
    it "properly expands cache keys without the serializers" do
      cacheable = double("cacheable")
      allow(cacheable).to receive(:cache_key) { "the_cache_key" }
      allow(ReactOnRailsPro::Utils).to receive(:bundle_hash).and_return("123456")

      result = ReactOnRailsPro::Cache.react_component_cache_key("Foobar",
                                                                cache_key: cacheable, prerender: true)

      expect(result).to eq(["ror_component", ReactOnRails::VERSION, ReactOnRailsPro::VERSION, "123456", "Foobar",
                            cacheable])
    end

    it "properly expands cache keys with the serializers" do
      cacheable = double("cacheable")
      allow(cacheable).to receive(:cache_key) { "the_cache_key" }
      allow(ReactOnRailsPro::Utils).to receive(:bundle_hash).and_return("123456")
      allow(ReactOnRailsPro::Cache).to receive(:serializers_cache_key).and_return("abc")

      result = ReactOnRailsPro::Cache.react_component_cache_key("Foobar", cache_key: cacheable,
                                                                          prerender: true)

      expect(result).to eq(["ror_component", ReactOnRails::VERSION, ReactOnRailsPro::VERSION,
                            "123456", "abc", "Foobar", cacheable])
    end
  end

  describe ".serializers_cache_key" do
    context "serializer_files is defined" do
      it "returns an MD5 based on the files" do
        serializer_glob = File.join(FixturesHelper.fixtures_dir, "app", "views", "**", "*.jbuilder")
        allow(ReactOnRailsPro.configuration).to receive(:serializer_globs).and_return(serializer_glob)
        allow_any_instance_of(Digest::MD5).to receive(:hexdigest).and_return("eb3dc8ec96886ec81203c9e13f0277a7")

        result = ReactOnRailsPro::Cache.serializers_cache_key

        expect(result).to eq("eb3dc8ec96886ec81203c9e13f0277a7")
      end
    end

    context "serializer_files is not defined" do
      it "returns nil" do
        allow(ReactOnRailsPro.configuration).to receive(:serializer_globs).and_return(nil)

        result = ReactOnRailsPro::Cache.serializers_cache_key

        expect(result).to be_nil
      end
    end
  end
end

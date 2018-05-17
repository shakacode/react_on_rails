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
      expect(cache_data.keys.first).to eq("ror_component/11.0.7/0.6.0/MyComponent/the_cache_key")
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
    it "properly expands cache keys" do
      cacheable = double("cacheable")
      allow(cacheable).to receive(:cache_key) { "the_cache_key" }
      allow(ReactOnRailsPro::Utils).to receive(:bundle_hash).and_return("123456")

      result = ReactOnRailsPro::Cache.react_component_cache_key("Foobar", cache_key: cacheable,
                                                                          prerender: true)

      expect(result).to eq(["ror_component", ReactOnRails::VERSION, ReactOnRailsPro::VERSION, "123456", "Foobar",
                            cacheable])
    end
  end
end

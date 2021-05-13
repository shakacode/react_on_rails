# frozen_string_literal: true

require_relative "./spec_helper"

describe ReactOnRailsPro::Cache, :caching do
  describe ".fetch_react_component" do
    let(:logger_mock) { instance_double("Rails.logger").as_null_object }

    before do
      allow(Rails).to receive(:logger).and_return(logger_mock)
    end

    it "fetches the value from the cache if the value is a string" do
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

    it "fetches the value from the cache if the value is a Hash" do
      html = "<div>Something</div>"
      ssr_result = { component_html: html }
      create_component_code = instance_double("create_component_code")
      allow(create_component_code).to receive(:call) { ssr_result }

      result1 = described_class.fetch_react_component("MyComponent",
                                                      if: true,
                                                      cache_key: "the_cache_key") do
        create_component_code.call
      end

      result2 = described_class.fetch_react_component("MyComponent",
                                                      if: true,
                                                      cache_key: "the_cache_key") do
        create_component_code.call
      end

      expect(result1[:RORP_CACHE_HIT]).to eq(false)
      expect(result2[:RORP_CACHE_HIT]).to eq(true)
      expect(result2[:RORP_CACHE_KEY])
        .to eq(described_class.react_component_cache_key("MyComponent", { cache_key: "the_cache_key" }))

      expect(create_component_code).to have_received(:call).once
      string_cache_key = "ror_component/#{ReactOnRails::VERSION}/#{ReactOnRailsPro::VERSION}/MyComponent/the_cache_key"
      expect(cache_data.keys.first).to eq(string_cache_key)
      expect(cache_data.values.first.value[:component_html]).to eq(html)
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
    it "properly expands cache keys without the dependencies" do
      cacheable = instance_double("cacheable")
      allow(cacheable).to receive(:cache_key).and_return("the_cache_key")
      allow(ReactOnRailsPro::Utils).to receive(:bundle_hash).and_return("123456")

      result = described_class.react_component_cache_key("Foobar",
                                                         cache_key: cacheable, prerender: true)

      expect(result).to eq(["ror_component", ReactOnRails::VERSION, ReactOnRailsPro::VERSION, "123456", "Foobar",
                            cacheable])
    end

    it "properly expands cache keys with the dependencies" do
      cacheable = instance_double("cacheable")
      allow(cacheable).to receive(:cache_key).and_return("the_cache_key")
      allow(ReactOnRailsPro::Utils).to receive(:bundle_hash).and_return("123456")
      allow(described_class).to receive(:dependencies_cache_key).and_return("abc")

      result = described_class.react_component_cache_key("Foobar", cache_key: cacheable,
                                                                   prerender: true)

      expect(result).to eq(["ror_component", ReactOnRails::VERSION, ReactOnRailsPro::VERSION,
                            "123456", "abc", "Foobar", cacheable])
    end
  end

  describe ".dependencies_cache_key" do
    context "when dependency_globs is defined" do
      it "calls Utils::digest_of_globs" do
        dependency_glob = File.join(FixturesHelper.fixtures_dir, "app", "views", "**", "*.jbuilder")
        allow(ReactOnRailsPro.configuration).to receive(:dependency_globs).and_return(dependency_glob)

        allow(ReactOnRailsPro::Utils).to receive(:digest_of_globs).and_return(Digest::MD5.new)

        expect(ReactOnRailsPro::Utils).to receive(:digest_of_globs).once

        described_class.dependencies_cache_key
      end
    end

    context "when dependency_globs is not defined" do
      it "returns nil" do
        allow(ReactOnRailsPro.configuration).to receive(:dependency_globs).and_return(nil)

        result = described_class.dependencies_cache_key

        expect(result).to be_nil
      end
    end
  end
end

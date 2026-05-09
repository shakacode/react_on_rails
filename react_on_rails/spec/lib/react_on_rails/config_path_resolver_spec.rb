# frozen_string_literal: true

require_relative "../../react_on_rails/spec_helper"
require_relative "../../../lib/react_on_rails/config_path_resolver"
require "fileutils"
require "tmpdir"

RSpec.describe ReactOnRails::ConfigPathResolver do
  let(:resolver_class) do
    Class.new do
      include ReactOnRails::ConfigPathResolver

      attr_reader :warnings

      def initialize
        @warnings = []
      end

      def add_warning(message)
        @warnings << message
      end
    end
  end

  let(:resolver) { resolver_class.new }

  def stub_node_modules_location(path)
    allow(ReactOnRails).to receive(:configuration).and_return(
      instance_double(ReactOnRails::Configuration, node_modules_location: path)
    )
  end

  describe "#resolved_package_root" do
    let(:rails_root) { Pathname.new("/tmp/myapp/rails") }

    before do
      allow(Rails).to receive(:root).and_return(rails_root)
    end

    it "resolves root package paths to Rails.root" do
      [nil, "", ".", rails_root.to_s, "#{rails_root}/"].each do |node_modules_location|
        resolver = resolver_class.new
        stub_node_modules_location(node_modules_location)

        expect(resolver.send(:resolved_package_root)).to eq(rails_root.to_s)
        expect(resolver.send(:resolved_package_json_path)).to eq(rails_root.join("package.json").to_s)
        expect(resolver.send(:resolved_package_path, "pnpm-lock.yaml")).to eq(rails_root.join("pnpm-lock.yaml").to_s)
      end
    end

    it "resolves nested package paths relative to Rails.root" do
      stub_node_modules_location("../client")

      expect(resolver.send(:resolved_package_root)).to eq("/tmp/myapp/client")
      expect(resolver.send(:resolved_package_json_path)).to eq("/tmp/myapp/client/package.json")
      expect(resolver.send(:resolved_package_path, "yarn.lock")).to eq("/tmp/myapp/client/yarn.lock")
    end

    it "passes through absolute package paths" do
      stub_node_modules_location("/opt/app/client/")

      expect(resolver.send(:resolved_package_root)).to eq("/opt/app/client")
      expect(resolver.send(:resolved_package_json_path)).to eq("/opt/app/client/package.json")
      expect(resolver.send(:resolved_package_path, "bun.lock")).to eq("/opt/app/client/bun.lock")
    end
  end

  describe "#package_json_path_for" do
    let(:tmpdir) { Pathname.new(Dir.mktmpdir) }

    after do
      FileUtils.remove_entry(tmpdir) if tmpdir.exist?
    end

    it "returns package.json under the configured package root when present" do
      package_root = tmpdir.join("client")
      FileUtils.mkdir_p(package_root)
      File.write(package_root.join("package.json"), "{}")

      package_json_path = resolver.send(:package_json_path_for, "package manager lockfile", package_root.to_s)

      expect(package_json_path).to eq(package_root.join("package.json").to_s)
      expect(resolver.warnings).to be_empty
    end

    it "warns once when package.json is missing from an existing package root" do
      package_root = tmpdir.join("client")
      FileUtils.mkdir_p(package_root)

      2.times do
        expect(resolver.send(:package_json_path_for, "package manager lockfile", package_root.to_s)).to be_nil
      end

      expect(resolver.warnings).to contain_exactly(
        a_string_including("#{package_root}/package.json not found; cannot detect package manager lockfile")
      )
    end

    it "warns once when the configured package root is missing" do
      package_root = tmpdir.join("missing-client")

      2.times do
        expect(resolver.send(:package_json_path_for, "React dependencies", package_root.to_s)).to be_nil
      end

      expect(resolver.warnings).to contain_exactly(
        a_string_including("node_modules_location points to #{package_root}")
      )
    end
  end

  describe "#warn_missing_package_root" do
    let(:resolver_class_without_add_warning) do
      Class.new do
        include ReactOnRails::ConfigPathResolver

        public :warn_missing_package_root
      end
    end

    it "raises a clear error when the includer does not provide add_warning" do
      resolver = resolver_class_without_add_warning.new

      expect { resolver.send(:warn_missing_package_root, "/missing/client") }
        .to raise_error(NotImplementedError, /must implement #add_warning\(message\)/)
    end
  end
end

# frozen_string_literal: true

require_relative "../spec_helper"
require "tmpdir"

RSpec.describe ReactOnRails::VersionChecker::LockfileResolution do
  describe ".all_versions" do
    def fixture_dir(name)
      File.expand_path("../fixtures/lockfiles/#{name}", __dir__)
    end

    def versions_in(files, package_name = "react-server-dom-webpack")
      Dir.mktmpdir do |dir|
        files.each { |name, content| File.write(File.join(dir, name), content) }
        described_class.all_versions(dir, package_name)
      end
    end

    it "reads the direct dependency from every supported lockfile format" do
      versions = %w[yarn_classic yarn_berry_v4 yarn_berry_v8 npm_v1 npm_v2 npm_v3
                    pnpm_v5 pnpm_v6 pnpm_v9 pnpm_v11_multidoc bun_v1 bun_v2_real].to_h do |fixture|
        [fixture, described_class.all_versions(fixture_dir(fixture), "react-on-rails")]
      end

      expect(versions.values).to all(eq(["16.6.0"])), versions.inspect
    end

    it "does not match a longer package name that shares the prefix" do
      expect(described_class.all_versions(fixture_dir("yarn_classic_similar_packages"), "react-on-rails"))
        .to eq(["1.2.3"])
    end

    it "returns nothing for missing or unreadable lockfiles" do
      %w[no_lockfile bun_lockb npm_malformed pnpm_corrupt yarn_classic_malformed].each do |fixture|
        expect(described_class.all_versions(fixture_dir(fixture), "react-on-rails")).to eq([]), fixture
      end
    end

    it "collects transitive pnpm 9 copies from packages and snapshots" do
      lockfile = <<~YAML
        lockfileVersion: '9.0'
        importers:
          .:
            dependencies:
              react-on-rails-rsc:
                specifier: 19.3.1
                version: 19.3.1(react-dom@19.3.0(react@19.3.0))(react@19.3.0)
        packages:
          react-server-dom-webpack@19.3.0:
            resolution: {integrity: sha512-abc}
          react-server-dom-webpack-extra@1.0.0:
            resolution: {integrity: sha512-def}
        snapshots:
          react-server-dom-webpack@19.3.0(react-dom@19.3.0(react@19.3.0))(react@19.3.0)(webpack@5.105.2):
            dependencies:
              react: 19.3.0
          react-server-dom-webpack@19.2.8(react-dom@19.2.8(react@19.2.8))(react@19.2.8):
            dependencies:
              react: 19.2.8
      YAML

      expect(versions_in("pnpm-lock.yaml" => lockfile)).to contain_exactly("19.3.0", "19.2.8")
    end

    it "reads pnpm 6 and pnpm 5 package keys" do
      pnpm6 = <<~YAML
        lockfileVersion: '6.0'
        dependencies: {}
        packages:
          /react-server-dom-webpack@19.2.7(react-dom@19.2.7)(react@19.2.7):
            resolution: {integrity: sha512-abc}
      YAML
      pnpm5 = <<~YAML
        lockfileVersion: 5.4
        dependencies: {}
        packages:
          /react-server-dom-webpack/19.0.1_react@19.0.1:
            resolution: {integrity: sha512-abc}
      YAML

      expect(versions_in("pnpm-lock.yaml" => pnpm6)).to eq(["19.2.7"])
      expect(versions_in("pnpm-lock.yaml" => pnpm5)).to eq(["19.0.1"])
    end

    it "collects every Yarn classic block, including merged selectors" do
      lockfile = <<~LOCK
        # yarn lockfile v1

        react-server-dom-webpack-extra@^1.0.0:
          version "1.0.0"

        "react-server-dom-webpack@~19.3.0", react-server-dom-webpack@19.3.0:
          version "19.3.0"

        react-server-dom-webpack@~19.2.8:
          version "19.2.9"
      LOCK

      expect(versions_in("yarn.lock" => lockfile)).to contain_exactly("19.3.0", "19.2.9")
    end

    it "collects every Yarn Berry entry" do
      lockfile = <<~YAML
        __metadata:
          version: 8

        "react-server-dom-webpack@npm:~19.3.0":
          version: 19.3.1

        "react-server-dom-webpack@npm:~19.2.8":
          version: 19.2.8
      YAML

      expect(versions_in("yarn.lock" => lockfile)).to contain_exactly("19.3.1", "19.2.8")
    end

    it "finds nested npm copies behind a patched top-level copy" do
      lockfile = JSON.generate(
        "lockfileVersion" => 3,
        "packages" => {
          "" => { "dependencies" => { "react-server-dom-webpack" => "19.3.1" } },
          "node_modules/react-server-dom-webpack" => { "version" => "19.3.1" },
          "node_modules/react-on-rails-rsc/node_modules/react-server-dom-webpack" => { "version" => "19.3.0" },
          "node_modules/react-server-dom-webpack-extra" => { "version" => "1.0.0" }
        }
      )

      expect(versions_in("package-lock.json" => lockfile)).to contain_exactly("19.3.1", "19.3.0")
    end

    it "finds nested npm v1 copies" do
      lockfile = JSON.generate(
        "lockfileVersion" => 1,
        "dependencies" => {
          "react-on-rails-rsc" => {
            "version" => "19.3.0",
            "dependencies" => { "react-server-dom-webpack" => { "version" => "19.2.8" } }
          }
        }
      )

      expect(versions_in("package-lock.json" => lockfile)).to eq(["19.2.8"])
    end

    it "finds npm v1 alias copies beside a patched ordinary copy" do
      lockfile = JSON.generate(
        "lockfileVersion" => 1,
        "dependencies" => {
          "react-server-dom-webpack" => { "version" => "19.3.1" },
          "flight" => { "version" => "npm:react-server-dom-webpack@19.3.0" },
          "unrelated" => { "version" => "npm:react-server-dom-webpack-extra@1.0.0" }
        }
      )

      expect(versions_in("package-lock.json" => lockfile)).to contain_exactly("19.3.1", "19.3.0")
    end

    it "reads bun.lock copies keyed by install path" do
      lockfile = <<~JSONC
        {
          "lockfileVersion": 1,
          "packages": {
            "react-server-dom-webpack": ["react-server-dom-webpack@19.3.1", "", {}, "sha512-abc"],
            "react-on-rails-rsc/react-server-dom-webpack": ["react-server-dom-webpack@19.3.0", "", {}, "sha512-def"],
          },
        }
      JSONC

      expect(versions_in("bun.lock" => lockfile)).to contain_exactly("19.3.1", "19.3.0")
    end

    it "finds npm alias copies in every lockfile format" do
      npm = JSON.generate(
        "packages" => {
          "" => { "name" => "my-app" },
          "node_modules/flight" => { "name" => "react-server-dom-webpack", "version" => "19.3.0" }
        }
      )
      classic = "\"flight@npm:react-server-dom-webpack@19.3.0\":\n  version \"19.3.0\"\n"
      berry = <<~YAML
        __metadata:
          version: 8

        "flight@npm:react-server-dom-webpack@19.3.0":
          version: 19.3.0
          resolution: "react-server-dom-webpack@npm:19.3.0"
      YAML

      expect(versions_in("package-lock.json" => npm)).to eq(["19.3.0"])
      expect(versions_in("yarn.lock" => classic)).to eq(["19.3.0"])
      expect(versions_in("yarn.lock" => berry)).to eq(["19.3.0"])
    end

    it "combines lockfiles from several package managers" do
      yarn = "react-server-dom-webpack@19.3.0:\n  version \"19.3.0\"\n"
      npm = JSON.generate("packages" => { "node_modules/react-server-dom-webpack" => { "version" => "19.3.1" } })

      expect(versions_in("yarn.lock" => yarn, "package-lock.json" => npm)).to contain_exactly("19.3.0", "19.3.1")
    end
  end
end

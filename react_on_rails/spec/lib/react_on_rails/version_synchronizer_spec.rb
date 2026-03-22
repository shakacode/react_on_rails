# frozen_string_literal: true

require "stringio"
require "tmpdir"
require "fileutils"
require_relative "../../react_on_rails/spec_helper"
require_relative "../../../lib/react_on_rails/version_synchronizer"
require_relative "../../react_on_rails/support/version_test_helpers"

module ReactOnRails
  RSpec.describe VersionSynchronizer do
    let(:io) { StringIO.new }
    let(:tmpdir) { Dir.mktmpdir }
    let(:package_json_path) { File.join(tmpdir, "package.json") }
    let(:synchronizer) { described_class.new(package_json_path: package_json_path, io: io) }

    before do
      stub_gem_version("16.4.0.rc.5")
      allow(ReactOnRails::Utils).to receive(:react_on_rails_pro_version).and_return("16.4.0.rc.5")
    end

    after do
      FileUtils.remove_entry(tmpdir)
    end

    describe "#sync" do
      context "when mismatches exist in package.json" do
        before do
          write_package_json(
            "dependencies" => {
              "react-on-rails" => "16.4.0.rc.4",
              "react-on-rails-pro" => "16.4.0.rc.4",
              "react-on-rails-pro-node-renderer" => "16.4.0.rc.4"
            }
          )
        end

        it "reports mismatches without changing files in dry-run mode" do
          result = synchronizer.sync

          expect(result.changes.size).to eq(3)
          expect(result.changed_files).to eq([])
          expect(read_package_json.dig("dependencies", "react-on-rails")).to eq("16.4.0.rc.4")
          expect(io.string).to include("Dry run only")
        end

        it "updates package.json in write mode" do
          result = synchronizer.sync(write: true)

          expect(result.changes.size).to eq(3)
          expect(result.changed_files).to eq([package_json_path])
          expect(read_package_json.dig("dependencies", "react-on-rails")).to eq("16.4.0-rc.5")
          expect(read_package_json.dig("dependencies", "react-on-rails-pro")).to eq("16.4.0-rc.5")
          expect(read_package_json.dig("dependencies", "react-on-rails-pro-node-renderer")).to eq("16.4.0-rc.5")
          expect(io.string).to include("Updated file:")
          expect(io.string).to include("refresh lockfile entries")
        end
      end

      context "when only the base package is present" do
        before do
          allow(ReactOnRails::Utils).to receive(:react_on_rails_pro_version).and_return("")
          write_package_json(
            "dependencies" => {
              "react-on-rails" => "16.4.0.rc.4"
            }
          )
        end

        it "updates the base package only" do
          result = synchronizer.sync(write: true)

          expect(result.changes.size).to eq(1)
          expect(read_package_json.dig("dependencies", "react-on-rails")).to eq("16.4.0-rc.5")
        end
      end

      context "when package.json uses non-exact version specs" do
        before do
          write_package_json(
            "dependencies" => {
              "react-on-rails" => "workspace:*",
              "react-on-rails-pro" => ">=16.0.0"
            }
          )
        end

        it "skips non-exact specs instead of rewriting them" do
          result = synchronizer.sync(write: true)

          expect(result.changes).to eq([])
          expect(result.changed_files).to eq([])
          expect(read_package_json.dig("dependencies", "react-on-rails")).to eq("workspace:*")
          expect(read_package_json.dig("dependencies", "react-on-rails-pro")).to eq(">=16.0.0")
        end
      end

      context "when mismatches exist in peerDependencies" do
        before do
          write_package_json(
            "peerDependencies" => {
              "react-on-rails" => "16.4.0.rc.4"
            }
          )
        end

        it "updates peerDependencies in write mode" do
          result = synchronizer.sync(write: true)

          expect(result.changes.size).to eq(1)
          expect(result.changed_files).to eq([package_json_path])
          expect(read_package_json.dig("peerDependencies", "react-on-rails")).to eq("16.4.0-rc.5")
        end
      end

      context "when package.json is already synchronized" do
        before do
          write_package_json(
            "dependencies" => {
              "react-on-rails" => "16.4.0-rc.5",
              "react-on-rails-pro" => "16.4.0-rc.5"
            }
          )
        end

        it "returns no changes" do
          result = synchronizer.sync

          expect(result.changes).to eq([])
          expect(io.string).to include("No package.json version mismatches found")
        end
      end

      context "when package.json is synchronized but a lockfile exists" do
        before do
          write_package_json(
            "dependencies" => {
              "react-on-rails" => "16.4.0-rc.5"
            }
          )
          File.write(File.join(tmpdir, "package-lock.json"), "{}\n")
        end

        it "prints a lockfile caveat in dry-run output" do
          result = synchronizer.sync

          expect(result.changes).to eq([])
          expect(io.string).to include("Lockfiles may still pin different versions")
        end
      end

      context "when package.json uses custom indentation" do
        before do
          custom_json = [
            "{",
            "    \"dependencies\": {",
            "        \"react-on-rails\": \"16.4.0.rc.4\"",
            "    }",
            "}"
          ].join("\n")
          File.write(package_json_path, "#{custom_json}\n")
        end

        it "preserves the original indentation width when writing" do
          synchronizer.sync(write: true)

          content = File.read(package_json_path)
          expect(content).to include("\n    \"dependencies\":")
          expect(content).to include("\n        \"react-on-rails\": \"16.4.0-rc.5\"")
        end
      end

      context "when package.json does not exist" do
        it "raises an error" do
          expect { synchronizer.sync }.to raise_error(ReactOnRails::Error, /package\.json not found/)
        end
      end

      context "when package_json_path is a directory" do
        let(:package_json_path) { tmpdir }

        it "raises an error" do
          expect { synchronizer.sync }.to raise_error(ReactOnRails::Error, /package\.json not found/)
        end
      end
    end

    def write_package_json(contents)
      File.write(package_json_path, "#{JSON.pretty_generate(contents)}\n")
    end

    def read_package_json
      JSON.parse(File.read(package_json_path))
    end
  end
end

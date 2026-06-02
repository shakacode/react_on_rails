# frozen_string_literal: true

require_relative "spec_helper"
require "json"
require "rake"
require "tmpdir"

RSpec.describe "shakapacker version rake helpers" do
  let(:rake_file) { File.expand_path("../../rakelib/shakapacker_version.rake", __dir__) }
  let(:task_context) { TOPLEVEL_BINDING.eval("self") }

  before do
    Rake::Task.clear
    load rake_file
  end

  after do
    Rake::Task.clear
  end

  describe "#update_shakapacker_package_jsons" do
    it "updates core and adapter npm package versions while preserving range prefixes" do
      Dir.mktmpdir do |dir|
        package_json_path = File.join(dir, "package.json")
        File.write(
          package_json_path,
          <<~JSON
            {
              "dependencies": {
                "shakapacker": "10.1.0",
                "shakapacker-webpack": "~10.1.0",
                "shakapacker-rspack": "^10.1.0"
              }
            }
          JSON
        )

        allow(task_context).to receive(:monorepo_root).and_return(dir)

        task_context.send(:update_shakapacker_package_jsons, "10.2.0")

        package_json = JSON.parse(File.read(package_json_path))
        expect(package_json.dig("dependencies", "shakapacker")).to eq("10.2.0")
        expect(package_json.dig("dependencies", "shakapacker-webpack")).to eq("~10.2.0")
        expect(package_json.dig("dependencies", "shakapacker-rspack")).to eq("^10.2.0")
      end
    end

    it "updates adapter packages without a core shakapacker dependency" do
      Dir.mktmpdir do |dir|
        package_json_path = File.join(dir, "package.json")
        File.write(
          package_json_path,
          <<~JSON
            {
              "dependencies": {
                "shakapacker-webpack": "~10.1.0"
              }
            }
          JSON
        )

        allow(task_context).to receive(:monorepo_root).and_return(dir)

        task_context.send(:update_shakapacker_package_jsons, "10.2.0")

        package_json = JSON.parse(File.read(package_json_path))
        expect(package_json.dig("dependencies", "shakapacker-webpack")).to eq("~10.2.0")
      end
    end

    it "leaves package.json unchanged when no shakapacker package is present" do
      Dir.mktmpdir do |dir|
        package_json_path = File.join(dir, "package.json")
        original_content = <<~JSON
          {
            "dependencies": {
              "react": "^19.0.0"
            }
          }
        JSON
        File.write(package_json_path, original_content)

        allow(task_context).to receive(:monorepo_root).and_return(dir)

        task_context.send(:update_shakapacker_package_jsons, "10.2.0")

        expect(File.read(package_json_path)).to eq(original_content)
      end
    end

    it "does not update unrelated package names that contain shakapacker" do
      Dir.mktmpdir do |dir|
        package_json_path = File.join(dir, "package.json")
        File.write(
          package_json_path,
          <<~JSON
            {
              "dependencies": {
                "@scope/shakapacker": "1.0.0",
                "shakapacker-plugin": "1.0.0",
                "my-shakapacker-helper": "1.0.0"
              }
            }
          JSON
        )

        allow(task_context).to receive(:monorepo_root).and_return(dir)

        task_context.send(:update_shakapacker_package_jsons, "10.2.0")

        package_json = JSON.parse(File.read(package_json_path))
        expect(package_json.dig("dependencies", "@scope/shakapacker")).to eq("1.0.0")
        expect(package_json.dig("dependencies", "shakapacker-plugin")).to eq("1.0.0")
        expect(package_json.dig("dependencies", "my-shakapacker-helper")).to eq("1.0.0")
      end
    end
  end
end

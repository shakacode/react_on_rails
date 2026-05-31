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
  end
end

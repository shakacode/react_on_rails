# frozen_string_literal: true

require_relative "spec_helper"
require_relative "../../rakelib/example_type"
require "json"
require "rake"
require "tmpdir"

RSpec.describe "shakapacker_examples rake helpers" do
  let(:rake_file) { File.expand_path("../../rakelib/shakapacker_examples.rake", __dir__) }
  let(:task_context) { TOPLEVEL_BINDING.eval("self") }

  describe "#pin_shakapacker_npm_version" do
    before do
      Rake::Task.clear
      allow(ReactOnRails::TaskHelpers::ExampleType).to receive(:all).and_return({ shakapacker_examples: [] })
      load rake_file
    end

    it "pins shakapacker in both dependency sections" do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, "Gemfile.lock"), "    shakapacker (9.5.0)\n")
        File.write(
          File.join(dir, "package.json"),
          <<~JSON
            {
              "dependencies": {
                "shakapacker": "^9.5.0"
              },
              "devDependencies": {
                "shakapacker": "~9.5.0"
              }
            }
          JSON
        )

        task_context.send(:pin_shakapacker_npm_version, dir)

        package_json = JSON.parse(File.read(File.join(dir, "package.json")))
        expect(package_json.dig("dependencies", "shakapacker")).to eq("9.5.0")
        expect(package_json.dig("devDependencies", "shakapacker")).to eq("9.5.0")
      end
    end

    it "reads prerelease shakapacker gem versions from Gemfile.lock" do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, "Gemfile.lock"), "    shakapacker (9.6.0.beta.0)\n")

        gem_version = task_context.send(:shakapacker_gem_version_from_lockfile, dir)

        expect(gem_version).to eq("9.6.0.beta.0")
      end
    end
  end

  describe "pinned React example generation" do
    let(:example_dir) { "/tmp/example-app" }
    let(:example_type) do
      instance_double(
        ReactOnRails::TaskHelpers::ExampleType,
        dir: example_dir,
        name: "example-app",
        name_pretty: "example-app example app",
        rails_options: "--skip-bundle",
        gemfile: "#{example_dir}/Gemfile",
        generator_shell_commands: ["rails generate react_on_rails:install"],
        pinned_react_version?: true,
        react_version_string: "18.0.0",
        clobber_task_name_short: "clobber_example_app",
        clobber_task_name: "shakapacker_examples:clobber_example_app",
        gen_task_name_short: "gen_example_app",
        gen_task_name: "shakapacker_examples:gen_example_app"
      )
    end

    before do
      Rake::Task.clear
      allow(ReactOnRails::TaskHelpers::ExampleType).to receive(:all).and_return(
        { shakapacker_examples: [example_type] }
      )
      load rake_file

      allow(task_context).to receive(:puts)
      allow(task_context).to receive(:mkdir_p)
      allow(task_context).to receive(:rm_rf)
      allow(task_context).to receive(:sh_in_dir)
      allow(task_context).to receive(:unbundled_sh_in_dir)
      allow(task_context).to receive(:apply_react_version)
    end

    it "pins shakapacker after the pinned React branch bundle install and before npm install" do
      bundle_install_calls = 0

      allow(task_context).to receive(:bundle_install_in) do |_dir|
        bundle_install_calls += 1
      end

      expect(task_context).to receive(:pin_shakapacker_npm_version).with(example_dir).ordered do
        expect(bundle_install_calls).to eq(3)
      end
      expect(task_context).to receive(:sh_in_dir)
        .with(example_dir, "npm install --legacy-peer-deps --install-links")
        .ordered

      Rake::Task["shakapacker_examples:gen_example_app"].invoke
    end
  end
end

# frozen_string_literal: true

require_relative "spec_helper"
require_relative "../../rakelib/example_type"
require "rake"

RSpec.describe "run_rspec rake tasks" do
  let(:rake_file) { File.expand_path("../../rakelib/run_rspec.rake", __dir__) }
  let(:task_context) { TOPLEVEL_BINDING.eval("self") }
  let(:example_type) do
    instance_double(
      ReactOnRails::TaskHelpers::ExampleType,
      name_pretty: "basic example app",
      name: "basic",
      rspec_task_name_short: "example_basic",
      rspec_task_name: "run_rspec:example_basic",
      gen_task_name: "shakapacker_examples:gen_basic",
      pinned_react_version?: false,
      react_version: nil
    )
  end

  before do
    Rake::Task.clear
    allow(YAML).to receive(:safe_load_file).and_return({ "example_type_data" => [] })
    allow(ReactOnRails::TaskHelpers::ExampleType).to receive(:all).and_return(
      { shakapacker_examples: [example_type] }
    )
    load rake_file

    # Stub out the generation dependency so invoking the rspec task doesn't require loading
    # shakapacker_examples.rake in this unit test.
    Rake::Task.define_task("shakapacker_examples:gen_basic")
    allow(task_context).to receive(:run_tests_in)
  end

  it "runs example specs in unbundled mode" do
    expected_dir = File.join(task_context.send(:examples_dir), "basic")

    expect(task_context).to receive(:run_tests_in).with(expected_dir, unbundled: true)
    Rake::Task["run_rspec:example_basic"].invoke
  end
end

# frozen_string_literal: true

require_relative "../../react_on_rails/spec_helper"
require "rake"

RSpec.describe "generate_response_types rake task" do
  let(:rake_file) { File.expand_path("../../../lib/tasks/generate_response_types.rake", __dir__) }

  before do
    Rake::Task.clear
    Rake::Task.define_task(:environment)
    load rake_file
    ENV.delete("REACT_ON_RAILS_RESPONSE_TYPES_OUT")
  end

  after do
    ENV.delete("REACT_ON_RAILS_RESPONSE_TYPES_OUT")
    Rake::Task.clear
  end

  it "generates response types with the default output path" do
    allow(ReactOnRails::TypeScriptResponseTypes).to receive(:generate)
      .with(output_path: nil)
      .and_return("/tmp/react_on_rails_response_types.d.ts")

    expect do
      Rake::Task["react_on_rails:generate_response_types"].invoke
    end.to output(%r{Generated React on Rails response types in /tmp/react_on_rails_response_types\.d\.ts})
      .to_stdout
    expect(ReactOnRails::TypeScriptResponseTypes).to have_received(:generate)
      .with(output_path: nil)
  end

  it "passes REACT_ON_RAILS_RESPONSE_TYPES_OUT through to the generator" do
    ENV["REACT_ON_RAILS_RESPONSE_TYPES_OUT"] = "/tmp/custom.d.ts"
    allow(ReactOnRails::TypeScriptResponseTypes).to receive(:generate)
      .with(output_path: "/tmp/custom.d.ts")
      .and_return("/tmp/custom.d.ts")

    Rake::Task["react_on_rails:generate_response_types"].invoke

    expect(ReactOnRails::TypeScriptResponseTypes).to have_received(:generate)
      .with(output_path: "/tmp/custom.d.ts")
  end
end

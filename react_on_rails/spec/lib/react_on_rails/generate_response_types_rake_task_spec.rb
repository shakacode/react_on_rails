# frozen_string_literal: true

require_relative "../../react_on_rails/spec_helper"
require "rake"

RSpec.describe "generate_response_types rake task" do
  let(:rake_file) { File.expand_path("../../../lib/tasks/generate_response_types.rake", __dir__) }
  let(:rails_application) { instance_double(Rails::Application, eager_load!: nil) }

  before do
    Rake::Task.clear
    Rake::Task.define_task(:environment)
    load rake_file
    ENV.delete("REACT_ON_RAILS_RESPONSE_TYPES_OUT")
    allow(Rails).to receive(:application).and_return(rails_application)
  end

  after do
    ENV.delete("REACT_ON_RAILS_RESPONSE_TYPES_OUT")
  end

  it "generates response types with the default output path" do
    expect(rails_application).to receive(:eager_load!).ordered
    expect(ReactOnRails::TypeScriptResponseTypes).to receive(:generate)
      .with(output_path: nil)
      .ordered
      .and_return("/tmp/react_on_rails_response_types.d.ts")

    expect do
      Rake::Task["react_on_rails:generate_response_types"].invoke
    end.to output(%r{Generated React on Rails response types in /tmp/react_on_rails_response_types\.d\.ts})
      .to_stdout
  end

  it "passes REACT_ON_RAILS_RESPONSE_TYPES_OUT through to the generator" do
    ENV["REACT_ON_RAILS_RESPONSE_TYPES_OUT"] = "/tmp/custom.d.ts"
    allow(ReactOnRails::TypeScriptResponseTypes).to receive(:generate)
      .with(output_path: "/tmp/custom.d.ts")
      .and_return("/tmp/custom.d.ts")

    Rake::Task["react_on_rails:generate_response_types"].invoke

    expect(ReactOnRails::TypeScriptResponseTypes).to have_received(:generate)
      .with(output_path: "/tmp/custom.d.ts")
    expect(rails_application).to have_received(:eager_load!)
  end
end

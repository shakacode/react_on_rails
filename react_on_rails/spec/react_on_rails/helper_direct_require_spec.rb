# frozen_string_literal: true

require_relative "spec_helper"
require "open3"
require "rbconfig"

RSpec.describe "requiring react_on_rails/helper directly" do
  it "loads the renderer parse-error dependency" do
    script = <<~RUBY
      require "react_on_rails/error"
      require "react_on_rails/helper"

      helper = Class.new { include ReactOnRails::Helper }.new
      begin
        helper.send(:raise_renderer_prerender_error, RuntimeError.new("renderer failed"), "Component", "props", "code")
      rescue ReactOnRails::PrerenderError => error
        puts error.class.name
        puts error.err.class.name
      end
    RUBY

    stdout, stderr, status = Open3.capture3(RbConfig.ruby, "-Ilib", "-e", script)

    expect(status).to be_success, stderr
    expect(stdout).to eq("ReactOnRails::PrerenderError\nRuntimeError\n")
  end
end

# frozen_string_literal: true

require_relative "spec_helper"
require "open3"
require "rbconfig"

# Invalid calls have two distinct contracts: Ruby validates them in ordinary
# applications, while RBS rejects them before entering the method when hooked.
# Separate child processes prove both without removing hooks from the test suite.
RSpec.describe "Runtime and RBS input contracts" do
  def contract_result(code, rbs:)
    env = {
      "RUBYOPT" => nil,
      "RBS_TEST_TARGET" => "ReactOnRails::Controller*,ReactOnRails::TypeScriptResponseTypes*,ReactOnRails::Utils," \
                           "ReactOnRails::GitUtils,ReactOnRails::Locales*,ReactOnRails::PrerenderError," \
                           "ReactOnRails::TestHelper",
      "RBS_TEST_OPT" => "-I sig -r pathname"
    }
    setup = <<~RUBY
      require "./spec/react_on_rails/spec_helper"
      require "react_on_rails/controller/form_responders"
      require "json"
      begin
        #{code}
        puts "ROR_CONTRACT_RESULT:" + JSON.generate({result: "accepted"})
      rescue #{rbs ? 'RBS::Test::Tester::TypeError' : 'StandardError'} => error
        puts "ROR_CONTRACT_RESULT:" + JSON.generate({error_class: error.class.name, message: error.message})
      end
    RUBY
    args = [RbConfig.ruby, "-rbundler/setup"]
    args << "-rrbs/test/setup" if rbs
    stdout, stderr, status = Open3.capture3(env, *args, "-e", setup, chdir: File.expand_path("../..", __dir__))
    expect(status.success?).to be(true), "#{stdout}\n#{stderr}"
    # Coverage tools can append output after the child's contract result.
    result_lines = stdout.lines.grep(/\AROR_CONTRACT_RESULT:/)
    expect(result_lines.size).to eq(1), "#{stdout}\n#{stderr}"
    JSON.parse(result_lines.fetch(0).delete_prefix("ROR_CONTRACT_RESULT:"))
  end

  [false, true].each do |rbs|
    context "with RBS runtime hooks #{rbs ? 'enabled' : 'absent in the isolated application'}" do
      it "rejects unknown redux_store keywords" do
        result = contract_result(<<~RUBY, rbs:)
          controller = Class.new { include ReactOnRails::Controller }.new
          controller.redux_store("TestStore", props: { a: 1 }, typo_option: true)
        RUBY
        expect(result.fetch("error_class")).to eq(rbs ? "RBS::Test::Tester::TypeError" : "ArgumentError")
        expected = rbs ? /Controller#redux_store.*ArgumentError/ : /unknown keyword: :typo_option/
        expect(result.fetch("message")).to match(expected)
      end

      it "rejects symbolic HTTP statuses" do
        result = contract_result(<<~RUBY, rbs:)
          controller = Class.new { include ReactOnRails::Controller::FormResponders }.new
          controller.render_model_errors(Object.new, status: :unprocessable_entity)
        RUBY
        expect(result.fetch("error_class")).to eq(rbs ? "RBS::Test::Tester::TypeError" : "ArgumentError")
        expected = rbs ? /render_model_errors.*ArgumentTypeError.*Integer.*unprocessable_entity/ : /Integer HTTP status/
        expect(result.fetch("message")).to match(expected)
      end

      it "rejects nil type fields" do
        result = contract_result('ReactOnRails::TypeScriptResponseTypes.define_type("Project", fields: nil)', rbs:)
        expect(result.fetch("error_class")).to eq(rbs ? "RBS::Test::Tester::TypeError" : "ReactOnRails::Error")
        expected = rbs ? /define_type.*ArgumentTypeError.*Hash.*nil/ : /fields must be a Hash, got NilClass/
        expect(result.fetch("message")).to match(expected)
      end

      it "rejects array response fields" do
        result = contract_result(<<~RUBY, rbs:)
          ReactOnRails::TypeScriptResponseTypes.define_response("projects.index", type_name: "Projects", fields: [])
        RUBY
        expect(result.fetch("error_class")).to eq(rbs ? "RBS::Test::Tester::TypeError" : "ReactOnRails::Error")
        expected = rbs ? /define_response.*ArgumentTypeError.*Hash.*\[\]/ : /fields must be a Hash, got Array/
        expect(result.fetch("message")).to match(expected)
      end
    end
  end

  it "keeps the smart_trim length constraint under runtime hooks" do
    result = contract_result('ReactOnRails::Utils.smart_trim({ a: 1 }, "5")', rbs: true)
    expect(result.fetch("error_class")).to eq("RBS::Test::Tester::TypeError")
    expect(result.fetch("message")).to match(/smart_trim.*ArgumentTypeError.*Integer/)
  end

  it "rejects non-boolean immediate_hydration under runtime hooks" do
    result = contract_result(<<~RUBY, rbs: true)
      controller = Class.new { include ReactOnRails::Controller }.new
      controller.redux_store("TestStore", immediate_hydration: "yes")
    RUBY
    expect(result.fetch("error_class")).to eq("RBS::Test::Tester::TypeError")
    expect(result.fetch("message")).to match(/redux_store.*ArgumentTypeError.*bool/)
  end

  it "requires a GitUtils handler that can report errors" do
    result = contract_result('ReactOnRails::GitUtils.uncommitted_changes?("not a handler", git_installed: false)',
                             rbs: true)
    expect(result.fetch("error_class")).to eq("RBS::Test::Tester::TypeError")
    expect(result.fetch("message")).to match(/uncommitted_changes\?.*ArgumentTypeError.*_MessageHandler/)
  end

  it "rejects unsupported asset compiler options" do
    result = contract_result("ReactOnRails::TestHelper.ensure_assets_compiled(force_compile: true)", rbs: true)
    expect(result.fetch("error_class")).to eq("RBS::Test::Tester::TypeError")
    expect(result.fetch("message")).to match(/ensure_assets_compiled.*ArgumentError/)
  end

  it "rejects integer locale directory returns" do
    result = contract_result(<<~RUBY, rbs: true)
      ReactOnRails.configuration.i18n_dir = 42
      ReactOnRails::Locales::Base.allocate.send(:i18n_dir)
    RUBY
    expect(result.fetch("error_class")).to eq("RBS::Test::Tester::TypeError")
    expect(result.fetch("message")).to match(/Base#i18n_dir.*ReturnTypeError.*42/)
  end

  it "retains the PrerenderError exception constraint" do
    result = contract_result('ReactOnRails::PrerenderError.new(err: "not an exception", props: { a: 1 })', rbs: true)
    expect(result.fetch("error_class")).to eq("RBS::Test::Tester::TypeError")
    expect(result.fetch("message")).to match(/PrerenderError#initialize.*ArgumentTypeError.*StandardError/)
  end
end

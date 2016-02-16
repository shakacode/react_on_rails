require_relative "../support/generator_spec_helper"
require_relative "../support/version_test_helpers"

describe InstallGenerator, type: :generator do
  destination File.expand_path("../../dummy-for-generators/", __FILE__)

  context "no args" do
    before(:all) { run_generator_test_with_args(%w()) }
    include_examples "base_generator:base", application_js: true
    include_examples "base_generator:no_server_rendering"
    include_examples "no_redux_generator:base"
    include_examples "no_redux_generator:no_server_rendering"
    include_examples "bootstrap:enabled"
    include_examples "js_linters:enabled"
  end

  context "--skip-js-linters" do
    before(:all) { run_generator_test_with_args(%w(--skip-js-linters)) }
    include_examples "base_generator:base", application_js: true
    include_examples "base_generator:no_server_rendering"
    include_examples "no_redux_generator:base"
    include_examples "no_redux_generator:no_server_rendering"
    include_examples "bootstrap:enabled"
    include_examples "js_linters:disabled"
  end

  context "-j" do
    before(:all) { run_generator_test_with_args(%w(-j)) }
    include_examples "base_generator:base", application_js: true
    include_examples "base_generator:no_server_rendering"
    include_examples "no_redux_generator:base"
    include_examples "no_redux_generator:no_server_rendering"
    include_examples "bootstrap:enabled"
    include_examples "js_linters:disabled"
  end

  context "--ruby-linters" do
    before(:all) { run_generator_test_with_args(%w(--ruby-linters)) }
    include_examples "base_generator:base", application_js: true
    include_examples "base_generator:no_server_rendering"
    include_examples "no_redux_generator:base"
    include_examples "no_redux_generator:no_server_rendering"
    include_examples "bootstrap:enabled"
    include_examples "js_linters:enabled"
    include_examples "ruby_linters"
  end

  context "-L" do
    before(:all) { run_generator_test_with_args(%w(-L)) }
    include_examples "base_generator:base", application_js: true
    include_examples "base_generator:no_server_rendering"
    include_examples "no_redux_generator:base"
    include_examples "no_redux_generator:no_server_rendering"
    include_examples "bootstrap:enabled"
    include_examples "js_linters:enabled"
    include_examples "ruby_linters"
  end

  context "--server-rendering" do
    before(:all) { run_generator_test_with_args(%w(--server-rendering)) }
    include_examples "base_generator:base", application_js: true
    include_examples "base_generator:server_rendering"
    include_examples "no_redux_generator:base"
    include_examples "no_redux_generator:server_rendering"
    include_examples "bootstrap:enabled"
    include_examples "js_linters:enabled"
  end

  context "-S" do
    before(:all) { run_generator_test_with_args(%w(-S)) }
    include_examples "base_generator:base", application_js: true
    include_examples "base_generator:server_rendering"
    include_examples "no_redux_generator:base"
    include_examples "no_redux_generator:server_rendering"
    include_examples "bootstrap:enabled"
    include_examples "js_linters:enabled"
  end

  context "--redux" do
    before(:all) { run_generator_test_with_args(%w(--redux)) }
    include_examples "base_generator:base", application_js: true
    include_examples "base_generator:no_server_rendering"
    include_examples "react_with_redux_generator:base"
    include_examples "react_with_redux_generator:no_server_rendering"
    include_examples "bootstrap:enabled"
    include_examples "js_linters:enabled"
  end

  context "-R" do
    before(:all) { run_generator_test_with_args(%w(-R)) }
    include_examples "base_generator:base", application_js: true
    include_examples "base_generator:no_server_rendering"
    include_examples "react_with_redux_generator:base"
    include_examples "react_with_redux_generator:no_server_rendering"
    include_examples "bootstrap:enabled"
    include_examples "js_linters:enabled"
  end

  context "--redux --server_rendering" do
    before(:all) { run_generator_test_with_args(%w(--redux --server-rendering)) }
    include_examples "base_generator:base", application_js: true
    include_examples "base_generator:server_rendering"
    include_examples "react_with_redux_generator:base"
    include_examples "react_with_redux_generator:server_rendering"
    include_examples "bootstrap:enabled"
    include_examples "js_linters:enabled"
  end

  context "-R -S" do
    before(:all) { run_generator_test_with_args(%w(-R -S)) }
    include_examples "base_generator:base", application_js: true
    include_examples "base_generator:server_rendering"
    include_examples "react_with_redux_generator:base"
    include_examples "react_with_redux_generator:server_rendering"
    include_examples "bootstrap:enabled"
    include_examples "js_linters:enabled"
  end

  context "-R -S" do
    before(:all) { run_generator_test_with_args(%w(-R -S)) }
    include_examples "base_generator:base", application_js: true
    include_examples "base_generator:server_rendering"
    include_examples "react_with_redux_generator:base"
    include_examples "react_with_redux_generator:server_rendering"
    include_examples "bootstrap:enabled"
    include_examples "js_linters:enabled"
  end

  context "without existing application.css/scss file" do
    before(:all) { run_generator_test_with_args([], application_css: false) }
    it "creates its own application.scss file" do
      assert_file("app/assets/stylesheets/application.scss")
    end
  end

  context "--heroku-deployment" do
    before(:all) { run_generator_test_with_args(%w(--heroku-deployment)) }
    include_examples "heroku_deployment"
  end

  context "-H" do
    before(:all) { run_generator_test_with_args(%w(-H)) }
    include_examples "heroku_deployment"
  end

  context "--no-skip-bootstrap" do
    before(:all) { run_generator_test_with_args(%w(--no-skip-bootstrap)) }
    include_examples "base_generator:base", application_js: true
    include_examples "bootstrap:enabled"
  end

  context "--no-skip-bootstrap" do
    before(:all) { run_generator_test_with_args(%w(--no-skip-bootstrap), application_js: false) }
    include_examples "base_generator:base", application_js: false
    include_examples "bootstrap:enabled"
  end

  context "-b" do
    before(:all) { run_generator_test_with_args(%w(-b)) }
    include_examples "bootstrap:disabled"
  end

  context "--skip-bootstrap" do
    before(:all) { run_generator_test_with_args(%w(--skip-bootstrap)) }
    include_examples "base_generator:base", application_js: true
    include_examples "bootstrap:disabled"
  end

  context "--skip-bootstrap" do
    before(:all) { run_generator_test_with_args(%w(--skip-bootstrap), application_js: false) }
    include_examples "base_generator:base", application_js: false
    include_examples "bootstrap:disabled"
  end

  context "without existing application.js or application.js.coffee file" do
    before(:all) { run_generator_test_with_args([], application_js: false) }
    include_examples "base_generator:base", application_js: false
  end

  context "with existing application.js or application.js.coffee file" do
    before(:all) { run_generator_test_with_args([], application_js: true) }
    include_examples "base_generator:base", application_js: true
  end

  context "without existing assets.rb file" do
    before(:all) { run_generator_test_with_args([], assets_rb: false) }
    include_examples "base_generator:base", assets_rb: false
  end

  context "with existing assets.rb file" do
    before(:all) { run_generator_test_with_args([], assets_rb: true) }
    include_examples "base_generator:base", assets_rb: true
  end

  context "without existing spec dir" do
    before(:all) { run_generator_test_with_args(%w(--ruby-linters), spec: false) }
    it "does not add the spec directory to the ruby-lint.yml" do
      assert_file("ruby-lint.yml") do |contents|
        refute_match(/- spec/, contents)
      end
    end
  end

  context "without existing spec dir" do
    before(:all) { run_generator_test_with_args(%w(--ruby-linters), spec: true) }
    it "adds the spec directory to the ruby-lint.yml" do
      assert_file("ruby-lint.yml") do |contents|
        assert_match(/- spec/, contents)
      end
    end
  end

  context "with missing files to trigger errors" do
    specify "GeneratorMessages has the missing file error" do
      run_generator_test_with_args([], gitignore: false)
      expected = <<-MSG.strip_heredoc
        .gitignore was not found.
        Please add the following content to your .gitignore file:
        # React on Rails
        npm-debug.log
        node_modules

        # Generated js bundles
        /app/assets/javascripts/generated/*

        MSG
      expect(GeneratorMessages.output)
        .to include(GeneratorMessages.format_error(expected))
    end
  end

  context "with helpful message" do
    specify "base generator contains a helpful message" do
      run_generator_test_with_args(%w())
      expected = <<-MSG.strip_heredoc

        What to do next:

          - Ensure your bundle and npm are up to date.

              bundle && npm i

          - Run the npm rails-server command to load the rails server.

              npm run rails-server

          - Visit http://localhost:3000/hello_world and see your React On Rails app running!

          - Run the npm express-server command to load the node server with hot reloading support.

              npm run express-server

          - Visit http://localhost:4000 and see your React On Rails app running using the Webpack Dev server.
        MSG
      expect(GeneratorMessages.output)
        .to include(GeneratorMessages.format_info(expected))
    end

    specify "react with redux generator contains a helpful message" do
      run_generator_test_with_args(%w(--redux))
      expected = <<-MSG.strip_heredoc

        What to do next:

          - Ensure your bundle and npm are up to date.

              bundle && npm i

          - Run the npm rails-server command to load the rails server.

              npm run rails-server

          - Visit http://localhost:3000/hello_world and see your React On Rails app running!

          - Run the npm express-server command to load the node server with hot reloading support.

              npm run express-server

          - Visit http://localhost:4000 and see your React On Rails app running using the Webpack Dev server.
        MSG
      expect(GeneratorMessages.output)
        .to include(GeneratorMessages.format_info(expected))
    end
  end
end

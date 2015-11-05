require File.expand_path("../../support/generator_spec_helper", __FILE__)

describe InstallGenerator, type: :generator do
  destination File.expand_path("../../dummy-for-generators/", __FILE__)

  context "no args" do
    before(:all) { run_generator_test_with_args(%w()) }
    include_examples "base_generator:base"
    include_examples "base_generator:no_server_rendering"
    include_examples "no_redux_generator:base"
    include_examples "no_redux_generator:no_server_rendering"
    include_examples "bootstrap"
    include_examples "heroku_deployment"
  end

  context "--linters" do
    before(:all) { run_generator_test_with_args(%w(-L)) }
    include_examples "base_generator:base"
    include_examples ":linters"
    include_examples "bootstrap"
    include_examples "heroku_deployment"
  end

  context "-L" do
    before(:all) { run_generator_test_with_args(%w(-L)) }
    include_examples "base_generator:base"
    include_examples ":linters"
    include_examples "bootstrap"
    include_examples "heroku_deployment"
  end

  context "--server-rendering" do
    before(:all) { run_generator_test_with_args(%w(--server-rendering)) }
    include_examples "base_generator:base"
    include_examples "base_generator:server_rendering"
    include_examples "no_redux_generator:base"
    include_examples "no_redux_generator:server_rendering"
    include_examples "bootstrap"
    include_examples "heroku_deployment"
  end

  context "-S" do
    before(:all) { run_generator_test_with_args(%w(-S)) }
    include_examples "base_generator:base"
    include_examples "base_generator:server_rendering"
    include_examples "no_redux_generator:base"
    include_examples "no_redux_generator:server_rendering"
    include_examples "bootstrap"
    include_examples "heroku_deployment"
  end

  context "--redux" do
    before(:all) { run_generator_test_with_args(%w(--redux)) }
    include_examples "base_generator:base"
    include_examples "base_generator:no_server_rendering"
    include_examples "react_with_redux_generator:base"
    include_examples "bootstrap"
    include_examples "heroku_deployment"
  end

  context "-R" do
    before(:all) { run_generator_test_with_args(%w(-R)) }
    include_examples "base_generator:base"
    include_examples "base_generator:no_server_rendering"
    include_examples "react_with_redux_generator:base"
    include_examples "bootstrap"
    include_examples "heroku_deployment"
  end

  context "--redux --server_rendering" do
    before(:all) { run_generator_test_with_args(%w(--redux --server-rendering)) }
    include_examples "base_generator:base"
    include_examples "base_generator:server_rendering"
    include_examples "react_with_redux_generator:base"
    include_examples "react_with_redux_generator:server_rendering"
    include_examples "bootstrap"
    include_examples "heroku_deployment"
  end

  context "-R -S" do
    before(:all) { run_generator_test_with_args(%w(-R -S)) }
    include_examples "base_generator:base"
    include_examples "base_generator:server_rendering"
    include_examples "react_with_redux_generator:base"
    include_examples "react_with_redux_generator:server_rendering"
    include_examples "bootstrap"
    include_examples "heroku_deployment"
  end
end

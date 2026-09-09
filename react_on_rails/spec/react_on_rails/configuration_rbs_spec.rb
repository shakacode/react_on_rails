# frozen_string_literal: true

require_relative "spec_helper"
require "open3"

RSpec.describe "Configuration runtime RBS contract" do
  def check_configuration(script, environment = "test")
    boot = <<~RUBY
      require "rails"
      require "rails/application"
      Rails.application = Class.new(Rails::Application)
      require "react_on_rails/configuration"
    RUBY
    Open3.capture3(
      { "RBS_TEST_TARGET" => "ReactOnRails::Configuration", "RBS_TEST_OPT" => "-I sig -r pathname",
        "RBS_TEST_SKIP" => "", "RBS_TEST_UNCHECKED_CLASSES" => "", "RBS_TEST_DOUBLE_SUITE" => "",
        "RBS_TEST_SAMPLE_SIZE" => "ALL", "RAILS_ENV" => environment },
      RbConfig.ruby, "-rrbs/test/setup", "-Ilib", "-e", boot + script,
      chdir: File.expand_path("../..", __dir__)
    )
  end

  it "constructs default configurations with Rails.root and nullable values in development and production" do
    %w[development production].each do |environment|
      stdout, stderr, status = check_configuration(<<~RUBY, environment)
        config = ReactOnRails::Configuration.new
        raise "root changed" unless config.node_modules_location == Rails.root
        raise "path type changed" unless config.node_modules_location.is_a?(Pathname)
        raise "unset command changed" unless config.build_test_command.nil?
        raise "database default changed" unless config.check_database_on_dev_start == true
        puts "default accepted"
      RUBY
      expect(status.success?).to be(true), stderr
      expect(stdout).to include("default accepted")
    end
  end

  it "accepts the documented String and Pathname directories through keywords and accessors" do
    stdout, stderr, status = check_configuration(<<~'RUBY')
      ["/app/locales", Pathname.new("/app/locales")].each do |path|
        config = ReactOnRails::Configuration.new(node_modules_location: path, i18n_dir: path, i18n_yml_dir: path)
        %i[node_modules_location i18n_dir i18n_yml_dir].each do |name|
          raise "constructor changed path" unless config.public_send(name) == path
          config.public_send("#{name}=", path)
          raise "accessor changed path" unless config.public_send(name) == path
        end
      end
      puts "paths accepted"
    RUBY
    expect(status.success?).to be(true), stderr
    expect(stdout).to include("paths accepted")
  end

  it "preserves nullable constructor values and accepts existing database and renderer options" do
    stdout, stderr, status = check_configuration(<<~'RUBY')
      nullable = %i[
        server_bundle_js_file prerender replay_console logging_on_server generated_assets_dir
        server_renderer_pool_size server_renderer_timeout raise_on_prerender_error webpack_generated_files
        rendering_extension build_test_command build_production_command random_dom_id auto_load_bundle
        same_bundle_for_client_and_server rendering_props_extension make_generated_server_bundle_the_entrypoint
        components_subdirectory stores_subdirectory i18n_dir i18n_yml_dir i18n_output_format
        i18n_yml_safe_load_options generated_component_packs_loading_strategy component_registry_timeout
        server_bundle_output_path enforce_private_server_bundles
      ]
      config = ReactOnRails::Configuration.new(**nullable.to_h { |name| [name, nil] }, development_mode: false)
      nullable.each do |name|
        raise "nullable keyword changed: #{name}" unless config.public_send(name).nil?
        config.public_send("#{name}=", nil)
        raise "nullable accessor changed: #{name}" unless config.public_send(name).nil?
      end
      config = ReactOnRails::Configuration.new(
        check_database_on_dev_start: false, server_renderer_pool_size: 4, server_renderer_timeout: 30,
        component_registry_timeout: 0, webpack_generated_files: ["manifest.json"],
        generated_component_packs_loading_strategy: :defer, trace: false, development_mode: false
      )
      raise "database option changed" unless config.check_database_on_dev_start == false
      raise "pool size changed" unless config.server_renderer_pool_size == 4
      raise "timeout changed" unless config.server_renderer_timeout == 30
      raise "registry timeout changed" unless config.component_registry_timeout == 0
      raise "manifest changed" unless config.webpack_generated_files == ["manifest.json"]
      raise "strategy changed" unless config.generated_component_packs_loading_strategy == :defer
      puts "options accepted"
    RUBY
    expect(status.success?).to be(true), stderr
    expect(stdout).to include("options accepted")
  end

  it "accepts documented string locale output formats without changing their values" do
    stdout, stderr, status = check_configuration(<<~RUBY)
      ["js", "JSON", :json, nil].each do |format|
        config = ReactOnRails::Configuration.new(i18n_output_format: format)
        raise "constructor changed format" unless config.i18n_output_format == format
        config.i18n_output_format = format
        raise "accessor changed format" unless config.i18n_output_format == format
      end
      puts "locale formats accepted"
    RUBY
    expect(status.success?).to be(true), stderr
    expect(stdout).to include("locale formats accepted")
  end

  it "still rejects invalid paths, booleans, integers, and collection elements" do
    stdout, stderr, status = check_configuration(<<~'RUBY')
      invalid = {
        node_modules_location: 123, i18n_dir: 123, i18n_yml_dir: 123, i18n_output_format: 123,
        prerender: "false", check_database_on_dev_start: "false", component_registry_timeout: "5000",
        server_renderer_pool_size: "4", server_renderer_timeout: "20", webpack_generated_files: [123]
      }
      invalid.each do |name, value|
        begin
          ReactOnRails::Configuration.new(**{ name => value })
          raise "invalid keyword accepted: #{name}"
        rescue RBS::Test::Tester::TypeError => error
          raise unless error.message.include?("ArgumentTypeError")
        end
        begin
          ReactOnRails::Configuration.new.public_send("#{name}=", value)
          raise "invalid accessor accepted: #{name}"
        rescue RBS::Test::Tester::TypeError => error
          raise unless error.message.include?("ArgumentTypeError")
        end
      end
      puts "invalid values rejected"
    RUBY
    expect(status.success?).to be(true), stderr
    expect(stdout).to include("invalid values rejected")
  end

  it "loads Pathname for the ordinary Rake runtime hook while preserving custom signature options" do
    launcher = <<~RUBY
      require "rake"
      require "shellwords"
      load "rakelib/run_rspec.rake"
      runtime_env = Shellwords.split(rbs_runtime_env_vars).to_h { |pair| pair.split("=", 2) }
      if ENV["RBS_TEST_OPT"]
        raise "custom signature options lost" unless runtime_env.fetch("RBS_TEST_OPT").include?(ENV["RBS_TEST_OPT"])
      end
      exec(runtime_env, "bundle", "exec", "ruby", "-Ilib", "-e", ARGV.fetch(0))
    RUBY
    script = <<~RUBY
      require "rails"
      require "rails/application"
      Rails.application = Class.new(Rails::Application)
      require "react_on_rails/configuration"
      config = ReactOnRails::Configuration.new
      raise "root changed" unless config.node_modules_location == Rails.root
      begin
        config.prerender = "false"
        raise "runtime checking was disabled"
      rescue RBS::Test::Tester::TypeError => error
        raise unless error.message.include?("ArgumentTypeError")
      end
      puts "rake runtime hook passed"
    RUBY
    [nil, "-I 'sig' -r json"].each do |options|
      stdout, stderr, status = Open3.capture3(
        { "RBS_TEST_OPT" => options, "DISABLE_RBS_RUNTIME_CHECKING" => nil,
          "RBS_TEST_SKIP" => "", "RBS_TEST_UNCHECKED_CLASSES" => "", "RBS_TEST_DOUBLE_SUITE" => "" },
        RbConfig.ruby, "-e", launcher, script, chdir: File.expand_path("../..", __dir__)
      )
      expect(status.success?).to be(true), stderr
      expect(stdout).to include("rake runtime hook passed")
    end
  end
end

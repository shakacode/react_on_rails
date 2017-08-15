# frozen_string_literal: true

require_relative "../simplecov_helper"
Dir[File.expand_path("../../support/shared_examples", __FILE__) + "/*.rb"].each { |file| require file }
generators_glob = File.expand_path("../../../../lib/generators/react_on_rails/*_generator.rb", __FILE__)
Dir[generators_glob.to_s].each { |file| require file }
include ReactOnRails::Generators

RSpec.configure do |config|
  config.after(:each) do
    GeneratorMessages.clear
  end
end

def simulate_existing_rails_files(options)
  simulate_existing_file(".gitignore") if options.fetch(:gitignore, true)
  if options.fetch(:hello_world_file, false)
    simulate_existing_file(
      "app/views/hello_world/index.html.erb",
      "<%= react_component('HelloWorldApp', props: @hello_world_props, prerender: false) %>"
    )
  end
  simulate_existing_file("Gemfile", "")
  simulate_existing_file("config/routes.rb", "Rails.application.routes.draw do\nend\n")
  simulate_existing_file("config/application.rb",
                         "module Gentest\nclass Application < Rails::Application\nend\nend)")

  return unless options.fetch(:spec, true)

  simulate_existing_dir("spec")
  simulate_existing_file("spec/rails_helper.rb",
                         "RSpec.configure do |config|\nend\n")
end

def simulate_npm_files(options)
  if options.fetch(:package_json, false)
    package_json = "client/package.json"
    package_json_data = <<-JSON.strip_heredoc
      {
        "name": "foo",
        "private": true,
        "scripts": {
          "foo": "bar"
        },
        "dependencies": {
          "foo": "^0",
          "react-on-rails": "5.2.0",
          "bar": "^0"
        },
        "devDependencies": {
        }
      }
    JSON
    simulate_existing_file(package_json, package_json_data)
  end

  return unless options.fetch(:webpack_client_base_config, false)
  config = "client/webpack.config.js"
  text = <<-TEXT
  resolve: {
    ...
  },
  plugins: [
    ...
  ]
  TEXT
  simulate_existing_file(config, text)
end

# Expects an array of strings, such as "--redux"
def run_generator_test_with_args(args, options = {})
  prepare_destination # this completely wipes the `destination` directory
  simulate_existing_rails_files(options)
  simulate_npm_files(options)
  yield if block_given?
  run_generator(args + ["--ignore-warnings"])
end

# Simulate having an existing file for cases where the generator needs to modify, not create, a file
def simulate_existing_file(file, data = "some existing text\n")
  # raise "File #{file} already exists in call to simulate_existing_file" if File.exist?(file)
  path = Pathname.new(File.join(destination_root, file))
  mkdir_p(path.dirname)
  File.open(path, "w+") do |f|
    f.puts(data) if data.present?
  end
end

# Simulate having an existing directory for cases where the generator needs to add a file to a directory
# that will definitely already exist
def simulate_existing_dir(dirname)
  path = File.join(destination_root, dirname)
  mkdir_p(path)
end

def assert_directory_with_keep_file(dir)
  assert_directory dir
  assert_file File.join(dir, ".keep")
end

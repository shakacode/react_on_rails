require File.expand_path("../../support/generator_spec_helper", __FILE__)

describe DevTestsGenerator, type: :generator do
  destination File.expand_path("../../dummy-for-generators/", __FILE__)

  before(:all) { run_generator_test_with_args(%w(), package_json: true, webpack_client_base_config: true) }

  it "copies rspec files" do
    %w(spec/spec_helper.rb
       spec/rails_helper.rb
       spec/simplecov_helper.rb
       .rspec).each { |file| assert_file(file) }
  end

  it "copies tests" do
    %w(spec/features/hello_world_spec.rb).each { |file| assert_file(file) }
  end

  it "changes package.json to use local react-on-rails version of module" do
    assert_file("client/package.json") do |contents|
      assert_match('"react-on-rails": "../../.."', contents)
      refute_match('"react-on-rails": "ReactOnRails::VERSION"', contents)
    end
  end

  it "adds test-related gems to Gemfile" do
    assert_file("Gemfile") do |contents|
      assert_match("gem 'rspec-rails', group: :test", contents)
      assert_match("gem 'capybara', group: :test", contents)
      assert_match("gem 'selenium-webdriver', group: :test", contents)
      assert_match("gem 'coveralls', require: false", contents)
      assert_match("gem 'poltergeist'", contents)
    end
  end

  it "changes the webpack.client.base.config.js to use a resolveLoader" do
    expected = <<-TEXT
  resolve: {
    ...
  },

  // This fixes an issue with resolving 'react' when using a local symlinked version
  // of the node_package folder
  resolveLoader: {
    fallback: [path.join(__dirname, 'node_modules')],
  },
  plugins: [
    ...
  ]
TEXT

    assert_file("client/webpack.client.base.config.js") do |contents|
      assert_match(expected, contents)
    end
  end
end

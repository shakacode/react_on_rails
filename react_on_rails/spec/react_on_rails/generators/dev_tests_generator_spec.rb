# frozen_string_literal: true

require File.expand_path("../support/generator_spec_helper", __dir__)

describe DevTestsGenerator, type: :generator do
  destination File.expand_path("../dummy-for-generators", __dir__)

  context "without server rendering" do
    before(:all) do
      run_generator_test_with_args(%w[],
                                   package_json: true,
                                   spec: false)
    end

    it "copies rspec files" do
      %w[spec/spec_helper.rb
         spec/rails_helper.rb
         spec/simplecov_helper.rb
         .rspec].each { |file| assert_file(file) }
    end

    it "copies tests" do
      %w[spec/system/hello_world_spec.rb].each { |file| assert_file(file) }
    end

    it "changes package.json to use local react-on-rails version of module" do
      assert_file("package.json") do |contents|
        expect(contents).to match('"react-on-rails"')
        expect(contents).to match('"postinstall"')
      end
    end

    it "adds test-related gems to Gemfile" do
      assert_file("Gemfile") do |contents|
        expect(contents).to match("gem \"rspec-rails\", group: :test")
        expect(contents).to match("gem \"coveralls\", require: false")
        # chromedriver-helper was removed as it's deprecated since 2019
        # Modern selenium-webdriver (4.x) handles driver management automatically
      end
    end
  end

  context "with server-rendering" do
    before(:all) do
      run_generator_test_with_args(%w[--example-server-rendering],
                                   package_json: true,
                                   spec: false,
                                   hello_world_file: true)
    end

    it "adds prerender for examples with example-server-rendering" do
      assert_file("app/views/hello_world/index.html.erb") do |contents|
        expect(contents).to match("prerender: true")
      end
    end
  end
end

require File.expand_path("../../support/generator_spec_helper", __FILE__)

describe DevTestsGenerator, type: :generator do
  destination File.expand_path("../../dummy-for-generators/", __FILE__)

  before(:all) { run_generator_test_with_args(%w()) }

  it "copies rspec files" do
    %w(spec/spec_helper.rb
       spec/rails_helper.rb
       spec/simplecov_helper.rb
       .rspec).each { |file| assert_file(file) }
  end

  it "copies tests" do
    %w(spec/features/hello_world_spec.rb).each { |file| assert_file(file) }
  end

  it "adds test-related gems to Gemfile" do
    assert_file("Gemfile") do |contents|
      assert_match("gem 'rspec-rails', group: :test", contents)
      assert_match("gem 'capybara', group: :test", contents)
      assert_match("gem 'selenium-webdriver', group: :test", contents)
      assert_match("gem 'coveralls', require: false", contents)
    end
  end
end

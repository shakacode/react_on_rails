require "spec_helper"

describe "Using Capybara::Screenshot with Test::Unit" do
  include CommonSetup

  before do
    clean_current_dir
  end

  def run_failing_case(code, integration_path = '.')
    write_file("#{integration_path}/test_failure.rb", <<-RUBY)
      #{ensure_load_paths_valid}
      require 'test/unit'
      require 'capybara'
      require 'capybara/rspec'
      require 'capybara-screenshot'
      require 'capybara-screenshot/testunit'

      #{setup_test_app}
      Capybara::Screenshot.register_filename_prefix_formatter(:testunit) do | fault |
        raise "expected fault" unless fault.exception.message.include? %q{Unable to find link or button "you'll never find me"}
        'my_screenshot'
      end

      class TestFailure < Test::Unit::TestCase
        include Capybara::DSL

        def test_failure
          #{code}
        end
      end
    RUBY

    cmd = "bundle exec ruby #{integration_path}/test_failure.rb"
    run_simple_with_retry cmd, false
    expect(output_from(cmd)).to include %q{Unable to find link or button "you'll never find me"}
  end

  it "saves a screenshot on failure for any test in path 'test/integration'" do
    run_failing_case <<-RUBY, 'test/integration'
      visit '/'
      assert(page.body.include?('This is the root page'))
      click_on "you'll never find me"
    RUBY
    check_file_content 'tmp/my_screenshot.html', 'This is the root page', true
  end

  it "does not generate a screenshot for tests that are not in 'test/integration'" do
    run_failing_case <<-RUBY, 'test/something-else'
      visit '/'
      assert(page.body.include?('This is the root page'))
      click_on "you'll never find me"
    RUBY

    check_file_presence(%w{tmp/my_screenshot.html}, false)
  end

  it 'saves a screenshot for the correct session for failures using_session' do
    run_failing_case <<-RUBY, 'test/integration'
      visit '/'
      assert(page.body.include?('This is the root page'))
      using_session :different_session do
        visit '/different_page'
        assert(page.body.include?('This is a different page'))
        click_on "you'll never find me"
      end
    RUBY
    check_file_content 'tmp/my_screenshot.html', 'This is a different page', true
  end

  it 'prunes screenshots on failure' do
    create_screenshot_for_pruning
    configure_prune_strategy :last_run
    run_failing_case <<-RUBY, 'test/integration'
      visit '/'
      assert(page.body.include?('This is the root page'))
      click_on "you'll never find me"
    RUBY
    assert_screenshot_pruned
  end
end

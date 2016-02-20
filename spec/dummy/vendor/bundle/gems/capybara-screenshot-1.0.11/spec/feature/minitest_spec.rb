require "spec_helper"

describe "Using Capybara::Screenshot with MiniTest" do
  include CommonSetup

  before do
    clean_current_dir
  end

  def run_failing_case(code)
    write_file('test_failure.rb', <<-RUBY)
      #{ensure_load_paths_valid}
      require 'minitest/autorun'
      require 'capybara'
      require 'capybara-screenshot'
      require 'capybara-screenshot/minitest'

      #{setup_test_app}
      Capybara::Screenshot.register_filename_prefix_formatter(:minitest) do |test_case|
        test_name = test_case.respond_to?(:name) ? test_case.name : test_case.__name__
        raise "expected fault" unless test_name.include? 'test_failure'
        'my_screenshot'
      end

      #{code}
    RUBY

    cmd = 'bundle exec ruby test_failure.rb'
    run_simple_with_retry cmd, false
    expect(output_from(cmd)).to include %q{Unable to find link or button "you'll never find me"}
  end

  it 'saves a screenshot on failure' do
    run_failing_case <<-RUBY
      module ActionDispatch
        class IntegrationTest < Minitest::Unit::TestCase; end
      end

      class TestFailure < ActionDispatch::IntegrationTest
        include Capybara::DSL

        def test_failure
          visit '/'
          assert(page.body.include?('This is the root page'))
          click_on "you'll never find me"
        end
      end
    RUBY
    check_file_content 'tmp/my_screenshot.html', 'This is the root page', true
  end

  it "does not save a screenshot for tests that don't inherit from ActionDispatch::IntegrationTest" do
    run_failing_case <<-RUBY
      class TestFailure < MiniTest::Unit::TestCase
        include Capybara::DSL

        def test_failure
          visit '/'
          assert(page.body.include?('This is the root page'))
          click_on "you'll never find me"
        end
      end
    RUBY
    check_file_presence(%w{tmp/my_screenshot.html}, false)
  end

  it 'saves a screenshot for the correct session for failures using_session' do
    run_failing_case <<-RUBY
      module ActionDispatch
        class IntegrationTest < Minitest::Unit::TestCase; end
      end

      class TestFailure < ActionDispatch::IntegrationTest
        include Capybara::DSL

        def test_failure
          visit '/'
          assert(page.body.include?('This is the root page'))
          using_session :different_session do
            visit '/different_page'
            assert(page.body.include?('This is a different page'))
            click_on "you'll never find me"
          end
        end
      end
    RUBY
    check_file_content 'tmp/my_screenshot.html', 'This is a different page', true
  end

  it 'prunes screenshots on failure' do
    create_screenshot_for_pruning
    configure_prune_strategy :last_run
    run_failing_case <<-RUBY
      module ActionDispatch
        class IntegrationTest < Minitest::Unit::TestCase; end
      end

      class TestFailure < ActionDispatch::IntegrationTest
        include Capybara::DSL

        def test_failure
          visit '/'
          assert(page.body.include?('This is the root page'))
          click_on "you'll never find me"
        end
      end
    RUBY
    assert_screenshot_pruned
  end
end

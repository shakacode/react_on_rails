require 'spec_helper'

describe Capybara::Screenshot::RSpec do
  describe "used with RSpec" do
    include CommonSetup

    before do
      clean_current_dir
    end

    def run_failing_case(code, error_message, format=nil)
      run_case code, format: format

      cmd = cmd_with_format(format)
      if error_message.kind_of?(Regexp)
        expect(output_from(cmd)).to match(error_message)
      else
        expect(output_from(cmd)).to include(error_message)
      end
    end

    def run_case(code, options = {})
      write_file('spec/test_failure.rb', <<-RUBY)
        #{ensure_load_paths_valid}
        require 'rspec'
        require 'capybara'
        require 'capybara/rspec'
        require 'capybara-screenshot'
        require 'capybara-screenshot/rspec'

        #{setup_test_app}
        #{code}
      RUBY

      cmd = cmd_with_format(options[:format])
      run_simple_with_retry cmd, false

      expect(output_from(cmd)).to include('0 failures') if options[:assert_all_passed]
    end

    def cmd_with_format(format)
      "bundle exec rspec #{"--format #{format} " if format}spec/test_failure.rb"
    end

    it 'saves a screenshot on failure' do
      run_failing_case <<-RUBY, %q{Unable to find link or button "you'll never find me"}
        feature 'screenshot with failure' do
          scenario 'click on a missing link' do
            visit '/'
            expect(page.body).to include('This is the root page')
            click_on "you'll never find me"
          end
        end
      RUBY
      check_file_content('tmp/screenshot.html', 'This is the root page', true)
    end

    formatters = {
      progress:      'HTML screenshot:',
      documentation: 'HTML screenshot:',
      html:          %r{<a href="file://\./tmp/screenshot\.html"[^>]*>HTML page</a>}
    }

    # Textmate formatter is only included in RSpec 2
    if RSpec::Core::Version::STRING.to_i == 2
      formatters[:textmate] = %r{TextMate\.system\(.*open file://\./tmp/screenshot.html}
    end

    formatters.each do |formatter, error_message|
      it "uses the associated #{formatter} formatter" do
        run_failing_case <<-RUBY, error_message, formatter
          feature 'screenshot with failure' do
            scenario 'click on a missing link' do
              visit '/'
              click_on "you'll never find me"
            end
          end
        RUBY
        check_file_content('tmp/screenshot.html', 'This is the root page', true)
      end
    end

    it "does not save a screenshot for tests that don't use Capybara" do
      run_failing_case <<-RUBY, %q{expected: false}
        describe 'failing test' do
          it 'fails intentionally' do
            expect(true).to eql(false)
          end
        end
      RUBY
      check_file_presence(%w{tmp/screenshot.html}, false)
    end

    it 'saves a screenshot for the correct session for failures using_session' do
      run_failing_case <<-RUBY, %q{Unable to find link or button "you'll never find me"}
        feature 'screenshot with failure' do
          scenario 'click on a missing link' do
            visit '/'
            expect(page.body).to include('This is the root page')
            using_session :different_session do
              visit '/different_page'
              expect(page.body).to include('This is a different page')
              click_on "you'll never find me"
            end
          end
        end
      RUBY
      check_file_content('tmp/screenshot.html', 'This is a different page', true)
    end

    context 'pruning' do
      before do
        create_screenshot_for_pruning
        configure_prune_strategy :last_run
      end

      it 'on failure it prunes previous screenshots when strategy is set' do
        run_failing_case <<-RUBY, 'HTML screenshot:', :progress
          feature 'screenshot with failure' do
            scenario 'click on a missing link' do
              visit '/'
              click_on "you'll never find me"
            end
          end
        RUBY
        assert_screenshot_pruned
      end

      it 'on success it never prunes' do
        run_case <<-CUCUMBER, assert_all_passed: true
          feature 'screenshot without failure' do
            scenario 'click on a link' do
              visit '/'
            end
          end
        CUCUMBER
        assert_screenshot_not_pruned
      end
    end

    context 'no pruning by default' do
      before do
        create_screenshot_for_pruning
      end

      it 'on failure it leaves existing screenshots' do
        run_failing_case <<-RUBY, 'HTML screenshot:', :progress
          feature 'screenshot with failure' do
            scenario 'click on a missing link' do
              visit '/'
              click_on "you'll never find me"
            end
          end
        RUBY
        assert_screenshot_not_pruned
      end
    end
  end
end

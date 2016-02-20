module CommonSetup
  def self.included(target)
    target.class_eval do
      include Aruba::Api
    end

    target.let(:gem_root) { File.expand_path('../..', File.dirname(__FILE__)) }

    target.let(:ensure_load_paths_valid) do
      <<-RUBY
        %w(lib spec).each do |include_folder|
          $LOAD_PATH.unshift(File.join('#{gem_root}', include_folder))
        end
      RUBY
    end

    target.let(:screenshot_path) { 'tmp' }
    target.let(:screenshot_for_pruning_path) { "#{screenshot_path}/old_screenshot.html" }

    target.let(:setup_test_app) do
      <<-RUBY
        require 'support/test_app'
        Capybara.save_and_open_page_path = '#{screenshot_path}'
        Capybara.app = TestApp
        Capybara::Screenshot.append_timestamp = false
        #{@additional_setup_steps}
      RUBY
    end

    target.before do
      if ENV['BUNDLE_GEMFILE'] && ENV['BUNDLE_GEMFILE'].match(/^\.|^[^\/\.]/)
        ENV['BUNDLE_GEMFILE'] = File.join(gem_root, ENV['BUNDLE_GEMFILE'])
      end
    end

    def run_simple_with_retry(*args)
      run_simple(*args)
    rescue ChildProcess::TimeoutError => e
      puts "run_simple(#{args.join(', ')}) failed. Will retry once. `#{e.message}`"
      run_simple(*args)
    end

    def configure_prune_strategy(strategy)
       @additional_setup_steps = "Capybara::Screenshot.prune_strategy = :keep_last_run"
    end

    def create_screenshot_for_pruning
      write_file screenshot_for_pruning_path, '<html></html>'
    end

    def assert_screenshot_pruned
      check_file_presence Array(screenshot_for_pruning_path), false
    end

    def assert_screenshot_not_pruned
      check_file_presence Array(screenshot_for_pruning_path), true
    end
  end
end

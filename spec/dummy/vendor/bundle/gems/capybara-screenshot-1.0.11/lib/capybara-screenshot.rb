module Capybara
  module Screenshot
    class << self
      attr_accessor :autosave_on_failure
      attr_accessor :registered_drivers
      attr_accessor :filename_prefix_formatters
      attr_accessor :append_timestamp
      attr_accessor :append_random
      attr_accessor :webkit_options
      attr_writer   :final_session_name
      attr_accessor :prune_strategy
    end

    self.autosave_on_failure = true
    self.registered_drivers = {}
    self.filename_prefix_formatters = {}
    self.append_timestamp = true
    self.append_random = false
    self.webkit_options = {}
    self.prune_strategy = :keep_all

    def self.append_screenshot_path=(value)
      $stderr.puts "WARNING: Capybara::Screenshot.append_screenshot_path is deprecated. " +
        "Please use Capybara::Screenshot::RSpec.add_link_to_screenshot_for_failed_examples instead."
      RSpec.add_link_to_screenshot_for_failed_examples = value
    end

    def self.screenshot_and_save_page
      saver = Saver.new(Capybara, Capybara.page)
      saver.save
      {:html => saver.html_path, :image => saver.screenshot_path}
    end

    def self.screenshot_and_open_image
      require "launchy"

      saver = Saver.new(Capybara, Capybara.page, false)
      saver.save
      Launchy.open saver.screenshot_path
      {:html => nil, :image => saver.screenshot_path}
    end

    class << self
      alias screen_shot_and_save_page screenshot_and_save_page
      alias screen_shot_and_open_image screenshot_and_open_image
    end

    def self.filename_prefix_for(test_type, test)
      filename_prefix_formatters.fetch(test_type) { |key|
        filename_prefix_formatters[:default]
      }.call(test)
    end

    def self.capybara_root
      @capybara_root ||= if defined?(::Rails)
        ::Rails.root.join capybara_tmp_path
      elsif defined?(Padrino)
        Padrino.root capybara_tmp_path
      elsif defined?(Sinatra)
        File.join(Sinatra::Application.root, capybara_tmp_path)
      else
        capybara_tmp_path
      end.to_s
    end

    def self.register_driver(driver, &block)
      self.registered_drivers[driver] = block
    end

    def self.register_filename_prefix_formatter(test_type, &block)
      self.filename_prefix_formatters[test_type] = block
    end

    def self.final_session_name
      @final_session_name || Capybara.session_name || :default
    end

    # Prune screenshots based on prune_strategy
    # Will run only once unless force:true
    def self.prune(options = {})
      reset_prune_history if options[:force]
      Capybara::Screenshot::Pruner.new(Capybara::Screenshot.prune_strategy).prune_old_screenshots unless @pruned_previous_screenshots
      @pruned_previous_screenshots = true
    end

    # Reset prune history allowing further prunining on next failure
    def self.reset_prune_history
      @pruned_previous_screenshots = nil
    end

    private

    # If the path isn't set, default to the current directory
    def self.capybara_tmp_path
      Capybara.save_and_open_page_path || '.'
    end
  end
end

# Register driver renderers.
# The block should return `:not_supported` if a screenshot could not be saved.
Capybara::Screenshot.class_eval do
  register_driver(:default) do |driver, path|
    driver.render(path)
  end

  register_driver(:rack_test) do |driver, path|
    :not_supported
  end

  register_driver(:mechanize) do |driver, path|
    :not_supported
  end

  register_driver(:selenium) do |driver, path|
    driver.browser.save_screenshot(path)
  end

  register_driver(:poltergeist) do |driver, path|
    driver.render(path, :full => true)
  end

  register_driver(:poltergeist_billy) do |driver, path|
    driver.render(path, :full => true)
  end

  webkit_block = proc do |driver, path|
    if driver.respond_to?(:save_screenshot)
      driver.save_screenshot(path, webkit_options)
    else
      driver.render(path)
    end
  end

  register_driver :webkit,       &webkit_block
  register_driver :webkit_debug, &webkit_block

  register_driver(:terminus) do |driver, path|
    if driver.respond_to?(:save_screenshot)
      driver.save_screenshot(path)
    else
      :not_supported
    end
  end
end

# Register filename prefix formatters
Capybara::Screenshot.class_eval do
  register_filename_prefix_formatter(:default) do |test|
    'screenshot'
  end
end

require 'capybara/dsl'
require 'capybara/util/save_and_open_page' if Capybara::VERSION.match(/^\d+/)[0] == '1' # no longer needed in Capybara version 2

require 'capybara-screenshot/saver'
require 'capybara-screenshot/capybara'
require 'capybara-screenshot/pruner'

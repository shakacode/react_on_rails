# frozen_string_literal: true

# This file supports 2 strategies:
# 1. switch_to_selenium: switch drivers
# 2. restart_poltergeist

RESTART_PHANTOMJS = ENV["RESTART_PHANTOMJS"] &&
                    %w[TRUE YES].include?(ENV["RESTART_PHANTOMJS"].upcase)
# puts "RESTART_PHANTOMJS = #{RESTART_PHANTOMJS}"

CAPYBARA_TIMEOUT_RETRIES = 3

# HACK: workaround for Capybara Poltergeist StatusFailErrors, simply retries
# based on https://gist.github.com/afn/c04ccfe71d648763b306
RSpec.configure do |config|
  config.around(:each, type: :feature) do |ex|
    example = RSpec.current_example
    use_selenium = false
    original_driver = Capybara.default_driver
    CAPYBARA_TIMEOUT_RETRIES.times do
      example.instance_variable_set("@exception", nil)

      # Private method in rspec:
      # rspec-core-3.5.4/lib/rspec/core/memoized_helpers.rb:139
      __init_memoized

      if use_selenium
        Capybara.current_driver = js_selenium_driver
        Capybara.javascript_driver = js_selenium_driver
        Capybara.default_driver = js_selenium_driver
        puts "Switched to #{js_selenium_driver} from #{Capybara.current_driver}"
      end

      ex.run

      example_ex = example.exception

      break unless example_ex

      is_multiple_exception = example_ex.is_a?(RSpec::Core::MultipleExceptionError)

      break unless example_ex.is_a?(Capybara::Poltergeist::StatusFailError) ||
                   example_ex.is_a?(Capybara::Poltergeist::DeadClient) ||
                   is_multiple_exception

      if is_multiple_exception
        m_exceptions = example_ex.all_exceptions

        idx = m_exceptions.find_index do |exception|
          exception.is_a?(Capybara::Poltergeist::StatusFailError) ||
            exception.is_a?(Capybara::Poltergeist::DeadClient) ||
            exception.class < SystemCallError
        end

        break unless idx
      end

      puts "\n"
      puts "=" * 80
      puts "Exception caught! #{example_ex}"
      puts example_ex.message
      puts "when running example:\n  #{example.full_description}"
      puts "  at #{example.location} with driver #{Capybara.current_driver}."

      if RESTART_PHANTOMJS
        PhantomJSRestart.call
      else
        use_selenium = true
      end
      puts "=" * 80
    end
    Capybara.current_driver = original_driver
    Capybara.javascript_driver = original_driver
    Capybara.default_driver = original_driver
    Capybara.use_default_driver
  end
end

# Rather than using switching to use selenium, we could have restarted Phantomjs
module PhantomJSRestart
  def self.call
    puts "Restarting phantomjs: iterating through capybara sessions..."
    session_pool = Capybara.send("session_pool")
    session_pool.each do |mode, session|
      msg = "  => #{mode} -- "
      driver = session.driver
      if driver.is_a?(Capybara::Poltergeist::Driver)
        msg += "restarting"
        driver.restart
      else
        msg += "not poltergeist: #{driver.class}"
      end
      puts msg
    end
  end
end

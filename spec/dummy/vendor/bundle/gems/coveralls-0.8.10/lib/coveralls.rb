require "coveralls/version"
require "coveralls/configuration"
require "coveralls/api"
require "coveralls/output"
require "coveralls/simplecov"

module Coveralls
  extend self

  class NilFormatter
    def format(result)
    end
  end

  attr_accessor :testing, :noisy, :run_locally

  def wear!(simplecov_setting=nil, &block)
    setup!
    start! simplecov_setting, &block
  end

  def wear_merged!(simplecov_setting=nil, &block)
    require 'simplecov'
    @@adapter = :simplecov
    ::SimpleCov.formatter = NilFormatter
    start! simplecov_setting, &block
  end

  def push!
    require 'simplecov'
    result = ::SimpleCov::ResultMerger.merged_result
    Coveralls::SimpleCov::Formatter.new.format result
  end

  def setup!
    # Try to load up SimpleCov.
    @@adapter = nil
    if defined?(::SimpleCov)
      @@adapter = :simplecov
    else
      begin
        require 'simplecov'
        @@adapter = :simplecov if defined?(::SimpleCov)
      rescue
      end
    end

    # Load the appropriate adapter.
    if @@adapter == :simplecov
      ::SimpleCov.formatter = Coveralls::SimpleCov::Formatter
      Coveralls::Output.puts("[Coveralls] Set up the SimpleCov formatter.", :color => "green")
    else
      Coveralls::Output.puts("[Coveralls] Couldn't find an appropriate adapter.", :color => "red")
    end

  end

  def start!(simplecov_setting = 'test_frameworks', &block)
    if @@adapter == :simplecov
      ::SimpleCov.add_filter 'vendor'

      if simplecov_setting
        Coveralls::Output.puts("[Coveralls] Using SimpleCov's '#{simplecov_setting}' settings.", :color => "green")
        if block_given?
          ::SimpleCov.start(simplecov_setting) { instance_eval(&block)}
        else
          ::SimpleCov.start(simplecov_setting)
        end
      elsif block
        Coveralls::Output.puts("[Coveralls] Using SimpleCov settings defined in block.", :color => "green")
        ::SimpleCov.start { instance_eval(&block) }
      else
        Coveralls::Output.puts("[Coveralls] Using SimpleCov's default settings.", :color => "green")
        ::SimpleCov.start
      end
    end
  end

  def should_run?
    # Fail early if we're not on a CI
    unless will_run?
      Coveralls::Output.puts("[Coveralls] Outside the CI environment, not sending data.", :color => "yellow")
      return false
    end

    if ENV["COVERALLS_RUN_LOCALLY"] || (defined?(@run_locally) && @run_locally)
      Coveralls::Output.puts("[Coveralls] Creating a new job on Coveralls from local coverage results.", :color => "cyan")
    end

    true
  end

  def will_run?
    ENV["CI"] || ENV["JENKINS_URL"] || ENV['TDDIUM'] ||
      ENV["COVERALLS_RUN_LOCALLY"] || (defined?(@testing) && @testing)
  end

  def noisy?
    ENV["COVERALLS_NOISY"] || (defined?(@noisy) && @noisy)
  end
end

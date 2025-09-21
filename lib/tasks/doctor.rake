# frozen_string_literal: true

require_relative "../react_on_rails"
require_relative "../react_on_rails/doctor"

begin
  require "rainbow"
rescue LoadError
  # Fallback if Rainbow is not available
  class Rainbow
    def self.method_missing(_method, text)
      SimpleColorWrapper.new(text)
    end

    def self.respond_to_missing?(_method, _include_private = false)
      true
    end
  end

  class SimpleColorWrapper
    def initialize(text)
      @text = text
    end

    def method_missing(_method, *_args)
      self
    end

    def respond_to_missing?(_method, _include_private = false)
      true
    end

    def to_s
      @text
    end
  end
end

namespace :react_on_rails do
  desc "Diagnose React on Rails setup and configuration"
  task :doctor do
    verbose = ENV["VERBOSE"] == "true"
    fix = ENV["FIX"] == "true"

    doctor = ReactOnRails::Doctor.new(verbose: verbose, fix: fix)
    doctor.run_diagnosis
  end
end

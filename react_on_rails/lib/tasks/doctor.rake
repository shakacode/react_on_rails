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
  rsc_doctor_checks = ["react_server_components"].freeze
  # Shared by both tasks so ENV option parsing and Doctor initialization stay identical.
  doctor_options = lambda do |only: nil|
    verbose = ENV["VERBOSE"] == "true"
    fix = ENV["FIX"] == "true"
    # Pass unknown values through so Doctor#initialize fails fast with
    # ArgumentError instead of silently falling back to text output.
    format = ENV["FORMAT"].to_s.empty? ? :text : ENV["FORMAT"].to_sym
    selected_checks = only || ENV["ONLY"].to_s.split(/[,\s]+/).reject(&:empty?)
    options = { verbose:, fix:, format: }
    options[:only] = selected_checks unless selected_checks.empty?
    options
  end

  desc "Diagnose React on Rails setup and configuration (FORMAT=json for machine-readable output)"
  task :doctor do
    doctor = ReactOnRails::Doctor.new(**doctor_options.call)
    doctor.run_diagnosis
  end

  namespace :doctor do
    desc "Diagnose only React Server Components setup (FORMAT=json for machine-readable output)"
    task :rsc do
      doctor = ReactOnRails::Doctor.new(**doctor_options.call(only: rsc_doctor_checks))
      doctor.run_diagnosis
    end
  end
end

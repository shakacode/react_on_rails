require 'rspec/expectations'

Minitest::Test.class_eval do
  include ::RSpec::Matchers

  def expect(*a, &b)
    assert(true) # so each expectation gets counted in minitest's assertion stats
    super
  end

  # Convert a `MultipleExpectationsNotMetError` to a `Minitest::Assertion` error so
  # it gets counted in minitest's summary stats as a failure rather than an error.
  # It would be nice to make `MultipleExpectationsNotMetError` subclass
  # `Minitest::Assertion`, but Minitest's implementation does not treat subclasses
  # the same, so this is the best we can do.
  def aggregate_failures(*args, &block)
    super
  rescue RSpec::Expectations::MultipleExpectationsNotMetError => e
    assertion_failed = Minitest::Assertion.new(e.message)
    assertion_failed.set_backtrace e.backtrace
    raise assertion_failed
  end
end

module RSpec
  module Expectations
    remove_const :ExpectationNotMetError
    # Exception raised when an expectation fails.
    ExpectationNotMetError = ::Minitest::Assertion
  end
end

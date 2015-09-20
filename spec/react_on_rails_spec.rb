require "coveralls"
Coveralls.wear!("rails") # must occur before any of your application code is required
require "spec_helper"

describe ReactOnRails do
  it "has a version number" do
    expect(ReactOnRails::VERSION).not_to be nil
  end
end

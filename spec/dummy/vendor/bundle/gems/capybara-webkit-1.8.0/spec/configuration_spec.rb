require "spec_helper"

describe Capybara::Webkit::Configuration do
  it "returns a hash and then prevents future modification" do
    Capybara::Webkit.configure do |config|
      config.debug = true
    end

    result = Capybara::Webkit::Configuration.to_hash

    expect(result).to include(debug: true)
    expect { Capybara::Webkit.configure {} }.to raise_error(
      "All configuration must take place before the driver starts"
    )
  end
end

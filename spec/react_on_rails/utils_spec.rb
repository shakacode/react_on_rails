require_relative "spec_helper"
require_relative "../../lib/react_on_rails/utils"

describe ReactOnRails::Utils do
  it "detect running OS" do
    %w(cygwin mswin mingw bccwin wince emx).each do |platform|
      RUBY_PLATFORM = platform
      ReactOnRails::Utils.running_on_windows?.should == true
    end
  end
end

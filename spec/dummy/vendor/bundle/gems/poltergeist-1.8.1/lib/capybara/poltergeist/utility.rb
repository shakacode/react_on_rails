module Capybara
  module Poltergeist
    class << self
      def windows?
        RbConfig::CONFIG["host_os"] =~ /mingw|mswin|cygwin/
      end
    end
  end
end
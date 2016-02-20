module Capybara::Poltergeist
  class Inspector
    BROWSERS     = %w(chromium chromium-browser google-chrome open)
    DEFAULT_PORT = 9664

    def self.detect_browser
      @browser ||= BROWSERS.find { |name| browser_binary_exists?(name) }
    end

    attr_reader :port

    def initialize(browser = nil, port = DEFAULT_PORT)
      @browser = browser.respond_to?(:to_str) ? browser : nil
      @port    = port
    end

    def browser
      @browser ||= self.class.detect_browser
    end

    def url(scheme)
      "#{scheme}://localhost:#{port}/"
    end

    def open(scheme)
      if browser
        Process.spawn(browser, url(scheme))
      else
        raise Error, "Could not find a browser executable to open #{url(scheme)}. " \
                     "You can specify one manually using e.g. `:inspector => 'chromium'` " \
                     "as a configuration option for Poltergeist."
      end
    end

    def self.browser_binary_exists?(browser)
      exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each { |ext|
          exe = "#{path}#{File::SEPARATOR}#{browser}#{ext}"
          return exe if File.executable? exe
        }
      end
      return nil
    end
  end
end

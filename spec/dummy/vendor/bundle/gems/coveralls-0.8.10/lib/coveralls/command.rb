require "thor"

module Coveralls
  class CommandLine < Thor

    desc "push", "Runs your test suite and pushes the coverage results to Coveralls."
    def push
      return unless ensure_can_run_locally!
      ENV["COVERALLS_RUN_LOCALLY"] = "true"
      cmd = "bundle exec rake"
      if File.exist?('.travis.yml')
        cmd = YAML.load_file('.travis.yml')["script"] || cmd rescue cmd
      end
      exec cmd
      ENV["COVERALLS_RUN_LOCALLY"] = nil
    end

    desc "report", "Runs your test suite locally and displays coverage statistics."
    def report
      ENV["COVERALLS_NOISY"] = "true"
      exec "bundle exec rake"
      ENV["COVERALLS_NOISY"] = nil
    end

    desc "open", "View this repository on Coveralls."
    def open
      open_token_based_url "https://coveralls.io/repos/%@"
    end

    desc "service", "View this repository on your CI service's website."
    def service
      open_token_based_url "https://coveralls.io/repos/%@/service"
    end

    desc "last", "View the last build for this repository on Coveralls."
    def last
      open_token_based_url "https://coveralls.io/repos/%@/last_build"
    end

    desc "version", "See version"
    def version
      Coveralls::Output.puts Coveralls::VERSION
    end

    private

    def open_token_based_url url
      config = Coveralls::Configuration.configuration
      if config[:repo_token]
        url = url.gsub("%@", config[:repo_token])
        `open #{url}`
      else
        Coveralls::Output.puts "No repo_token configured."
      end
    end

    def ensure_can_run_locally!
      config = Coveralls::Configuration.configuration
      if config[:repo_token].nil?
        Coveralls::Output.puts "Coveralls cannot run locally because no repo_secret_token is set in .coveralls.yml", :color => "red"
        Coveralls::Output.puts "Please try again when you get your act together.", :color => "red"

        return false
      end
      true
    end

  end
end

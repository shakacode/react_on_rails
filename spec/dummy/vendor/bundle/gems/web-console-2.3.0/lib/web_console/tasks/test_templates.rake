namespace :test do
  desc "Run tests for templates"
  task templates: "templates:all"

  namespace :templates do
    task all: [ :daemonize, :npm, :rackup, :wait, :mocha, :kill, :exit ]
    task serve: [ :npm, :rackup ]

    work_dir    = Pathname(EXPANDED_CWD).join("test/templates")
    pid_file    = Pathname(Dir.tmpdir).join("web_console.#{SecureRandom.uuid}.pid")
    runner_uri  = URI.parse("http://localhost:29292/html/spec_runner.html")
    rackup_opts = "-p #{runner_uri.port}"
    test_result = nil

    def need_to_wait?(uri)
      Net::HTTP.start(uri.host, uri.port) { |http| http.get(uri.path) }
    rescue Errno::ECONNREFUSED
      retry if yield
    end

    task :daemonize do
      rackup_opts += " -D -P #{pid_file}"
    end

    task :npm do
      Dir.chdir(work_dir) { system "npm install --silent" }
    end

    task :rackup do
      Dir.chdir(work_dir) { system "bundle exec rackup #{rackup_opts}" }
    end

    task :wait do
      cnt = 0
      need_to_wait?(runner_uri) { sleep 1; cnt += 1; cnt < 5 }
    end

    task :mocha do
      Dir.chdir(work_dir) { test_result = system("$(npm bin)/mocha-phantomjs #{runner_uri}") }
    end

    task :kill do
      system "kill #{File.read pid_file}"
    end

    task :exit do
      exit test_result
    end
  end
end

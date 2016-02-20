require "spring/boot"
require "set"
require "pty"

module Spring
  class Application
    attr_reader :manager, :watcher, :spring_env, :original_env

    def initialize(manager, original_env)
      @manager      = manager
      @original_env = original_env
      @spring_env   = Env.new
      @mutex        = Mutex.new
      @waiting      = Set.new
      @preloaded    = false
      @state        = :initialized
      @interrupt    = IO.pipe
    end

    def state(val)
      return if exiting?
      log "#{@state} -> #{val}"
      @state = val
    end

    def state!(val)
      state val
      @interrupt.last.write "."
    end

    def app_env
      ENV['RAILS_ENV']
    end

    def app_name
      spring_env.app_name
    end

    def log(message)
      spring_env.log "[application:#{app_env}] #{message}"
    end

    def preloaded?
      @preloaded
    end

    def preload_failed?
      @preloaded == :failure
    end

    def exiting?
      @state == :exiting
    end

    def terminating?
      @state == :terminating
    end

    def watcher_stale?
      @state == :watcher_stale
    end

    def initialized?
      @state == :initialized
    end

    def start_watcher
      @watcher = Spring.watcher
      @watcher.on_stale { state! :watcher_stale }
      @watcher.start
    end

    def preload
      log "preloading app"

      begin
        require "spring/commands"
      ensure
        start_watcher
      end

      require Spring.application_root_path.join("config", "application")

      # config/environments/test.rb will have config.cache_classes = true. However
      # we want it to be false so that we can reload files. This is a hack to
      # override the effect of config.cache_classes = true. We can then actually
      # set config.cache_classes = false after loading the environment.
      Rails::Application.initializer :initialize_dependency_mechanism, group: :all do
        ActiveSupport::Dependencies.mechanism = :load
      end

      require Spring.application_root_path.join("config", "environment")

      @original_cache_classes = Rails.application.config.cache_classes
      Rails.application.config.cache_classes = false

      disconnect_database

      @preloaded = :success
    rescue Exception => e
      @preloaded = :failure
      watcher.add e.backtrace.map { |line| line[/^(.*)\:\d+/, 1] }
      raise e unless initialized?
    ensure
      watcher.add loaded_application_features
      watcher.add Spring.gemfile, "#{Spring.gemfile}.lock"

      if defined?(Rails) && Rails.application
        watcher.add Rails.application.paths["config/initializers"]
        watcher.add Rails.application.paths["config/database"]
        if secrets_path = Rails.application.paths["config/secrets"]
          watcher.add secrets_path
        end
      end
    end

    def eager_preload
      with_pty { preload }
    end

    def run
      state :running
      manager.puts

      loop do
        IO.select [manager, @interrupt.first]

        if terminating? || watcher_stale? || preload_failed?
          exit
        else
          serve manager.recv_io(UNIXSocket)
        end
      end
    end

    def serve(client)
      log "got client"
      manager.puts

      stdout, stderr, stdin = streams = 3.times.map { client.recv_io }
      [STDOUT, STDERR, STDIN].zip(streams).each { |a, b| a.reopen(b) }

      preload unless preloaded?

      args, env = JSON.load(client.read(client.gets.to_i)).values_at("args", "env")
      command   = Spring.command(args.shift)

      connect_database
      setup command

      if Rails.application.reloaders.any?(&:updated?)
        ActionDispatch::Reloader.cleanup!
        ActionDispatch::Reloader.prepare!
      end

      pid = fork {
        IGNORE_SIGNALS.each { |sig| trap(sig, "DEFAULT") }
        trap("TERM", "DEFAULT")

        STDERR.puts "Running via Spring preloader in process #{Process.pid}" unless Spring.quiet

        ARGV.replace(args)
        $0 = command.exec_name

        # Delete all env vars which are unchanged from before spring started
        original_env.each { |k, v| ENV.delete k if ENV[k] == v }

        # Load in the current env vars, except those which *were* changed when spring started
        env.each { |k, v| ENV[k] ||= v }

        # requiring is faster, so if config.cache_classes was true in
        # the environment's config file, then we can respect that from
        # here on as we no longer need constant reloading.
        if @original_cache_classes
          ActiveSupport::Dependencies.mechanism = :require
          Rails.application.config.cache_classes = true
        end

        connect_database
        srand

        invoke_after_fork_callbacks
        shush_backtraces

        command.call
      }

      disconnect_database
      reset_streams

      log "forked #{pid}"
      manager.puts pid

      wait pid, streams, client
    rescue Exception => e
      log "exception: #{e}"
      manager.puts unless pid

      if streams && !e.is_a?(SystemExit)
        print_exception(stderr, e)
        streams.each(&:close)
      end

      client.puts(1) if pid
      client.close
    end

    def terminate
      if exiting?
        # Ensure that we do not ignore subsequent termination attempts
        log "forced exit"
        @waiting.each { |pid| Process.kill("TERM", pid) }
        Kernel.exit
      else
        state! :terminating
      end
    end

    def exit
      state :exiting
      manager.shutdown(:RDWR)
      exit_if_finished
      sleep
    end

    def exit_if_finished
      @mutex.synchronize {
        Kernel.exit if exiting? && @waiting.empty?
      }
    end

    # The command might need to require some files in the
    # main process so that they are cached. For example a test command wants to
    # load the helper file once and have it cached.
    def setup(command)
      if command.setup
        watcher.add loaded_application_features # loaded features may have changed
      end
    end

    def invoke_after_fork_callbacks
      Spring.after_fork_callbacks.each do |callback|
        callback.call
      end
    end

    def loaded_application_features
      root = Spring.application_root_path.to_s
      $LOADED_FEATURES.select { |f| f.start_with?(root) }
    end

    def disconnect_database
      ActiveRecord::Base.remove_connection if active_record_configured?
    end

    def connect_database
      ActiveRecord::Base.establish_connection if active_record_configured?
    end

    # This feels very naughty
    def shush_backtraces
      Kernel.module_eval do
        old_raise = Kernel.method(:raise)
        remove_method :raise
        define_method :raise do |*args|
          begin
            old_raise.call(*args)
          ensure
            if $!
              lib = File.expand_path("..", __FILE__)
              $!.backtrace.reject! { |line| line.start_with?(lib) }
            end
          end
        end
        private :raise
      end
    end

    def print_exception(stream, error)
      first, rest = error.backtrace.first, error.backtrace.drop(1)
      stream.puts("#{first}: #{error} (#{error.class})")
      rest.each { |line| stream.puts("\tfrom #{line}") }
    end

    def with_pty
      PTY.open do |master, slave|
        [STDOUT, STDERR, STDIN].each { |s| s.reopen slave }
        Thread.new { master.read }
        yield
        reset_streams
      end
    end

    def reset_streams
      [STDOUT, STDERR].each { |stream| stream.reopen(spring_env.log_file) }
      STDIN.reopen("/dev/null")
    end

    def wait(pid, streams, client)
      @mutex.synchronize { @waiting << pid }

      # Wait in a separate thread so we can run multiple commands at once
      Thread.new {
        begin
          _, status = Process.wait2 pid
          log "#{pid} exited with #{status.exitstatus}"

          streams.each(&:close)
          client.puts(status.exitstatus)
          client.close
        ensure
          @mutex.synchronize { @waiting.delete pid }
          exit_if_finished
        end
      }
    end

    private

    def active_record_configured?
      defined?(ActiveRecord::Base) && ActiveRecord::Base.configurations.any?
    end
  end
end

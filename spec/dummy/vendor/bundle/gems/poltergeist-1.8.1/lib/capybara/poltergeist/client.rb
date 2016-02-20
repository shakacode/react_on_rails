require "timeout"
require "capybara/poltergeist/utility"
require 'cliver'

module Capybara::Poltergeist
  class Client
    PHANTOMJS_SCRIPT  = File.expand_path('../client/compiled/main.js', __FILE__)
    PHANTOMJS_VERSION = ['>= 1.8.1', '< 3.0']
    PHANTOMJS_NAME    = 'phantomjs'

    KILL_TIMEOUT = 2 # seconds

    def self.start(*args)
      client = new(*args)
      client.start
      client
    end

    # Returns a proc, that when called will attempt to kill the given process.
    # This is because implementing ObjectSpace.define_finalizer is tricky.
    # Hat-Tip to @mperham for describing in detail:
    # http://www.mikeperham.com/2010/02/24/the-trouble-with-ruby-finalizers/
    def self.process_killer(pid)
      proc do
        begin
          Process.kill('KILL', pid)
        rescue Errno::ESRCH, Errno::ECHILD
        end
      end
    end

    attr_reader :pid, :server, :path, :window_size, :phantomjs_options

    def initialize(server, options = {})
      @server            = server
      @path              = Cliver::detect!((options[:path] || PHANTOMJS_NAME),
                                           *PHANTOMJS_VERSION)

      @window_size       = options[:window_size]       || [1024, 768]
      @phantomjs_options = options[:phantomjs_options] || []
      @phantomjs_logger  = options[:phantomjs_logger]  || $stdout

      pid = Process.pid
      at_exit do
        # do the work in a separate thread, to avoid stomping on $!,
        # since other libraries depend on it directly.
        Thread.new do
          stop if Process.pid == pid
        end.join
      end
    end

    def start
      @read_io, @write_io = IO.pipe
      @out_thread = Thread.new {
        while !@read_io.eof? && data = @read_io.readpartial(1024)
          @phantomjs_logger.write(data)
        end
      }

      process_options = {}
      process_options[:pgroup] = true unless Capybara::Poltergeist.windows?

      redirect_stdout do
        @pid = Process.spawn(*command.map(&:to_s), process_options)
        ObjectSpace.define_finalizer(self, self.class.process_killer(@pid))
      end
    end

    def stop
      if pid
        kill_phantomjs
        @out_thread.kill
        close_io
        ObjectSpace.undefine_finalizer(self)
      end
    end

    def restart
      stop
      start
    end

    def command
      parts = [path]
      parts.concat phantomjs_options
      parts << PHANTOMJS_SCRIPT
      parts << server.port
      parts.concat window_size
      parts
    end

    private

    # This abomination is because JRuby doesn't support the :out option of
    # Process.spawn. To be honest it works pretty bad with pipes too, because
    # we ought close writing end in parent process immediately but JRuby will
    # lose all the output from child. Process.popen can be used here and seems
    # it works with JRuby but I've experienced strange mistakes on Rubinius.
    def redirect_stdout
      prev = STDOUT.dup
      $stdout = @write_io
      STDOUT.reopen(@write_io)
      yield
    ensure
      STDOUT.reopen(prev)
      $stdout = STDOUT
      prev.close
    end

    def kill_phantomjs
      begin
        if Capybara::Poltergeist.windows?
          Process.kill('KILL', pid)
        else
          Process.kill('TERM', pid)
          begin
            Timeout.timeout(KILL_TIMEOUT) { Process.wait(pid) }
          rescue Timeout::Error
            Process.kill('KILL', pid)
            Process.wait(pid)
          end
        end
      rescue Errno::ESRCH, Errno::ECHILD
        # Zed's dead, baby
      end
      @pid = nil
    end

    # We grab all the output from PhantomJS like console.log in another thread
    # and when PhantomJS crashes we try to restart it. In order to do it we stop
    # server and client and on JRuby see this error `IOError: Stream closed`.
    # It happens because JRuby tries to close pipe and it is blocked on `eof?`
    # or `readpartial` call. The error is raised in the related thread and it's
    # not actually main thread but the thread that listens to the output. That's
    # why if you put some debug code after `rescue IOError` it won't be shown.
    # In fact the main thread will continue working after the error even if we
    # don't use `rescue`. The first attempt to fix it was a try not to block on
    # IO, but looks like similar issue appers after JRuby upgrade. Perhaps the
    # only way to fix it is catching the exception what this method overall does.
    def close_io
      [@write_io, @read_io].each do |io|
        begin
          io.close unless io.closed?
        rescue IOError
          raise unless RUBY_ENGINE == 'jruby'
        end
      end
    end
  end
end

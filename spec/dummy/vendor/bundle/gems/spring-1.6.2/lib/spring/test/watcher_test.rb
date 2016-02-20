require "tmpdir"
require "fileutils"
require "timeout"
require "active_support/core_ext/numeric/time"

module Spring
  module Test
    class WatcherTest < ActiveSupport::TestCase
      runnables.delete self # prevent Minitest running this class

      LATENCY = 0.001
      TIMEOUT = 1

      attr_accessor :dir

      def watcher_class
        raise NotImplementedError
      end

      def watcher
        @watcher ||= watcher_class.new(dir, LATENCY)
      end

      def setup
        @dir = File.realpath(Dir.mktmpdir)
      end

      def teardown
        FileUtils.remove_entry_secure @dir
        watcher.stop
      end

      def touch(file, mtime = nil)
        options = {}
        options[:mtime] = mtime if mtime
        FileUtils.touch(file, options)
      end

      def assert_stale
        timeout = Time.now + TIMEOUT
        sleep LATENCY until watcher.stale? || Time.now > timeout
        assert watcher.stale?
      end

      def assert_not_stale
        sleep LATENCY * 10
        assert !watcher.stale?
      end

      test "starting with no file" do
        file = "#{@dir}/omg"
        touch file, Time.now - 2.seconds

        watcher.start
        watcher.add file

        assert_not_stale
        touch file, Time.now
        assert_stale
      end

      test "is stale when a watched file is updated" do
        file = "#{@dir}/omg"
        touch file, Time.now - 2.seconds

        watcher.add file
        watcher.start

        assert_not_stale
        touch file, Time.now
        assert_stale
      end

      test "is stale when removing files" do
        file = "#{@dir}/omg"
        touch file, Time.now

        watcher.add file
        watcher.start

        assert_not_stale
        FileUtils.rm(file)
        assert_stale
      end

      test "is stale when files are added to a watched directory" do
        subdir = "#{@dir}/subdir"
        FileUtils.mkdir(subdir)

        watcher.add subdir
        watcher.start

        assert_not_stale
        touch "#{subdir}/foo", Time.now - 1.minute
        assert_stale
      end

      test "is stale when a file is changed in a watched directory" do
        subdir = "#{@dir}/subdir"
        FileUtils.mkdir(subdir)
        touch "#{subdir}/foo", Time.now - 1.minute

        watcher.add subdir
        watcher.start

        assert_not_stale
        touch "#{subdir}/foo", Time.now
        assert_stale
      end

      test "adding doesn't wipe stale state" do
        file = "#{@dir}/omg"
        file2 = "#{@dir}/foo"
        touch file, Time.now - 2.seconds
        touch file2, Time.now - 2.seconds

        watcher.add file
        watcher.start

        assert_not_stale

        touch file, Time.now
        watcher.add file2

        assert_stale
      end

      test "on stale" do
        file = "#{@dir}/omg"
        touch file, Time.now - 2.seconds

        stale = false
        watcher.on_stale { stale = true }

        watcher.add file
        watcher.start

        touch file, Time.now

        Timeout.timeout(1) { sleep 0.01 until stale }
        assert stale

        # Check that we only get notified once
        stale = false
        sleep LATENCY * 3
        assert !stale
      end

      test "add relative path" do
        File.write("#{dir}/foo", "foo")
        watcher.add "foo"
        assert_equal ["#{dir}/foo"], watcher.files.to_a
      end

      test "add dot relative path" do
        File.write("#{dir}/foo", "foo")
        watcher.add "./foo"
        assert_equal ["#{dir}/foo"], watcher.files.to_a
      end

      test "add non existent file" do
        watcher.add './foobar'
        assert watcher.files.empty?
      end
    end
  end
end

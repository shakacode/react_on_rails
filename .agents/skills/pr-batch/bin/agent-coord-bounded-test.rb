#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "minitest/autorun"
require "open3"
require "rbconfig"
require "tmpdir"

SCRIPT = File.expand_path("agent-coord-bounded", __dir__)

class AgentCoordBoundedTest < Minitest::Test # rubocop:disable Metrics/ClassLength
  def test_forwards_agent_coord_exit_status_stdout_and_stderr
    with_fake_agent_coord(<<~RUBY) do |env|
      $stderr.print "fake stderr"
      puts "fake stdout"
      exit 7
    RUBY
      stdout, stderr, status = run_script(env, "status", "--repo", "shakacode/react_on_rails")

      assert_equal 7, status.exitstatus
      assert_equal "fake stdout\n", stdout
      assert_equal "fake stderr", stderr
    end
  end

  def test_times_out_and_reports_unknown_friendly_status
    with_fake_agent_coord(<<~RUBY) do |env|
      puts "partial json output"
      $stdout.flush
      sleep 5
    RUBY
      stdout, stderr, status = run_script(env, "--timeout", "0.2", "doctor", "--json")

      assert_equal 124, status.exitstatus
      assert_empty stdout
      assert_includes stderr, "agent-coord-bounded: timed out after 0.2s"
      assert_includes stderr, "agent-coord doctor --json"
    end
  end

  def test_requires_agent_coord_arguments
    stdout, stderr, status = run_script({}, "--timeout", "1")

    assert_equal 64, status.exitstatus
    assert_empty stdout
    assert_includes stderr, "Usage: agent-coord-bounded"
  end

  def test_rejects_non_finite_timeout
    stdout, stderr, status = run_script({}, "--timeout", "1e999", "status")

    assert_equal 64, status.exitstatus
    assert_empty stdout
    assert_includes stderr, "--timeout must be a positive finite number"
  end

  def test_rejects_zero_timeout
    stdout, stderr, status = run_script({}, "--timeout", "0", "status")

    assert_equal 64, status.exitstatus
    assert_empty stdout
    assert_includes stderr, "--timeout must be a positive finite number"
  end

  def test_rejects_negative_timeout
    stdout, stderr, status = run_script({}, "--timeout", "-1", "status")

    assert_equal 64, status.exitstatus
    assert_empty stdout
    assert_includes stderr, "--timeout must be a positive finite number"
  end

  def test_rejects_invalid_default_timeout_without_backtrace
    env = { "AGENT_COORD_BOUNDED_TIMEOUT_SECONDS" => "not-a-number" }
    stdout, stderr, status = run_script(env, "status")

    assert_equal 64, status.exitstatus
    assert_empty stdout
    assert_includes stderr, "AGENT_COORD_BOUNDED_TIMEOUT_SECONDS must be a positive finite number"
    refute_includes stderr, "\n\tfrom "
  end

  def test_timeout_option_overrides_invalid_default_timeout
    with_fake_agent_coord(<<~RUBY, "AGENT_COORD_BOUNDED_TIMEOUT_SECONDS" => "not-a-number") do |env|
      puts "ok"
    RUBY
      stdout, stderr, status = run_script(env, "--timeout", "1", "status")

      assert_predicate status, :success?
      assert_equal "ok\n", stdout
      assert_empty stderr
    end
  end

  def test_help_does_not_parse_invalid_default_timeout
    stdout, stderr, status = run_script({ "AGENT_COORD_BOUNDED_TIMEOUT_SECONDS" => "not-a-number" }, "--help")

    assert_predicate status, :success?
    assert_includes stdout, "Usage: agent-coord-bounded"
    assert_empty stderr
  end

  def test_reports_missing_agent_coord_without_backtrace
    Dir.mktmpdir("agent-coord-bounded-test") do |dir|
      stdout, stderr, status = run_script({ "PATH" => dir }, "status", "--repo", "shakacode/react_on_rails")

      assert_equal 127, status.exitstatus
      assert_empty stdout
      assert_includes stderr, "agent-coord-bounded: unable to start"
      assert_includes stderr, "agent-coord status --repo shakacode/react_on_rails"
      refute_includes stderr, "\n\tfrom "
    end
  end

  def test_terminates_agent_coord_process_group_when_interrupted
    Dir.mktmpdir("agent-coord-bounded-test") do |dir|
      child_pid_file = File.join(dir, "child.pid")
      wrapper_pid = nil
      child_pid = nil

      with_fake_agent_coord(<<~RUBY, "AGENT_COORD_CHILD_PID" => child_pid_file) do |env|
        File.write(ENV.fetch("AGENT_COORD_CHILD_PID"), Process.pid.to_s)
        sleep 10
      RUBY
        wrapper_pid = Process.spawn(env, RbConfig.ruby, SCRIPT, "--timeout", "20", "status",
                                    out: File::NULL, err: File::NULL)

        assert wait_until(timeout: 5) { File.size?(child_pid_file) }, "fake agent-coord did not start"

        child_pid = File.read(child_pid_file).to_i
        Process.kill("TERM", wrapper_pid)
        _, status = Process.waitpid2(wrapper_pid)

        assert_equal 143, status.exitstatus
        assert wait_until(timeout: 5) { !process_alive?(child_pid) }, "fake agent-coord survived wrapper termination"
      ensure
        Process.kill("KILL", wrapper_pid) if wrapper_pid && process_alive?(wrapper_pid)
        Process.kill("KILL", child_pid) if child_pid && process_alive?(child_pid)
      end
    end
  end

  def test_timeout_kills_remaining_process_group_helpers
    Dir.mktmpdir("agent-coord-bounded-test") do |dir|
      helper_pid_file = File.join(dir, "helper.pid")
      helper_pid = nil

      with_fake_agent_coord(<<~RUBY, "AGENT_COORD_HELPER_PID" => helper_pid_file) do |env|
        helper_code = "trap('TERM') {}; File.write(ENV.fetch('AGENT_COORD_HELPER_PID'), Process.pid.to_s); sleep 10"
        helper_pid = Process.spawn({ "AGENT_COORD_HELPER_PID" => ENV.fetch("AGENT_COORD_HELPER_PID") },
                                   #{RbConfig.ruby.dump}, "-e", helper_code)
        Process.detach(helper_pid)
        deadline = Time.now + 5
        sleep 0.05 until File.size?(ENV.fetch("AGENT_COORD_HELPER_PID")) || Time.now >= deadline
        sleep 10
      RUBY
        stdout, stderr, status = run_script(env, "--timeout", "1", "status")

        assert_equal 124, status.exitstatus
        assert_empty stdout
        assert_includes stderr, "agent-coord-bounded: timed out after 1.0s"
        assert wait_until(timeout: 5) { File.size?(helper_pid_file) }, "fake helper did not start"

        helper_pid = File.read(helper_pid_file).to_i
        assert wait_until(timeout: 5) { !process_alive?(helper_pid) }, "helper survived process-group cleanup"
      ensure
        Process.kill("KILL", helper_pid) if helper_pid && process_alive?(helper_pid)
      end
    end
  end

  private

  def run_script(env, *)
    Open3.capture3(env, RbConfig.ruby, SCRIPT, *)
  end

  def with_fake_agent_coord(body, extra_env = {})
    Dir.mktmpdir("agent-coord-bounded-test") do |dir|
      fake_bin = File.join(dir, "agent-coord")
      File.write(fake_bin, <<~RUBY)
        #!/usr/bin/env ruby
        #{body}
      RUBY
      FileUtils.chmod(0o755, fake_bin)
      env = { "PATH" => "#{dir}:#{ENV.fetch('PATH')}" }.merge(extra_env)

      yield env
    end
  end

  def wait_until(timeout: 2)
    deadline = Time.now + timeout
    until Time.now >= deadline
      return true if yield

      sleep 0.05
    end

    false
  end

  def process_alive?(pid)
    Process.kill(0, pid)
    true
  rescue Errno::ESRCH
    false
  end
end

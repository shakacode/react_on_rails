require 'spec_helper'
require 'capybara/webkit/connection'

describe Capybara::Webkit::Connection do
  it "kills the process when the parent process dies", skip_on_windows: true, skip_on_jruby: true do
    read_io, write_io = IO.pipe

    fork_pid = fork do
      read_io.close
      connection = Capybara::Webkit::Connection.new
      write_io.write(connection.pid)
      write_io.close
      Process.wait(connection.pid)
    end

    write_io.close

    webkit_pid = read_io.read.to_i
    webkit_pid.should be > 1
    read_io.close
    Process.kill(9, fork_pid)
    eventually { expect { Process.getpgid(webkit_pid) }.to raise_error Errno::ESRCH }
  end

  def eventually
    polling_interval = 0.1
    time_limit = Time.now + 3
    loop do
      begin
        yield
        return
      rescue RSpec::Expectations::ExpectationNotMetError => error
        raise error if Time.now >= time_limit
        sleep polling_interval
      end
    end
  end

  it "raises an error if the server has stopped", skip_on_windows: true do
    path = 'false'
    stub_const("Capybara::Webkit::Connection::SERVER_PATH", path)

    expect { Capybara::Webkit::Connection.new }.
      to raise_error(
        Capybara::Webkit::ConnectionError,
        "#{path} failed to start.")
  end

  it "raises an error if the server is not ready", skip_on_windows: true do
    server_path = 'sleep 1'
    stub_const("Capybara::Webkit::Connection::SERVER_PATH", server_path)
    start_timeout = 0.5
    stub_const("Capybara::Webkit::Connection::WEBKIT_SERVER_START_TIMEOUT", start_timeout)

    error_string =
      if defined?(::JRUBY_VERSION)
        "#{server_path} failed to start."
      else
        "#{server_path} failed to start after #{start_timeout} seconds."
      end

    expect { Capybara::Webkit::Connection.new }.
      to raise_error(Capybara::Webkit::ConnectionError, error_string)
  end

  it "boots a server to talk to" do
    url = "http://#{@rack_server.host}:#{@rack_server.port}/"
    connection.puts "Visit"
    connection.puts 1
    connection.puts url.to_s.bytesize
    connection.print url
    connection.gets.should eq "ok\n"
    connection.gets.should eq "0\n"
    connection.puts "Body"
    connection.puts 0
    connection.gets.should eq "ok\n"
    response_length = connection.gets.to_i
    response = connection.read(response_length)
    response.should include("Hey there")
  end

  it 'forwards stderr to the given IO object' do
    read_io, write_io = IO.pipe
    redirected_connection = Capybara::Webkit::Connection.new(:stderr => write_io)
    redirected_connection.puts "EnableLogging"
    redirected_connection.puts 0

    script = 'console.log("hello world")'
    redirected_connection.puts "Execute"
    redirected_connection.puts 1
    redirected_connection.puts script.to_s.bytesize
    redirected_connection.print script

    expect(read_io).to include_response "\nhello world"
  end

  it 'does not forward stderr to nil' do
    IO.should_not_receive(:copy_stream)
    Capybara::Webkit::Connection.new(:stderr => nil)
  end

  it 'prints a deprecation warning if the stdout option is used' do
    Capybara::Webkit::Connection.any_instance.should_receive(:warn)
    Capybara::Webkit::Connection.new(:stdout => nil)
  end

  it 'does not forward stdout to nil if the stdout option is used' do
    Capybara::Webkit::Connection.any_instance.stub(:warn)
    IO.should_not_receive(:copy_stream)
    Capybara::Webkit::Connection.new(:stdout => nil)
  end

  it "returns the server port" do
    connection.port.should be_between 0x400, 0xffff
  end

  it 'sets appropriate options on its socket' do
    socket = double('socket')
    TCPSocket.stub(:open).and_return(socket)
    if defined?(Socket::TCP_NODELAY)
      socket.should_receive(:setsockopt).with(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, true)
    else
      socket.should_not_receive(:setsockopt)
    end
    Capybara::Webkit::Connection.new
  end

  it "chooses a new port number for a new connection" do
    new_connection = Capybara::Webkit::Connection.new
    new_connection.port.should_not == connection.port
  end

  let(:connection) { Capybara::Webkit::Connection.new }

  before(:all) do
    @app = lambda do |env|
      body = "<html><body>Hey there</body></html>"
      [200,
        { 'Content-Type' => 'text/html', 'Content-Length' => body.size.to_s },
        [body]]
    end
    @rack_server = Capybara::Server.new(@app)
    @rack_server.boot
  end
end

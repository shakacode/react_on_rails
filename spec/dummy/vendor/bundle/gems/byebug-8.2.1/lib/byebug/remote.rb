require 'socket'

#
# Remote debugging functionality.
#
# TODO: Refactor & add tests
#
module Byebug
  # Port number used for remote debugging
  PORT = 8989 unless defined?(PORT)

  class << self
    # If in remote mode, wait for the remote connection
    attr_accessor :wait_connection

    # The actual port that the server is started at
    attr_accessor :actual_port
    attr_reader :actual_control_port

    #
    # Interrupts the current thread
    #
    def interrupt
      current_context.interrupt
    end

    #
    # Starts a remote byebug
    #
    def start_server(host = nil, port = PORT)
      return if @thread

      Context.interface = nil
      start

      start_control(host, port == 0 ? 0 : port + 1)

      yield if block_given?

      mutex = Mutex.new
      proceed = ConditionVariable.new

      server = TCPServer.new(host, port)
      self.actual_port = server.addr[1]

      @thread = DebugThread.new do
        while (session = server.accept)
          Context.interface = RemoteInterface.new(session)
          mutex.synchronize { proceed.signal } if wait_connection
        end
      end

      mutex.synchronize { proceed.wait(mutex) } if wait_connection
    end

    def start_control(host = nil, ctrl_port = PORT + 1)
      return @actual_control_port if @control_thread
      server = TCPServer.new(host, ctrl_port)
      @actual_control_port = server.addr[1]

      @control_thread = DebugThread.new do
        while (session = server.accept)
          Context.interface = RemoteInterface.new(session)

          ControlProcessor.new(Byebug.current_context).process_commands
        end
      end

      @actual_control_port
    end

    #
    # Connects to the remote byebug
    #
    def start_client(host = 'localhost', port = PORT)
      Context.interface = LocalInterface.new
      puts 'Connecting to byebug server...'
      socket = TCPSocket.new(host, port)
      puts 'Connected.'

      catch(:exit) do
        while (line = socket.gets)
          case line
          when /^PROMPT (.*)$/
            input = Context.interface.read_command(Regexp.last_match[1])
            throw :exit unless input
            socket.puts input
          when /^CONFIRM (.*)$/
            input = Context.interface.confirm(Regexp.last_match[1])
            throw :exit unless input
            socket.puts input
          else
            puts line
          end
        end
      end
      socket.close
    end

    def parse_host_and_port(host_port_spec)
      location = host_port_spec.split(':')
      location[1] ? [location[0], location[1].to_i] : ['localhost', location[0]]
    end
  end
end

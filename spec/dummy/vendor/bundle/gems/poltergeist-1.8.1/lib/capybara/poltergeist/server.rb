module Capybara::Poltergeist
  class Server
    attr_reader :socket, :fixed_port, :timeout

    def initialize(fixed_port = nil, timeout = nil)
      @fixed_port = fixed_port
      @timeout    = timeout
      start
    end

    def port
      @socket.port
    end

    def timeout=(sec)
      @timeout = @socket.timeout = sec
    end

    def start
      @socket = WebSocketServer.new(fixed_port, timeout)
    end

    def stop
      @socket.close
    end

    def restart
      stop
      start
    end

    def send(command)
      @socket.send(command.id, command.message) or raise DeadClient.new(command.message)
    end
  end
end

require 'pry-remote'

module PryRemote
  #
  # Overrides PryRemote::Server
  #
  class Server
    #
    # Override the call to Pry.start to save off current Server, and not
    # teardown the server right after Pry.start finishes.
    #
    def run
      fail('Already running a pry-remote session!') if
        PryByebug.current_remote_server

      PryByebug.current_remote_server = self

      setup
      Pry.start @object, input: client.input_proxy, output: client.output
    end

    #
    # Override to reset our saved global current server session.
    #
    alias_method :teardown_without_pry_byebug, :teardown
    def teardown_with_pry_byebug
      return if @torn

      teardown_without_pry_byebug
      PryByebug.current_remote_server = nil
      @torn = true
    end
    alias_method :teardown, :teardown_with_pry_byebug
  end
end

# Ensure cleanup when a program finishes without another break. For example,
# 'next' on the last line of a program won't hit Byebug::PryProcessor#run,
# which normally handles cleanup.
at_exit do
  PryByebug.current_remote_server.teardown if PryByebug.current_remote_server
end

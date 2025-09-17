# frozen_string_literal: true

require_relative "dev/server_manager"
require_relative "dev/process_manager"
require_relative "dev/pack_generator"
require_relative "dev/file_manager"

module ReactOnRails
  module Dev
    # Development server management for React on Rails
    #
    # This module provides classes to manage development servers,
    # process managers, pack generation, and file cleanup.
    #
    # Usage:
    #   ReactOnRails::Dev::ServerManager.start(:development)
    #   ReactOnRails::Dev::ServerManager.kill_processes
    #   ReactOnRails::Dev::ServerManager.show_help
  end
end

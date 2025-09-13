# frozen_string_literal: true
# Copyright (c) 2015–2025 ShakaCode, LLC
# SPDX-License-Identifier: MIT


module GeneratorMessages
  class << self
    def output
      @output ||= []
    end

    def add_error(message)
      output << format_error(message)
    end

    def add_warning(message)
      output << format_warning(message)
    end

    def add_info(message)
      output << format_info(message)
    end

    def messages
      output
    end

    def format_error(msg)
      Rainbow("ERROR: #{msg}").red
    end

    def format_warning(msg)
      Rainbow("WARNING: #{msg}").orange
    end

    def format_info(msg)
      Rainbow(msg.to_s).green
    end

    def clear
      @output = []
    end

    def helpful_message_after_installation
      <<~MSG

        What to do next:

          - See the documentation on https://github.com/shakacode/shakapacker#webpack-configuration
            for how to customize the default webpack configuration.

          - Include your webpack assets to your application layout.

              <%= javascript_pack_tag 'hello-world-bundle' %>

          - To start Rails server run:

              ./bin/dev # Running with HMR

            or

              ./bin/dev static # Running with statically created bundles, without HMR

          - To server render, change this line app/views/hello_world/index.html.erb to
            `prerender: true` to see server rendering (right click on page and select "view source").

              <%= react_component("HelloWorldApp", props: @hello_world_props, prerender: true) %>

        Alternative steps to run the app:

          - We recommend using Procfile.dev with foreman, overmind, or a similar program. Alternately, you can run each of the processes listed in Procfile.dev in a separate tab in your terminal.

          - Visit http://localhost:3000/hello_world and see your React On Rails app running!
      MSG
    end
  end
end
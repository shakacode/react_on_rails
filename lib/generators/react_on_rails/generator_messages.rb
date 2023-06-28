# frozen_string_literal: true

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

              ./bin/dev-static # Running with statically created bundles, without HMR

          - To server render, change this line app/views/hello_world/index.html.erb to
            `prerender: true` to see server rendering (right click on page and select "view source").

              <%= react_component("HelloWorldApp", props: @hello_world_props, prerender: true) %>

        Alternative steps to run the app:

          - Run `rails s` to start the Rails server.

          - Run bin/shakapacker-dev-server to start the Webpack dev server for compilation of Webpack
            assets as soon as you save. This default setup with the dev server does not work
            for server rendering

          - Visit http://localhost:3000/hello_world and see your React On Rails app running!

          - To turn on HMR, edit config/shakapacker.yml and set HMR to true. Restart the rails server
            and bin/shakapacker-dev-server. Or use Procfile.dev.
      MSG
    end
  end
end

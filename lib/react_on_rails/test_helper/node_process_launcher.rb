module ReactOnRails
  module TestHelper
    def self.launch_node
      return unless ReactOnRails.configuration.server_render_method == "NodeJS"

      path = "#{::Rails.root}/client/node"
      puts "Launching NodeJS server at #{path}"
      system("cd #{path} && yarn start &")
      sleep(1)
    end
  end
end

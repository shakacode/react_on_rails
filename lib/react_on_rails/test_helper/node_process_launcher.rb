module ReactOnRails
  module TestHelper
    def self.launch_node
      if ReactOnRails.configuration.server_render_method == "NodeJS"
        path = "#{::Rails.root}/client/node"
        puts "Launching NodeJS server at #{path}"
        system("cd #{::Rails.root}/client/node && npm start &")
      end
    end
  end
end
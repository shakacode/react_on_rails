# frozen_string_literal: true

shared_examples "base_generator_common" do
  it "adds a route for get 'hello_world' to 'hello_world#index'" do
    match = <<-MATCH.strip_heredoc
      Rails.application.routes.draw do
        get 'hello_world', to: 'hello_world#index'
      end
    MATCH
    assert_file "config/routes.rb", match
  end

  it "copies common files" do
    %w[app/controllers/hello_world_controller.rb
       config/initializers/react_on_rails.rb
       Procfile.dev
       Procfile.dev-static-assets
       Procfile.dev-prod-assets].each { |file| assert_file(file) }
  end
end

shared_examples "react_component_structure" do
  it "creates react directories" do
    # Auto-registration structure for non-Redux components
    assert_directory "app/javascript/src/HelloWorld/ror_components"
  end

  it "copies react files" do
    # Auto-registration components for non-Redux
    assert_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.client.jsx"
    assert_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.server.jsx"
  end
end

shared_examples "base_generator" do
  include_examples "base_generator_common"
  include_examples "react_component_structure"
end

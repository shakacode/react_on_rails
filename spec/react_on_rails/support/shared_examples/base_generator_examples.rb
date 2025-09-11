# frozen_string_literal: true

shared_examples "base_generator" do
  it "adds a route for get 'hello_world' to 'hello_world#index'" do
    match = <<-MATCH.strip_heredoc
      Rails.application.routes.draw do
        get 'hello_world', to: 'hello_world#index'
      end
    MATCH
    assert_file "config/routes.rb", match
  end

  it "creates react directories" do
    # Auto-registration structure is always created
    assert_directory "app/javascript/src/HelloWorld/ror_components"
  end

  it "copies react files" do
    %w[app/controllers/hello_world_controller.rb
       config/initializers/react_on_rails.rb
       Procfile.dev
       Procfile.dev-static
       Procfile.dev-static-assets
       Procfile.dev-prod-assets].each { |file| assert_file(file) }

    # Auto-registration component is always created
    assert_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.jsx"
  end
end

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
    dirs = %w[components]
    dirs.each { |dirname| assert_directory "client/app/bundles/HelloWorld/#{dirname}" }
  end

  it "copies react files" do
    %w[app/controllers/hello_world_controller.rb
       client/app/bundles/HelloWorld/components/HelloWorld.jsx
       config/initializers/react_on_rails.rb
       Procfile.dev
       Procfile.dev-server].each { |file| assert_file(file) }
  end
end

shared_examples "base_generator" do
  it "adds a route for get 'hello_world' to 'hello_world#index'" do
    match = <<-MATCH.strip_heredoc
      Rails.application.routes.draw do
        get 'hello_world', to: 'hello_world#index'
      end
    MATCH
    assert_file "config/routes.rb", match
  end

  it "updates the .gitignore file" do
    match = <<-MATCH.strip_heredoc
      some existing text
      # React on Rails
      npm-debug.log*
      node_modules

      # Generated js bundles
      /public/webpack/*
    MATCH
    assert_file ".gitignore", match
  end

  it "creates react directories" do
    dirs = %w(components containers startup)
    dirs.each { |dirname| assert_directory "client/app/bundles/HelloWorld/#{dirname}" }
  end

  it "copies react files" do
    %w(app/controllers/hello_world_controller.rb
       client/app/bundles/HelloWorld/components/HelloWorld.jsx
       client/REACT_ON_RAILS_CLIENT_README.md
       client/webpack.config.js
       client/.babelrc
       client/package.json
       config/initializers/react_on_rails.rb
       config/webpack/paths.yml
       package.json
       Procfile.dev).each { |file| assert_file(file) }
  end

  it "appends path configurations to assets.rb" do
    expected = ReactOnRails::Generators::BaseGenerator::ASSETS_RB_APPEND
    assert_file("config/initializers/assets.rb") { |contents| assert_match(expected, contents) }
  end

  it "templates HelloWorldApp into webpack.config.js" do
    assert_file("client/webpack.config.js") do |contents|
      assert_match("registration", contents)
    end
  end
end

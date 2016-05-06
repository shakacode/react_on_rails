shared_examples "base_generator:base" do |options|
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
      npm-debug.log
      node_modules

      # Generated js bundles
      /app/assets/webpack/*
    MATCH
    assert_file ".gitignore", match
  end

  it "updates application.js" do
    match = <<-MATCH.strip_heredoc
      // DO NOT REQUIRE jQuery or jQuery-ujs in this file!
      // DO NOT REQUIRE TREE!

      // CRITICAL that vendor-bundle must be BEFORE bootstrap-sprockets and turbolinks
      // since it is exposing jQuery and jQuery-ujs

      //= require vendor-bundle
      //= require app-bundle

    MATCH
    assert_file("app/assets/javascripts/application.js") do |contents|
      assert_match(match, contents)
    end
  end

  it "doesn't include incompatible sprockets require statements" do
    assert_file("app/assets/javascripts/application.js") do |contents|
      refute_match(%r{//= require_tree \.$}, contents)
      refute_match(%r{//= require jquery$}, contents)
      refute_match("//= require jquery_ujs", contents)
    end
  end

  it "comments out incompatible sprockets require statements" do
    assert_file("app/assets/javascripts/application.js") do |contents|
      if options[:application_js]
        assert_match(%r{// require_tree \.$}, contents)
        assert_match(%r{// require jquery$}, contents)
        assert_match("//= require jquery-ui", contents)
        assert_match("// require jquery_ujs", contents)
      end
    end
  end

  it "creates react directories" do
    dirs = %w(components containers startup)
    dirs.each { |dirname| assert_directory "client/app/bundles/HelloWorld/#{dirname}" }
  end

  it "copies react files" do
    %w(app/controllers/hello_world_controller.rb
       app/views/hello_world/index.html.erb
       client/REACT_ON_RAILS_CLIENT_README.md
       client/app/bundles/HelloWorld/startup/clientRegistration.jsx
       client/webpack.client.rails.config.js
       client/.babelrc
       client/package.json
       config/initializers/react_on_rails.rb
       package.json
       Procfile.dev
       REACT_ON_RAILS.md).each { |file| assert_file(file) }
  end

  it "appends path configurations to assets.rb" do
    expected = ReactOnRails::Generators::BaseGenerator::ASSETS_RB_APPEND
    assert_file("config/initializers/assets.rb") { |contents| assert_match(expected, contents) }
  end
end

shared_examples "base_generator:no_server_rendering" do
  it "copies client-side-rendering version of Procfile.dev" do
    %w(Procfile.dev).each do |file|
      assert_file(file) do |contents|
        refute_match(/server: sh -c 'cd client && npm run build:dev:server'/, contents)
      end
    end
  end

  it "copies client-side-rendering version of hello_world/index.html.erb" do
    assert_file("app/views/hello_world/index.html.erb") do |contents|
      assert_match("prerender: false", contents)
    end
  end

  it "templates client-side-rendering version of webpack.client.base.js" do
    assert_file("client/webpack.client.base.config.js") do |contents|
      assert_match("clientRegistration", contents)
    end
  end

  it "doesn't add therubyracer to the Gemfile" do
    assert_file("Gemfile") do |contents|
      refute_match("gem 'therubyracer', platforms: :ruby", contents)
    end
  end

  it "doesn't copy server-side-rendering-only files" do
    %w(client/webpack.server.rails.config.js
       client/app/bundles/HelloWorld/startup/serverRegistration.jsx).each { |file| assert_no_file(file) }
  end

  it "sets server bundle js file to '' in react_on_rails initializer" do
    assert_file("config/initializers/react_on_rails.rb") do |contents|
      assert_match(/config.server_bundle_js_file = ""/, contents)
    end
  end
end

shared_examples "base_generator:server_rendering" do
  it "copies server-rendering-only files" do
    %w(client/webpack.server.rails.config.js
       client/app/bundles/HelloWorld/startup/serverRegistration.jsx).each { |file| assert_file(file) }
  end

  it "templates client-side-rendering version of webpack.client.base.js" do
    assert_file("client/webpack.client.base.config.js") do |contents|
      assert_match("clientRegistration", contents)
    end
  end

  it "copies server-side-rendering version of Procfile.dev" do
    %w(Procfile.dev).each do |file|
      assert_file(file) do |contents|
        assert_match(/server: sh -c 'cd client && npm run build:dev:server'/, contents)
      end
    end
  end

  it "copies the server-side-rendering version of hello_world/index.html.erb" do
    assert_file("app/views/hello_world/index.html.erb") do |contents|
      assert_match("prerender: true", contents)
    end
  end

  it "adds therubyracer to the Gemfile" do
    assert_file("Gemfile") do |contents|
      assert_match("gem 'therubyracer', platforms: :ruby", contents)
    end
  end

  it "sets server bundle js file to server-bundle in react_on_rails initializer" do
    regexp = /config.server_bundle_js_file = "server-bundle.js"/
    assert_file("config/initializers/react_on_rails.rb") do |contents|
      assert_match(regexp, contents)
    end
  end
end

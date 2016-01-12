shared_examples "base_generator:base" do |options|
  it "adds a route for get 'hello_world' to 'hello_world#index'" do
    match = <<-MATCH.strip_heredoc
      Rails.application.routes.draw do
        get 'hello_world', to: 'hello_world#index'
      end
    MATCH
    assert_file "config/routes.rb", match
  end

  it "adds client assets directories" do
    assert_directory("client/assets/stylesheets")
    assert_directory_with_keep_file("client/assets/fonts")
    assert_directory_with_keep_file("client/assets/images")
  end

  it "updates the .gitignore file" do
    match = <<-MATCH.strip_heredoc
      some existing text
      # React on Rails
      npm-debug.log
      node_modules

      # Generated js bundles
      /app/assets/javascripts/generated/*
    MATCH
    assert_file ".gitignore", match
  end

  it "updates application.js" do
    match = <<-MATCH.strip_heredoc
      // DO NOT REQUIRE jQuery or jQuery-ujs in this file!
      // DO NOT REQUIRE TREE!

      // CRITICAL that generated/vendor-bundle must be BEFORE bootstrap-sprockets and turbolinks
      // since it is exposing jQuery and jQuery-ujs
      //= require react_on_rails

      //= require generated/vendor-bundle
      //= require generated/app-bundle

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
       config/initializers/react_on_rails.rb
       client/webpack.client.hot.config.js
       client/webpack.client.rails.config.js
       client/.babelrc
       client/index.jade
       client/package.json
       client/server.js
       lib/tasks/assets.rake
       package.json
       Procfile.dev
       REACT_ON_RAILS.md
       client/REACT_ON_RAILS_CLIENT_README.md).each { |file| assert_file(file) }
  end

  it "appends path configurations to assets.rb" do
    expected = <<-EXPECTED.strip_heredoc
      # Add client/assets/ folders to asset pipeline's search path.
      # If you do not want to move existing images and fonts from your Rails app
      # you could also consider creating symlinks there that point to the original
      # rails directories. In that case, you would not add these paths here.
      Rails.application.config.assets.paths << Rails.root.join("client", "assets", "stylesheets")
      Rails.application.config.assets.paths << Rails.root.join("client", "assets", "images")
      Rails.application.config.assets.paths << Rails.root.join("client", "assets", "fonts")
      Rails.application.config.assets.precompile += %w( generated/server-bundle.js react_on_rails )
    EXPECTED
    assert_file("config/initializers/assets.rb") { |contents| assert_match(expected, contents) }
  end
end

shared_examples "base_generator:no_server_rendering" do
  it "copies client-side-rendering version of Procfile.dev" do
    assert_file("Procfile.dev") do |contents|
      refute_match(/server: sh -c 'cd client && npm run build:dev:server'/, contents)
    end
  end

  it "copies client-side-rendering version of assets.rake" do
    assert_file("lib/tasks/assets.rake") do |contents|
      refute_match(/sh "cd client && npm run build:server"/, contents)
    end
  end

  it "copies client-side-rendering version of clientGlobals" do
    assert_file("client/webpack.client.base.config.js") do |contents|
      assert_match("startup/globals", contents)
      refute_match("startup/clientGlobals", contents)
    end
  end

  it "copies client-side-rendering version of hello_world/index.html.erb" do
    assert_file("app/views/hello_world/index.html.erb") do |contents|
      assert_match("prerender: false", contents)
    end
  end

  it "templates client-side-rendering version of globals" do
    assert_file("client/app/bundles/HelloWorld/startup/globals.jsx") do |contents|
      assert_match("HelloWorldApp", contents)
      refute_match("HelloWorldAppClient", contents)
    end
  end

  it "templates client-side-rendering version of webpack.client.base.js" do
    assert_file("client/webpack.client.base.config.js") do |contents|
      assert_match("globals", contents)
      refute_match("clientGlobals", contents)
    end
  end

  it "doesn't add therubyracer to the Gemfile" do
    assert_file("Gemfile") do |contents|
      refute_match("gem 'therubyracer', platforms: :ruby", contents)
    end
  end
end

shared_examples "base_generator:server_rendering" do
  it "templates server-side-rendering version of globals" do
    assert_file("client/app/bundles/HelloWorld/startup/clientGlobals.jsx") do |contents|
      assert_match("HelloWorldAppClient", contents)
    end
  end

  it "copies server-side-rendering version of assets.rake" do
    assert_file("lib/tasks/assets.rake") do |contents|
      assert_match(/sh "cd client && npm run build:server"/, contents)
    end
  end

  it "copies server-rendering-only files" do
    %w(client/webpack.server.rails.config.js
       client/app/bundles/HelloWorld/startup/serverGlobals.jsx).each { |file| assert_file(file) }
  end

  it "copies server-side-rendering version of clientGlobals" do
    assert_file("client/webpack.client.base.config.js") do |contents|
      assert_match("startup/clientGlobals", contents)
      refute_match("startup/globals", contents)
    end
  end

  it "templates client-side-rendering version of webpack.client.base.js" do
    assert_file("client/webpack.client.base.config.js") do |contents|
      assert_match("clientGlobals", contents)
      refute_match("globals", contents)
    end
  end

  it "copies server-side-rendering version of Procfile.dev" do
    assert_file("Procfile.dev") do |contents|
      assert_match(/server: sh -c 'cd client && npm run build:dev:server'/, contents)
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
end

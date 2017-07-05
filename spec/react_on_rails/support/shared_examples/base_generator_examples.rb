# frozen_string_literal: true

shared_examples "base_generator" do
  it "adds a route for get 'hello_world' to 'hello_world#index'" do
    match = <<-MATCH.strip_heredoc
      Rails.application.routes.draw do
        get '#{example_page_path}', to: '#{example_page_path}#index'
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
    dirs = %w[components containers startup]
    dirs.each do |dirname|
      assert_directory "client/app/bundles/#{example_page_name}/#{dirname}"
    end
  end

  it "copies react files" do
    ["app/controllers/#{example_page_path}_controller.rb",
     "client/app/bundles/#{example_page_name}/components/#{example_page_name}.jsx",
     "client/REACT_ON_RAILS_CLIENT_README.md",
     "client/webpack.config.js",
     "client/.babelrc",
     "client/package.json",
     "config/initializers/react_on_rails.rb",
     "config/webpacker_lite.yml",
     "package.json",
     "Procfile.dev"].each { |file| assert_file(file) }
  end

  it "templates HelloWorldApp into webpack.config.js" do
    assert_file("client/webpack.config.js") do |contents|
      assert_match("registration", contents)
    end
  end
end

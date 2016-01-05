shared_examples "no_redux_generator:base" do
  it "copies non-redux base files" do
    assert_file("client/app/bundles/HelloWorld/containers/HelloWorld.jsx")
  end

  it "does not place react folders in root" do
    %w(reducers store middlewares constants actions).each do |dir|
      assert_no_directory(dir)
    end
  end
end

shared_examples "no_redux_generator:no_server_rendering" do
  it "does not copy react server-rendering-specific files" do
    assert_no_file("client/webpack.server.rails.config.js")
    assert_no_file("client/app/bundles/HelloWorld/startup/HelloWorldAppServer.jsx")
  end

  it "templates the client-side-rendering version of HelloWorldApp" do
    assert_file("client/app/bundles/HelloWorld/startup/HelloWorldAppClient.jsx") do |contents|
      assert_match("HelloWorld", contents)
    end
  end
end

shared_examples "no_redux_generator:server_rendering" do
  it "copies the react server-rendering-specific files" do
    assert_file("client/webpack.server.rails.config.js")
    assert_file("client/app/bundles/HelloWorld/startup/HelloWorldAppServer.jsx")
  end

  it "templates the server-side-rendering version of HelloWorldApp" do
    assert_file("client/app/bundles/HelloWorld/startup/HelloWorldAppClient.jsx") do |contents|
      assert_match("HelloWorld", contents)
    end
  end
end

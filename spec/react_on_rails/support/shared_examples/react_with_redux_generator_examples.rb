shared_examples "react_with_redux_generator:base" do
  it "creates redux directories" do
    %w(actions constants reducers store).each { |dir| assert_directory("client/app/bundles/HelloWorld/#{dir}") }
    assert_directory("client/app/lib/middlewares")
  end

  it "copies base redux files" do
    %w(client/app/bundles/HelloWorld/actions/helloWorldActionCreators.jsx
       client/app/bundles/HelloWorld/components/HelloWorldWidget.jsx
       client/app/bundles/HelloWorld/containers/HelloWorld.jsx
       client/app/bundles/HelloWorld/constants/helloWorldConstants.jsx
       client/app/bundles/HelloWorld/reducers/helloWorldReducer.jsx
       client/app/bundles/HelloWorld/reducers/index.jsx
       client/app/bundles/HelloWorld/store/helloWorldStore.jsx
       client/app/lib/middlewares/loggerMiddleware.js).each { |file| assert_file(file) }
  end
end

shared_examples "react_with_redux_generator:no_server_rendering" do
  it "templates the client-side-rendering version of HelloWorldAppClient" do
    assert_file("client/app/bundles/HelloWorld/startup/HelloWorldApp.jsx") do |contents|
      assert_match("HelloWorldApp", contents)
      refute_match("HelloWorldAppClient", contents)
    end
  end
end

shared_examples "react_with_redux_generator:server_rendering" do
  it "copies redux version of helloWorldAppServer.jsx" do
    assert_file("client/app/bundles/HelloWorld/startup/HelloWorldAppServer.jsx") do |contents|
      assert_match(/import { Provider } from 'react-redux';/, contents)
    end
  end

  it "templates the server-side-rendering version of HelloWorldAppClient" do
    assert_file("client/app/bundles/HelloWorld/startup/HelloWorldAppClient.jsx") do |contents|
      assert_match("HelloWorldAppClient", contents)
    end
  end
end

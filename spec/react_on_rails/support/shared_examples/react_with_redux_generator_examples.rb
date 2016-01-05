shared_examples "react_with_redux_generator:base" do
  it "creates redux directories" do
    %w(actions constants reducers store).each { |dir| assert_directory("client/app/bundles/HelloWorld/#{dir}") }
    assert_directory("client/app/lib/middlewares")
  end

  it "copies base redux files" do
    %w(client/app/bundles/HelloWorld/actions/helloWorldActionCreators.jsx
       client/app/bundles/HelloWorld/containers/HelloWorld.jsx
       client/app/bundles/HelloWorld/constants/helloWorldConstants.jsx
       client/app/bundles/HelloWorld/reducers/helloWorldReducer.jsx
       client/app/bundles/HelloWorld/reducers/index.jsx
       client/app/bundles/HelloWorld/store/helloWorldStore.jsx
       client/app/lib/middlewares/loggerMiddleware.js
       client/app/bundles/HelloWorld/startup/HelloWorldAppClient.jsx).each { |file| assert_file(file) }
  end
end

shared_examples "react_with_redux_generator:no_server_rendering" do
  it "does not template the server-side rendering files" do
    assert_no_file "client/app/bundles/HelloWorld/startup/HelloWorldAppServer.jsx"
  end
end

shared_examples "react_with_redux_generator:server_rendering" do
  it "copies redux version of helloWorldAppServer.jsx" do
    assert_file("client/app/bundles/HelloWorld/startup/HelloWorldAppServer.jsx") do |contents|
      assert_match(/import { Provider } from 'react-redux';/, contents)
    end
  end
end

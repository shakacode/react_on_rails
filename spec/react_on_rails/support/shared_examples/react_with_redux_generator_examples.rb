shared_examples "react_with_redux_generator" do
  it "creates redux directories" do
    %w(actions constants reducers store).each { |dir| assert_directory("client/app/bundles/HelloWorld/#{dir}") }
  end

  it "creates appropriate templates" do
    assert_file("client/app/bundles/HelloWorld/startup/registration.jsx") do |contents|
      assert_match("import HelloWorldApp from './HelloWorldApp';", contents)
    end
    assert_file("app/views/hello_world/index.html.erb") do |contents|
      assert_match(/"HelloWorldApp"/, contents)
    end
  end

  it "copies base redux files" do
    %w(client/app/bundles/HelloWorld/actions/helloWorldActionCreators.jsx
       client/app/bundles/HelloWorld/containers/HelloWorldContainer.jsx
       client/app/bundles/HelloWorld/constants/helloWorldConstants.jsx
       client/app/bundles/HelloWorld/reducers/helloWorldReducer.jsx
       client/app/bundles/HelloWorld/store/helloWorldStore.jsx
       client/app/bundles/HelloWorld/startup/HelloWorldApp.jsx).each { |file| assert_file(file) }
  end
end

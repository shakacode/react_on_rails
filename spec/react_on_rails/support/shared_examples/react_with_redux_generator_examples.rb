shared_examples "react_with_redux_generator" do
  it "creates redux directories" do
    %w(actions
       constants
       containers
       reducers
       store).each do |dir|
         assert_directory("client/app/bundles/HelloWorld/#{dir}")
       end
  end

  it "copies base redux files" do
    %w(client/app/bundles/HelloWorld/actions/helloWorldActionCreators.jsx
       client/app/bundles/HelloWorld/components/HelloWorld.jsx
       client/app/bundles/HelloWorld/containers/HelloWorldContainer.jsx
       client/app/bundles/HelloWorld/constants/helloWorldConstants.jsx
       client/app/bundles/HelloWorld/reducers/helloWorldReducer.jsx
       client/app/bundles/HelloWorld/store/helloWorldStore.jsx
       client/app/bundles/HelloWorld/startup/HelloWorldApp.jsx
       client/app/bundles/HelloWorld/startup/registration.jsx).each { |file| assert_file(file) }
  end
end

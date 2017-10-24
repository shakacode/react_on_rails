# frozen_string_literal: true

shared_examples "react_with_redux_generator" do
  it "creates redux directories" do
    %w[actions constants reducers store].each { |dir| assert_directory("app/javascript/bundles/HelloWorld/#{dir}") }
  end

  it "creates appropriate templates" do
    assert_file("app/javascript/packs/hello-world-bundle.js") do |contents|
      assert_match("import HelloWorldApp from '../bundles/HelloWorld/startup/HelloWorldApp';", contents)
    end
    assert_file("app/views/hello_world/index.html.erb") do |contents|
      assert_match(/"HelloWorldApp"/, contents)
    end
  end

  it "copies base redux files" do
    %w[app/javascript/bundles/HelloWorld/actions/helloWorldActionCreators.js
       app/javascript/bundles/HelloWorld/containers/HelloWorldContainer.js
       app/javascript/bundles/HelloWorld/constants/helloWorldConstants.js
       app/javascript/bundles/HelloWorld/reducers/helloWorldReducer.js
       app/javascript/bundles/HelloWorld/store/helloWorldStore.js
       app/javascript/bundles/HelloWorld/startup/HelloWorldApp.jsx].each { |file| assert_file(file) }
  end
end

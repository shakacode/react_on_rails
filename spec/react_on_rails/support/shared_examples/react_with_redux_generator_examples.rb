# frozen_string_literal: true

shared_examples "react_with_redux_generator" do
  it "creates redux directories" do
    assert_directory "app/javascript/src/HelloWorldApp/ror_components"
    %w[actions constants containers reducers store].each do |dir|
      assert_directory("app/javascript/src/HelloWorldApp/#{dir}")
    end
  end

  it "creates appropriate templates" do
    assert_file("app/views/hello_world/index.html.erb") do |contents|
      expect(contents).to match(/"HelloWorldApp"/)
    end
  end

  it "copies base redux files" do
    %w[app/javascript/src/HelloWorldApp/actions/helloWorldActionCreators.js
       app/javascript/src/HelloWorldApp/containers/HelloWorldContainer.js
       app/javascript/src/HelloWorldApp/constants/helloWorldConstants.js
       app/javascript/src/HelloWorldApp/reducers/helloWorldReducer.js
       app/javascript/src/HelloWorldApp/store/helloWorldStore.js
       app/javascript/src/HelloWorldApp/ror_components/HelloWorldApp.client.jsx
       app/javascript/src/HelloWorldApp/ror_components/HelloWorldApp.server.jsx].each { |file| assert_file(file) }
  end

  it "does not create non-Redux HelloWorld ror_components directory" do
    assert_no_directory "app/javascript/src/HelloWorld/ror_components"
    assert_no_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.module.css"
  end
end

# frozen_string_literal: true

shared_examples "react_with_redux_generator" do
  it "creates redux directories" do
    %w[actions constants reducers store].each do |dir|
      assert_directory("client/app/bundles/#{example_page_name}/#{dir}")
    end
  end

  it "creates appropriate templates" do
    assert_file("client/app/bundles/#{example_page_name}/startup/registration.jsx") do |contents|
      assert_match("import #{example_page_name}App from './#{example_page_name}App';", contents)
    end
    assert_file("app/views/#{example_page_path}/index.html.erb") do |contents|
      assert_match(/"#{example_page_name}App"/, contents)
    end
  end

  it "copies base redux files" do
    %w[client/app/bundles/HelloWorld/actions/helloWorldActionCreators.jsx
       client/app/bundles/HelloWorld/containers/HelloWorldContainer.jsx
       client/app/bundles/HelloWorld/constants/helloWorldConstants.jsx
       client/app/bundles/HelloWorld/reducers/helloWorldReducer.jsx
       client/app/bundles/HelloWorld/store/helloWorldStore.jsx
       client/app/bundles/HelloWorld/startup/HelloWorldApp.jsx].each do |file|
      file_using_passed_example_page_name = convert_example_page_name(file)
      assert_file(file_using_passed_example_page_name)
    end
  end
end

# frozen_string_literal: true

shared_examples "react_with_redux_generator" do |options = {}|
  typescript = options.fetch(:typescript, false)
  template_extension = typescript ? "ts" : "js"
  component_extension = typescript ? "tsx" : "jsx"

  it "creates redux directories" do
    assert_directory "app/javascript/src/HelloWorldApp/ror_components"
    %w[actions constants containers reducers store].each do |dir|
      assert_directory("app/javascript/src/HelloWorldApp/#{dir}")
    end
  end

  it "creates appropriate templates" do
    assert_file("app/views/hello_world/index.html.erb") do |contents|
      expect(contents).to match(/"HelloWorldApp"/)
      expect(contents).to include("Redux SSR Demo")
      expect(contents).to include("Redux store bootstrapping")
      expect(contents).to include("Inspect these files next")
      expect(contents).to include('<code class="path-hint">app/javascript/src/HelloWorldApp/</code>')
      expect(contents).to include("overflow-wrap: anywhere")
      expect(contents).to include("Compare OSS and Pro")
    end
  end

  it "copies base redux files" do
    [
      "app/javascript/src/HelloWorldApp/actions/helloWorldActionCreators.#{template_extension}",
      "app/javascript/src/HelloWorldApp/containers/HelloWorldContainer.#{template_extension}",
      "app/javascript/src/HelloWorldApp/constants/helloWorldConstants.#{template_extension}",
      "app/javascript/src/HelloWorldApp/reducers/helloWorldReducer.#{template_extension}",
      "app/javascript/src/HelloWorldApp/store/helloWorldStore.#{template_extension}",
      "app/javascript/src/HelloWorldApp/ror_components/HelloWorldApp.client.#{component_extension}",
      "app/javascript/src/HelloWorldApp/ror_components/HelloWorldApp.server.#{component_extension}"
    ].each { |file| assert_file(file) }
  end

  it "does not create non-Redux HelloWorld ror_components directory" do
    assert_no_directory "app/javascript/src/HelloWorld/ror_components"
    assert_no_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.module.css"
  end
end

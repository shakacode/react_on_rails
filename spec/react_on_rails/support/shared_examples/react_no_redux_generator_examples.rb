shared_examples "no_redux_generator" do
  it "copies non-redux base files" do
    assert_file("client/app/bundles/HelloWorld/containers/HelloWorld.jsx")
    assert_file("client/app/bundles/HelloWorld/startup/HelloWorldApp.jsx") do |contents|
      assert_match("HelloWorld", contents)
    end
  end

  it "does not place react folders in root" do
    %w(reducers store middlewares constants actions).each do |dir|
      assert_no_directory(dir)
    end
  end
end

shared_examples "no_redux_generator" do
  it "creates appropriate templates" do
    assert_file("client/app/bundles/HelloWorld/startup/registration.jsx") do |contents|
      assert_match("../components/HelloWorldApp", contents)
    end
    assert_file("client/app/bundles/HelloWorld/components/HelloWorldApp.jsx") do |contents|
      assert_match("class HelloWorldApp extends", contents)
    end
  end

  it "does not place react folders in root" do
    %w(reducers store middlewares constants actions).each do |dir|
      assert_no_directory(dir)
    end
  end
end

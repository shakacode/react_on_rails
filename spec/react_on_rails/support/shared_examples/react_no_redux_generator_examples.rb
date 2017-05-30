shared_examples "no_redux_generator" do
  it "creates appropriate templates" do
    assert_file("client/app/bundles/MainPage/startup/registration.jsx") do |contents|
      assert_match("import MainPage from '../components/MainPage';", contents)
    end
    assert_file("app/views/main_page/index.html.erb") do |contents|
      assert_match(/"MainPage"/, contents)
    end
  end

  it "does not place react folders in root" do
    %w(reducers store middlewares constants actions).each do |dir|
      assert_no_directory(dir)
    end
  end
end

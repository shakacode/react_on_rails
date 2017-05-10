shared_examples "react_with_redux_generator" do
  it "creates redux directories" do
    %w(actions constants reducers store).each { |dir| assert_directory("client/app/bundles/MainPage/#{dir}") }
  end

  it "creates appropriate templates" do
    assert_file("client/app/bundles/MainPage/startup/registration.jsx") do |contents|
      assert_match("import MainPageApp from './MainPageApp';", contents)
    end
    assert_file("app/views/main_page/index.html.erb") do |contents|
      assert_match(/"MainPageApp"/, contents)
    end
  end

  it "copies base redux files" do
    %w(client/app/bundles/MainPage/actions/mainPageActionCreators.jsx
       client/app/bundles/MainPage/containers/MainPageContainer.jsx
       client/app/bundles/MainPage/constants/mainPageConstants.jsx
       client/app/bundles/MainPage/reducers/mainPageReducer.jsx
       client/app/bundles/MainPage/store/mainPageStore.jsx
       client/app/bundles/MainPage/startup/MainPageApp.jsx).each { |file| assert_file(file) }
  end
end

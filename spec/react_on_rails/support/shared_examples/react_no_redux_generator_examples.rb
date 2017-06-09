# frozen_string_literal: true

shared_examples "no_redux_generator" do
  it "creates appropriate templates" do
    assert_file("client/app/bundles/#{example_page_name}/startup/registration.jsx") do |contents|
      assert_match("import #{example_page_name} from '../components/#{example_page_name}';", contents)
    end
    assert_file("app/views/#{example_page_path}/index.html.erb") do |contents|
      assert_match(/"#{example_page_name}"/, contents)
    end
  end

  it "does not place react folders in root" do
    %w[reducers store middlewares constants actions].each do |dir|
      assert_no_directory(dir)
    end
  end
end

# frozen_string_literal: true

shared_examples "no_redux_generator" do
  it "creates appropriate templates" do
    assert_file("app/javascript/packs/hello-world-bundle.js") do |contents|
      assert_match("import HelloWorld from '../bundles/HelloWorld/components/HelloWorld';", contents)
    end

    assert_file("app/views/hello_world/index.html.erb") do |contents|
      assert_match(/"HelloWorld"/, contents)
    end
  end

  it "does not place react folders in root" do
    %w[reducers store middlewares constants actions].each do |dir|
      assert_no_directory(dir)
    end
  end
end

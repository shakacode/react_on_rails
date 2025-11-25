# frozen_string_literal: true

shared_examples "no_redux_generator" do
  it "creates appropriate templates" do
    # No manual bundle for non-Redux (auto-bundling only)
    assert_no_file("app/javascript/packs/hello-world-bundle.js")

    assert_file("app/views/hello_world/index.html.erb") do |contents|
      expect(contents).to match(/"HelloWorld"/)
    end
  end

  it "does not place react folders in root" do
    %w[reducers store middlewares constants actions].each do |dir|
      assert_no_directory(dir)
    end
  end
end

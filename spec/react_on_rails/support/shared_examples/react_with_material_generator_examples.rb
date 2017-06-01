shared_examples "react_with_material_generator" do

  it "copies base material design sass import directives file" do
    %w(client/app/assets/styles/react_md.scss).each { |file| assert_file(file) }
  end

  it "adds appropriate import directives" do
    assert_file("client/app/styles/react_md.scss") do |contents|
      assert_match("@import '~react-md/src/scss/react-md';", contents)
      assert_match("@include react-md-everything;", contents)
    end
  end

  it "adds appropriate modules to the package.json file" do
    assert_file("client/package.json") do |contents|
      assert_match('"react-addons-css-transition-group":', contents)
      assert_match('"react-addons-transition-group":', contents)
      assert_match('"react-md":', contents)
    end
  end

end

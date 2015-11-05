shared_examples ":js_linters" do
  it "copies linter config files" do
    assert_file "client/.eslintrc"
    assert_file "client/.eslintignore"
    assert_file "client/.jscsrc"
  end

  it "copies linter node modules in package.json" do
    assert_match(linter_modules, linter_modules_included_in_package_json)
  end
end

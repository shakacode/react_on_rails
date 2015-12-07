shared_examples "js_linters:enabled" do
  it "copies JS linter config files" do
    js_linters_config_files.each { |file| assert_file(file) }
  end

  it "copies JS linter node modules in package.json" do
    expect(linter_modules_included_in_package_json.sort).to eq linter_modules_names.sort
  end
end

shared_examples "js_linters:disabled" do
  it "does not copy JS linter config files" do
    js_linters_config_files.each { |file| assert_no_file(file) }
  end

  it "does not copy JS linter node modules into package.json" do
    expect(linter_modules_included_in_package_json).to eq []
  end
end

def js_linters_config_files
  %w(client/.eslintrc
     client/.eslintignore
     client/.jscsrc)
end

# returns all matches for those linter modules found in dummy_for_generators/client/package.json
def linter_modules_included_in_package_json
  package_json_text = File.read(File.join(destination_root, "client/package.json"))
  linter_modules_names.reject { |module_name| !package_json_text.include?(module_name) }
end

# An array of strings representing the names of all javascript linter npm modules
def linter_modules_names
  %w(babel-eslint eslint eslint-config-airbnb eslint-config-shakacode eslint-plugin-react jscs)
end

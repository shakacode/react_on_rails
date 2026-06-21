# frozen_string_literal: true

require File.expand_path("../support/generator_spec_helper", __dir__)

describe DevTestsGenerator, type: :generator do
  destination File.expand_path("../dummy-for-generators", __dir__)

  context "without server rendering" do
    before(:all) do
      run_generator_test_with_args(%w[],
                                   package_json: true,
                                   spec: false)
    end

    it "copies rspec files" do
      %w[spec/spec_helper.rb
         spec/rails_helper.rb
         spec/simplecov_helper.rb
         eslint.config.mjs
         .rspec].each { |file| assert_file(file) }

      assert_no_file(".eslintrc")
    end

    it "copies the internal flat ESLint config" do
      assert_file("eslint.config.mjs") do |contents|
        expect(contents).to include("import js from '@eslint/js';")
        expect(contents).to include("import reactHooks from 'eslint-plugin-react-hooks';")
        expect(contents).to include("importPlugin.flatConfigs.recommended")
        expect(contents).to include("reactHooksRecommendedLatestConfigs")
        expect(contents).to include("__DEBUG_SERVER_ERRORS__: true")
        expect(contents).to include("'import/no-unresolved': 'off'")
        expect(contents).to include("'react/prop-types': 'off'")
      end
    end

    it "adds internal ESLint development dependencies" do
      assert_file("package.json") do |contents|
        dev_dependencies = JSON.parse(contents).fetch("devDependencies")

        expect(dev_dependencies).to include(
          "@eslint/js" => "^9.0.0",
          "eslint" => "^9.0.0",
          "eslint-config-prettier" => "^10.0.0",
          "eslint-plugin-import" => "^2.29.0",
          "eslint-plugin-react" => "^7.37.5",
          "eslint-plugin-react-hooks" => "^6.1.1",
          "globals" => "^16.0.0"
        )
      end
    end

    it "enables the default RSpec test asset hook in copied helpers" do
      assert_file("spec/rails_helper.rb") do |contents|
        expect(contents).to include("ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)")
        expect(contents).not_to include("# ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)")
      end

      assert_file("spec/spec_helper.rb") do |contents|
        expect(contents).to include("ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)")
        expect(contents).not_to include("# ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)")
      end
    end

    it "copies tests" do
      assert_file("spec/system/hello_world_spec.rb") do |contents|
        expect(contents).to include('describe "React SSR Demo", :js do')
        expect(contents).to include("expect(heading).to have_text(/(React|Redux) SSR Demo/)")
      end
    end

    it "changes package.json to use local react-on-rails version of module" do
      assert_file("package.json") do |contents|
        expect(contents).to match('"react-on-rails"')
        # Uses file: path to link to local package instead of yalc
        expect(contents).to match("file:../../../packages/react-on-rails")
      end
    end

    it "adds test-related gems to Gemfile" do
      assert_file("Gemfile") do |contents|
        expect(contents).to match("gem \"rspec-rails\", group: :test")
        expect(contents).to match("gem \"simplecov\", require: false, group: :test")
        # chromedriver-helper was removed as it's deprecated since 2019
        # Modern selenium-webdriver (4.x) handles driver management automatically
      end
    end
  end

  context "with server-rendering" do
    before(:all) do
      run_generator_test_with_args(%w[--example-server-rendering],
                                   package_json: true,
                                   spec: false,
                                   hello_world_file: true)
    end

    it "adds prerender for examples with example-server-rendering" do
      assert_file("app/views/hello_world/index.html.erb") do |contents|
        expect(contents).to match("prerender: true")
      end
    end
  end
end

# frozen_string_literal: true

require "json"

require_relative "../support/generator_spec_helper"
require_relative "../support/version_test_helpers"
describe InstallGenerator, type: :generator do
  include GeneratorSpec::TestCase

  destination File.expand_path("../dummy-for-generators", __dir__)

  def base_generator_fixture(options = {})
    ReactOnRails::Generators::BaseGenerator.new([], options, destination_root:)
  end

  def install_generator_fixture(options = {})
    described_class.new([], options, destination_root:)
  end

  def redux_generator_fixture(options = {})
    ReactOnRails::Generators::ReactWithReduxGenerator.new([], options, destination_root:)
  end

  def rsc_generator_fixture(options = {})
    ReactOnRails::Generators::RscGenerator.new([], options, destination_root:)
  end

  def gem_root_ci_workflow_path
    File.expand_path("../../../.github/workflows/ci.yml", __dir__)
  end

  def render_stock_webpack_template(template_path, options = {})
    base_generator_fixture(options).send(:rendered_template_for_cleanup, template_path)
  end

  def tailwind_dependency_requirements
    {
      "tailwindcss" => "^4.3.0",
      "@tailwindcss/postcss" => "^4.3.0",
      "postcss" => "^8.5.15",
      "postcss-loader" => "^8.2.1"
    }
  end

  def assert_rsc_dependency_requirements(dependencies)
    dependency_manager = ReactOnRails::Generators::JsDependencyManager
    rsc_react_range = dependency_manager::RSC_REACT_VERSION_RANGE

    expect_npm_dependency_to_satisfy("react", dependencies["react"], rsc_react_range)
    expect_npm_dependency_to_satisfy("react-dom", dependencies["react-dom"], rsc_react_range)
    expect(dependencies["react-on-rails-rsc"]).to eq(dependency_manager::RSC_PACKAGE_VERSION_PIN)
  end

  def assert_tailwind_dependencies
    assert_file "package.json" do |content|
      dependencies = JSON.parse(content).fetch("dependencies")

      tailwind_dependency_requirements.each do |name, version|
        expect_npm_dependency_to_satisfy(name, dependencies[name], version)
      end
    end
  end

  def expect_npm_dependency_to_satisfy(name, actual_version, expected_requirement)
    if actual_version.nil?
      raise RSpec::Expectations::ExpectationNotMetError,
            "expected #{name} dependency to be present and satisfy #{expected_requirement.inspect}"
    end

    if npm_range?(expected_requirement)
      return expect_npm_range_dependency_to_satisfy(actual_version, expected_requirement)
    end

    expect(actual_version).to eq(expected_requirement)
  rescue ArgumentError
    raise RSpec::Expectations::ExpectationNotMetError,
          "expected #{name} dependency #{actual_version.inspect} to satisfy #{expected_requirement.inspect}"
  end

  def npm_range?(expected_requirement)
    expected_requirement.start_with?("^", "~")
  end

  def expect_npm_range_dependency_to_satisfy(actual_version, expected_requirement)
    operator = expected_requirement[0]
    expected_floor = Gem::Version.new(expected_requirement[1..])
    actual = Gem::Version.new(actual_version.delete_prefix("^").delete_prefix("~"))

    expect(actual).to be >= expected_floor
    expect(actual).to be < npm_range_upper_bound(operator, expected_floor)
  end

  def npm_range_upper_bound(operator, version)
    return npm_caret_upper_bound(version) if operator == "^"

    npm_tilde_upper_bound(version)
  end

  def npm_caret_upper_bound(version)
    major, minor, patch = version.segments.values_at(0, 1, 2).map { |segment| segment || 0 }

    return Gem::Version.new("#{major + 1}.0.0") if major.positive?
    return Gem::Version.new("0.#{minor + 1}.0") if minor.positive?

    Gem::Version.new("0.0.#{patch + 1}")
  end

  def npm_tilde_upper_bound(version)
    major, minor = version.segments.values_at(0, 1).map { |segment| segment || 0 }

    return Gem::Version.new("#{major}.#{minor + 1}.0") if version.segments.length > 1

    Gem::Version.new("#{major + 1}.0.0")
  end

  def assert_tailwind_ssr_setup(config_dir:, extension:)
    assert_tailwind_dependencies
    assert_tailwind_stylesheet
    assert_tailwind_pack_entry
    assert_no_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.module.css"

    assert_tailwind_component(extension)
    assert_tailwind_bundler_config(config_dir)
    assert_tailwind_hello_world_view
    assert_tailwind_layout_owned_pack
  end

  def assert_tailwind_redux_setup(config_dir:, extension:)
    assert_tailwind_dependencies
    assert_tailwind_stylesheet
    assert_tailwind_pack_entry
    assert_no_file "app/javascript/src/HelloWorldApp/components/HelloWorld.module.css"

    assert_file "app/javascript/src/HelloWorldApp/ror_components/HelloWorldApp.client.#{extension}" do |content|
      expect(content).not_to include("application.css")
    end

    assert_file "app/javascript/src/HelloWorldApp/components/HelloWorld.#{extension}" do |content|
      expect(content).to include("React on Rails + Redux + Tailwind CSS")
      expect(content).to include("rounded-lg")
      expect(content).to include("focus:outline-hidden")
      expect(content).not_to include("HelloWorld.module.css")
      expect(content).not_to include("<form")
    end

    assert_tailwind_bundler_config(config_dir)
    assert_tailwind_layout_owned_pack
  end

  def assert_tailwind_component(extension)
    assert_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.client.#{extension}" do |content|
      expect(content).not_to include("application.css")
      expect(content).to include("React on Rails + Tailwind CSS")
      expect(content).to include("rounded-lg")
    end
  end

  def assert_tailwind_stylesheet(path: "app/javascript/stylesheets/application.css",
                                 source_directive: '@import "tailwindcss" source("../..");')
    assert_file path do |content|
      expect(content).to include("Tailwind v4 scans generated Rails app and Shakapacker source paths by default")
      expect(content).to include("add @source directives here")
      expect(content).to include('@source "../../../lib";')
      expect(content).to include('@source "../../../engines/my_engine/app";')
      expect(content).to include(source_directive)
    end
  end

  def assert_tailwind_pack_entry(path: "app/javascript/packs/react_on_rails_tailwind.js",
                                 import_path: "../stylesheets/application.css")
    assert_file path do |content|
      expect(content).to eq("import '#{import_path}';\n")
    end
  end

  def assert_tailwind_bundler_config(config_dir)
    assert_file "#{config_dir}/commonWebpackConfig.js" do |content|
      expect(content).to include("postcss-loader")
      expect(content).to include("@tailwindcss/postcss")
      expect(content).to include("addTailwindPostcssLoader")
      expect(content).to include("mergeTailwindPostcssLoader")
      expect(content).to include("plugin?.postcssPlugin")
      expect(content).to include("webpackConfig.module?.rules")
    end
  end

  def assert_tailwind_layout_owned_pack
    assert_file "app/views/layouts/react_on_rails_default.html.erb" do |content|
      expect_tailwind_pack_order(content)
      expect_generated_layout_head_tags(content)
      expect(content).to include("Tailwind is layout-owned")
      expect(content).not_to include("<!-- Empty pack tags")
    end
  end

  def expect_tailwind_pack_order(content)
    prepend_index = content.index('<% prepend_javascript_pack_tag "react_on_rails_tailwind" %>')
    stylesheet_index = content.index('<%= stylesheet_pack_tag "react_on_rails_tailwind", media: "all" %>')
    javascript_index = content.index("<%= javascript_pack_tag %>")

    expect(prepend_index).not_to be_nil
    expect(stylesheet_index).not_to be_nil
    expect(javascript_index).not_to be_nil
    expect(prepend_index).to be < stylesheet_index
    expect(stylesheet_index).to be < javascript_index
  end

  def expect_generated_layout_head_tags(content)
    expect(content).to include('<meta name="viewport" content="width=device-width,initial-scale=1">')
    expect(content).to include("<%= csrf_meta_tags %>")
    expect(content).to include("<%= csp_meta_tag %>")
  end

  def assert_tailwind_hello_world_view
    assert_file "app/views/hello_world/index.html.erb" do |content|
      expect(content).to include('react_component("HelloWorld", props: @hello_world_props, prerender: true)')
    end
  end

  def assert_tailwind_rsc_setup(config_dir:, extension:)
    assert_tailwind_dependencies
    assert_tailwind_stylesheet
    assert_tailwind_pack_entry

    assert_file "app/javascript/src/HelloServer/components/LikeButton.#{extension}" do |content|
      expect(content).not_to include("application.css")
      expect(content).to start_with("'use client';")
    end

    assert_tailwind_bundler_config(config_dir)
    assert_tailwind_layout_owned_pack
  end

  def simulate_managed_stock_webpack_files(options = {})
    # MANAGED_WEBPACK_FILE_TEMPLATES is private_constant; this fixture helper
    # intentionally introspects it so tests track managed-file coverage.
    managed_template_map = ReactOnRails::Generators::BaseGenerator.const_get(:MANAGED_WEBPACK_FILE_TEMPLATES)
    managed_template_map.each do |filename, template_path|
      simulate_existing_file("config/webpack/#{filename}", render_stock_webpack_template(template_path, options))
    end
  end

  def simulate_preinstalled_shakapacker(source_path:, source_entry_path:)
    simulate_existing_file("config/shakapacker.yml", <<~YAML)
      default: &default
        source_path: #{yaml_quoted_string(source_path)}
        source_entry_path: #{yaml_quoted_string(source_entry_path)}
        public_root_path: public
        public_output_path: packs
        cache_path: tmp/shakapacker
        webpack_compile_output: true
        shakapacker_precompile: true
        additional_paths: []
        cache_manifest: false
        assets_bundler: "webpack"

      development:
        <<: *default

      test:
        <<: *default
        compile: true

      production:
        <<: *default
    YAML
    # These files satisfy the generator's existing Shakapacker-install detection;
    # the custom path assertions below exercise config/shakapacker.yml.
    simulate_existing_file("bin/shakapacker", "")
    simulate_existing_file("bin/shakapacker-dev-server", "")
    simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
      const { generateWebpackConfig } = require('shakapacker')
      const webpackConfig = generateWebpackConfig()
      module.exports = webpackConfig
    JS
  end

  def yaml_quoted_string(value)
    # JSON strings are valid YAML scalars, so JSON.generate gives us safe quoting for free.
    JSON.generate(value.to_s)
  end

  # Reads the repo's own package.json packageManager pin and returns the version.
  # Anchoring on package.json (the user-visible source of truth) instead of
  # `const_get(:CI_PNPM_FALLBACK_VERSION)` keeps the assertion on observable surface
  # area and avoids reaching past `private_constant` from the spec.
  def repo_pinned_pnpm_version
    package_manager = JSON.parse(
      File.read(File.expand_path("../../../../package.json", __dir__))
    )["packageManager"]
    expect(package_manager).not_to(
      be_nil,
      "package.json must declare packageManager so CI_PNPM_FALLBACK_VERSION stays in sync"
    )
    match = package_manager.match(/\Apnpm@(?<version>\d+\.\d+\.\d+)(?:\+sha\d+\.[0-9a-f]+)?\z/)
    expect(match).not_to(
      be_nil,
      "package.json packageManager must declare a pnpm@<version> spec, got #{package_manager.inspect}"
    )
    match[:version]
  end

  describe "RSC managed-template cleanup rendering" do
    # Regression: serverWebpackConfig.js.tt / clientWebpackConfig.js.tt interpolate
    # `<%= rsc_plugin_class_name %>` / `<%= rsc_plugin_import_path %>` inside their `use_rsc?`
    # blocks. The cleanup re-render path (rendered_template_for_cleanup) evaluates templates
    # against the restricted TemplateRenderContext binding, so those helpers must be delegated
    # there. If they are not, RSC managed configs render as TEMPLATE_RENDER_FAILED and are
    # wrongly treated as non-removable (with a NameError warning printed during install).
    render_failed_sentinel = ReactOnRails::Generators::BaseGenerator.const_get(:TEMPLATE_RENDER_FAILED)

    %w[
      base/base/config/webpack/serverWebpackConfig.js.tt
      base/base/config/webpack/clientWebpackConfig.js.tt
    ].each do |template_path|
      basename = File.basename(template_path, ".tt")

      it "renders #{basename} for an RSC webpack project during cleanup" do
        rendered = render_stock_webpack_template(template_path, rsc: true, rspack: false)

        expect(rendered).not_to equal(render_failed_sentinel)
        expect(rendered).to include("RSCWebpackPlugin")
        expect(rendered).to include("react-on-rails-rsc/WebpackPlugin")
      end

      it "renders #{basename} for an RSC rspack project during cleanup" do
        rendered = render_stock_webpack_template(template_path, rsc: true, rspack: true)

        expect(rendered).not_to equal(render_failed_sentinel)
        expect(rendered).to include("RSCRspackPlugin")
        expect(rendered).to include("react-on-rails-rsc/RspackPlugin")
      end
    end
  end

  describe "Tailwind managed-template cleanup rendering" do
    render_failed_sentinel = ReactOnRails::Generators::BaseGenerator.const_get(:TEMPLATE_RENDER_FAILED)

    it "renders commonWebpackConfig.js for Tailwind during cleanup" do
      rendered = render_stock_webpack_template(
        "base/base/config/webpack/commonWebpackConfig.js.tt",
        tailwind: true
      )

      expect(rendered).not_to equal(render_failed_sentinel)
      expect(rendered).to include("@tailwindcss/postcss")
      expect(rendered).to include("addTailwindPostcssLoader")
      expect(rendered).to include("mergeTailwindPostcssLoader")
    end
  end

  describe "Redux generator policy" do
    it "hides the install --redux option from public help and usage text" do
      redux_option = described_class.class_options.fetch(:redux)

      expect(redux_option.hide).to be(true)
      expect(redux_option.aliases).to include("-R")

      usage_text = File.read(File.expand_path("../../../lib/generators/USAGE", __dir__))
      expect(usage_text).not_to include("--redux")
      expect(usage_text).not_to include("Redux (Optional)")
    end

    it "marks the base generator Redux option as internal legacy plumbing" do
      redux_option = ReactOnRails::Generators::BaseGenerator.class_options.fetch(:redux)

      expect(redux_option.hide).to be(true)
      expect(redux_option.aliases).to include("-R")
      expect(redux_option.description).to include("legacy")
    end
  end

  describe "manual generator fixtures" do
    it "keep CI workflow generation inside the generator spec destination" do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)

      Dir.chdir(File.expand_path("../../..", __dir__)) do
        install_generator_fixture(force: true).send(:add_ci_workflow)
      end

      assert_file ".github/workflows/ci.yml"
      expect(File).not_to exist(gem_root_ci_workflow_path)
    end
  end

  describe "agent guidance files" do
    # Exercise add_agent_files directly (like the CI-workflow fixture above) so the
    # idempotency/flag behavior is covered without running the full Shakapacker install.
    let(:agent_file_paths) do
      %w[AGENTS.md CLAUDE.md .cursor/rules/react-on-rails.mdc .github/copilot-instructions.md]
    end

    before { prepare_destination }

    def run_add_agent_files(options = {})
      generator = install_generator_fixture({ agent_files: true }.merge(options))
      Dir.chdir(destination_root) { generator.send(:add_agent_files) }
    end

    it "writes the consumer AGENTS.md and editor pointer files by default" do
      run_add_agent_files

      agent_file_paths.each { |relative_path| assert_file(relative_path) }

      assert_file "AGENTS.md" do |content|
        expect(content).to include("react_component")
        expect(content).to include("ror_components")
        expect(content).to include("react_on_rails:doctor FORMAT=json")
        expect(content).to include("`id`, `severity`, `message`, and `remediation.prompt`")
        expect(content).to include("Component '<Name>' Not Registered")
      end

      assert_file "CLAUDE.md" do |content|
        expect(content).to include("AGENTS.md")
      end
    end

    it "does not clobber agent files that already exist" do
      existing = "# Pre-existing project file — keep me\n"
      agent_file_paths.each { |relative_path| simulate_existing_file(relative_path, existing) }

      run_add_agent_files

      agent_file_paths.each do |relative_path|
        assert_file(relative_path) { |content| expect(content).to include("keep me") }
      end
    end

    it "skips all agent files when --no-agent-files is passed" do
      run_add_agent_files(agent_files: false)

      agent_file_paths.each { |relative_path| assert_no_file(relative_path) }
    end

    it "skips the editor pointer files when the app already has its own AGENTS.md" do
      simulate_existing_file("AGENTS.md", "# App's own AGENTS.md — keep me\n")

      run_add_agent_files

      # The existing AGENTS.md is left untouched and no pointer files are written, so we never
      # emit editor guidance referencing an AGENTS.md we did not author.
      assert_file("AGENTS.md") { |content| expect(content).to include("keep me") }
      %w[CLAUDE.md .cursor/rules/react-on-rails.mdc .github/copilot-instructions.md].each do |pointer|
        assert_no_file(pointer)
      end
    end
  end

  context "without args" do
    before(:all) { run_generator_test_with_args(%w[], package_json: true) }

    include_examples "base_generator", application_js: true
    include_examples "no_redux_generator"
    include_examples "scaffold_ci_and_scripts"

    it "sets DEFAULT_ROUTE to hello_world in bin/dev" do
      assert_file "bin/dev" do |content|
        expect(content).to include('DEFAULT_ROUTE = "hello_world"')
      end
    end

    it "creates the shakapacker watch wrapper and uses it in Procfiles" do
      assert_file "bin/shakapacker-watch" do |content|
        expect(content).to include('bin/shakapacker "$@" &')
        expect(content).to include("trap cleanup INT TERM")
      end

      assert_file "Procfile.dev" do |content|
        expect(content).to include("server-bundle: SERVER_BUNDLE_ONLY=true bin/shakapacker-watch --watch")
      end

      assert_file "Procfile.dev-static-assets" do |content|
        expect(content).to include("js: bin/shakapacker-watch --watch")
      end
    end

    it "installs appropriate transpiler dependencies based on Shakapacker version" do
      assert_file "package.json" do |content|
        package_json = JSON.parse(content)
        # This test verifies the generator adapts to the Shakapacker version in the current environment.
        # CI runs with both minimum (Shakapacker 8.x) and latest (Shakapacker 9.x) configurations,
        # so this test validates correct behavior for whichever version is installed.
        # SWC is the default transpiler for Shakapacker 9.3.0+; Babel is the default for older versions.
        swc_is_default = ReactOnRails::PackerUtils.shakapacker_version_requirement_met?("9.3.0")

        if swc_is_default
          expect(package_json["devDependencies"]).to include("@swc/core")
          expect(package_json["devDependencies"]).to include("swc-loader")
        else
          # For older Shakapacker versions, SWC is NOT installed by default
          # (Babel is the default, and babel.config.js requires @babel/preset-react)
          expect(package_json["devDependencies"]).not_to include("@swc/core")
          expect(package_json["devDependencies"]).to include("@babel/preset-react")
        end
      end
    end

    it "enables build_test_command by default" do
      assert_file "config/initializers/react_on_rails.rb" do |content|
        expect(content).to include(
          'config.build_test_command = "RAILS_ENV=test NODE_ENV=test bin/shakapacker-precompile-hook && ' \
          'SHAKAPACKER_SKIP_PRECOMPILE_HOOK=true RAILS_ENV=test NODE_ENV=test bin/shakapacker"'
        )
      end
    end

    it "sets shakapacker test compile to false by default" do
      assert_file "config/shakapacker.yml" do |content|
        expect(content).to match(/^test:.*?^\s+compile:\s*false/m)
      end
    end
  end

  context "with a pre-installed custom Shakapacker source root" do
    before(:all) do
      run_generator_test_with_args(%w[], package_json: true, force: false) do
        simulate_preinstalled_shakapacker(source_path: "client/app", source_entry_path: "entrypoints")
      end
    end

    it "generates the demo source and entrypoint under the configured Shakapacker paths" do
      assert_file "client/app/src/HelloWorld/ror_components/HelloWorld.client.jsx"
      assert_file "client/app/src/HelloWorld/ror_components/HelloWorld.server.jsx"
      assert_file "client/app/src/HelloWorld/ror_components/HelloWorld.module.css"
      assert_file "client/app/entrypoints/server-bundle.js"

      assert_no_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.client.jsx"
      assert_no_file "app/javascript/packs/server-bundle.js"
    end

    it "uses the configured source path in generated demo hints" do
      assert_file "app/views/hello_world/index.html.erb" do |content|
        expect(content).to include('<code class="path-hint">client/app/src/HelloWorld/</code>')
        expect(content).not_to include("app/javascript/src/HelloWorld/")
      end
    end
  end

  context "with a slash Shakapacker source entry path" do
    before(:all) do
      run_generator_test_with_args(%w[], package_json: true, force: false) do
        simulate_preinstalled_shakapacker(source_path: "client/app", source_entry_path: "/")
      end
    end

    it "generates entrypoints directly under the configured Shakapacker source path" do
      assert_file "client/app/server-bundle.js"
      assert_no_file "client/app/packs/server-bundle.js"
    end

    it "generates demo source files under the configured Shakapacker source path" do
      assert_file "client/app/src/HelloWorld/ror_components/HelloWorld.client.jsx"
      assert_file "client/app/src/HelloWorld/ror_components/HelloWorld.server.jsx"
      assert_file "client/app/src/HelloWorld/ror_components/HelloWorld.module.css"

      assert_no_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.client.jsx"
    end

    it "uses the configured source path in generated demo hints" do
      assert_file "app/views/hello_world/index.html.erb" do |content|
        expect(content).to include('<code class="path-hint">client/app/src/HelloWorld/</code>')
        expect(content).not_to include("app/javascript/src/HelloWorld/")
      end
    end
  end

  context "with --tailwind and a slash Shakapacker source entry path" do
    before(:all) do
      run_generator_test_with_args(%w[--tailwind], package_json: true, force: false) do
        simulate_preinstalled_shakapacker(source_path: "client/app", source_entry_path: "/")
      end
    end

    it "keeps Tailwind assets and imports anchored to the configured source path" do
      assert_file "client/app/server-bundle.js"
      assert_file "client/app/react_on_rails_tailwind.js", "import './stylesheets/application.css';\n"
      assert_file "client/app/stylesheets/application.css" do |content|
        expect(content).to include('@import "tailwindcss" source(none);')
        expect(content).to include('@source "..";')
        expect(content).to include('@source "../../../app";')
      end
      assert_file "client/app/src/HelloWorld/ror_components/HelloWorld.client.jsx" do |content|
        expect(content).not_to include("application.css")
      end

      assert_no_file "client/app/packs/server-bundle.js"
      assert_no_file "app/javascript/stylesheets/application.css"
      assert_no_file "app/javascript/packs/react_on_rails_tailwind.js"
    end
  end

  context "with --force and a pre-installed custom Shakapacker source root" do
    before(:all) do
      run_generator_test_with_args(%w[], package_json: true, force: true) do
        simulate_preinstalled_shakapacker(source_path: "client/app", source_entry_path: "entrypoints")
      end
    end

    it "generates base demo files from the config after --force overwrites the custom setup" do
      # --force causes copy_packer_config (which runs first) to overwrite the
      # pre-installed custom config with the stock config before
      # shakapacker_source_path memoizes. All path-dependent copies see the
      # stock app/javascript root.
      assert_file "app/javascript/packs/server-bundle.js"
      assert_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.client.jsx"
      assert_no_file "client/app/entrypoints/server-bundle.js"
      assert_no_file "client/app/src/HelloWorld/ror_components/HelloWorld.client.jsx"
    end

    it "uses the final Shakapacker source path in generated demo hints" do
      assert_file "app/views/hello_world/index.html.erb" do |content|
        expect(content).to include('<code class="path-hint">app/javascript/src/HelloWorld/</code>')
        expect(content).not_to include("client/app/src/HelloWorld/")
      end
    end
  end

  context "with --tailwind and a pre-installed custom Shakapacker source root" do
    before(:all) do
      run_generator_test_with_args(%w[--tailwind], package_json: true, force: false) do
        simulate_preinstalled_shakapacker(source_path: "client/app", source_entry_path: "entrypoints")
      end
    end

    it "generates Tailwind assets under the configured Shakapacker source path" do
      assert_file "client/app/entrypoints/react_on_rails_tailwind.js",
                  "import '../stylesheets/application.css';\n"
      assert_file "client/app/stylesheets/application.css" do |content|
        expect(content).to include('@import "tailwindcss" source(none);')
        expect(content).to include('@source "..";')
        expect(content).to include('@source "../../../app";')
      end
      assert_no_file "app/javascript/stylesheets/application.css"
      assert_no_file "app/javascript/packs/react_on_rails_tailwind.js"
    end

    it "keeps the generated client component free of global stylesheet imports" do
      assert_file "client/app/src/HelloWorld/ror_components/HelloWorld.client.jsx" do |content|
        expect(content).not_to include("application.css")
      end
    end
  end

  context "with --typescript and a pre-installed custom Shakapacker source root" do
    before(:all) do
      run_generator_test_with_args(%w[--typescript], package_json: true, force: false) do
        simulate_preinstalled_shakapacker(source_path: "client/app", source_entry_path: "entrypoints")
      end
    end

    it "generates TypeScript demo files under the configured Shakapacker source path" do
      assert_file "client/app/src/HelloWorld/ror_components/HelloWorld.client.tsx"
      assert_file "client/app/src/HelloWorld/ror_components/HelloWorld.server.tsx"

      assert_no_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.client.tsx"
    end

    it "points TypeScript support files at the configured Shakapacker source path" do
      assert_file "client/app/types/css-modules.d.ts"
      assert_no_file "app/javascript/types/css-modules.d.ts"

      assert_file "tsconfig.json" do |content|
        config = JSON.parse(content)
        expect(config["include"]).to include("client/app/**/*")
        expect(config["include"]).not_to include("app/javascript/**/*")
      end
    end
  end

  context "with --typescript --force and a pre-installed custom Shakapacker source root" do
    before(:all) do
      run_generator_test_with_args(%w[--typescript], package_json: true, force: true) do
        simulate_preinstalled_shakapacker(source_path: "client/app", source_entry_path: "entrypoints")
      end
    end

    it "points TypeScript support files at the overwritten Shakapacker source path" do
      assert_file "app/javascript/types/css-modules.d.ts"
      assert_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.client.tsx"
      assert_no_file "client/app/types/css-modules.d.ts"

      assert_file "tsconfig.json" do |content|
        config = JSON.parse(content)
        expect(config["include"]).to include("app/javascript/**/*")
        expect(config["include"]).not_to include("client/app/**/*")
      end
    end
  end

  context "with --rsc and a pre-installed custom Shakapacker source root" do
    before(:all) do
      run_generator_test_with_args(%w[--rsc --no-rspack], package_json: true, force: false) do
        simulate_preinstalled_shakapacker(source_path: "client/app", source_entry_path: "entrypoints")
      end
    end

    it "generates RSC demo files under the configured Shakapacker source path" do
      assert_file "client/app/src/HelloServer/ror_components/HelloServer.jsx"
      assert_file "client/app/src/HelloServer/components/HelloServer.jsx"
      assert_file "client/app/src/HelloServer/components/LikeButton.jsx"
      assert_file "client/app/entrypoints/server-bundle.js"
      assert_file "config/webpack/rscWebpackConfig.js"

      assert_no_file "app/javascript/src/HelloServer/ror_components/HelloServer.jsx"
      assert_no_file "app/javascript/packs/server-bundle.js"
    end

    it "uses the configured source path in generated RSC demo hints" do
      assert_file "app/views/hello_server/index.html.erb" do |content|
        expect(content).to include('<code class="path-hint">client/app/src/HelloServer/</code>')
        expect(content).not_to include("app/javascript/src/HelloServer/")
      end
    end
  end

  context "with --rsc and a slash Shakapacker source entry path" do
    before(:all) do
      run_generator_test_with_args(%w[--rsc --no-rspack], package_json: true, force: false) do
        simulate_preinstalled_shakapacker(source_path: "client/app", source_entry_path: "/")
      end
    end

    it "normalizes the RSC discovery registration entry path" do
      assert_file "client/app/server-bundle.js"
      assert_file "config/webpack/rscWebpackConfig.js" do |content|
        expect(content).to include("const sourceEntryPath = config.source_entry_path === '/' ? '' :")
        expect(content).to include("sourceEntryPath,\n    '../generated/server-component-registration-entry.js'")
      end
    end
  end

  context "with --rsc --tailwind and a pre-installed custom Shakapacker source root" do
    before(:all) do
      run_generator_test_with_args(%w[--rsc --tailwind --no-rspack], package_json: true, force: false) do
        simulate_preinstalled_shakapacker(source_path: "client/app", source_entry_path: "entrypoints")
      end
    end

    it "keeps Tailwind owned by the layout pack instead of the generated RSC client component" do
      assert_file "client/app/entrypoints/react_on_rails_tailwind.js",
                  "import '../stylesheets/application.css';\n"
      assert_file "client/app/stylesheets/application.css" do |content|
        expect(content).to include('@import "tailwindcss" source(none);')
        expect(content).to include('@source "..";')
        expect(content).to include('@source "../../../app";')
      end
      assert_file "client/app/src/HelloServer/components/LikeButton.jsx" do |content|
        expect(content).not_to include("application.css")
      end
    end
  end

  context "with --new-app" do
    before(:all) { run_generator_test_with_args(%w[--new-app], package_json: true) }

    it "creates a root landing page" do
      assert_file "config/routes.rb" do |content|
        expect(content).to include('root to: "home#index"')
      end
      assert_file "app/controllers/home_controller.rb" do |content|
        expect(content).to include("protect_from_forgery with: :exception")
        expect(content).to include("def index; end")
      end
      assert_file "app/views/home/index.html.erb" do |content|
        expect(content).to include("is ready.")
        expect(content).to include("/hello_world")
        expect(content).to include("Compare OSS and Pro")
        expect(content).to include("https://github.com/shakacode/react-on-rails-demo-marketplace-rsc")
      end
    end

    it "uses the root path and one-time browser opening in bin/dev" do
      assert_file "bin/dev" do |content|
        expect(content).to include('DEFAULT_ROUTE = "/"')
        expect(content).to include("AUTO_OPEN_BROWSER_ONCE = true")
        expect(content).to include("--open-browser-once")
      end
    end

    it "adds a return link from the SSR demo to the landing page" do
      assert_file "app/views/hello_world/index.html.erb" do |content|
        expect(content).to include("Return to the generated home page")
      end
    end
  end

  context "when --new-app config/routes.rb does not exist" do
    let(:generator) { base_generator_fixture(new_app: true) }

    before do
      prepare_destination
      simulate_existing_rails_files(gitignore: false, spec: false)
      FileUtils.rm_f(File.join(destination_root, "config/routes.rb"))
      allow(generator).to receive(:say_status)
    end

    it "warns instead of raising when config/routes.rb is missing" do
      Dir.chdir(destination_root) do
        generator.send(:add_root_route)
      end

      expect(generator)
        .to have_received(:say_status)
        .with(:warn, "Could not inject root route; config/routes.rb was not found", :yellow)
    end
  end

  context "when --new-app routes.rb is in an unexpected format" do
    let(:generator) { base_generator_fixture(new_app: true) }

    before do
      prepare_destination
      simulate_existing_rails_files(gitignore: false, spec: false)
      simulate_existing_file("config/routes.rb", "draw_routes do\nend\n")
      allow(generator).to receive(:say_status)
    end

    it "warns instead of silently skipping the root route injection" do
      Dir.chdir(destination_root) do
        generator.send(:add_root_route)
      end

      expect(generator)
        .to have_received(:say_status)
        .with(:warn, "Could not inject root route; config/routes.rb format was unexpected", :yellow)
    end
  end

  context "when --new-app routes.rb uses CRLF line endings" do
    let(:generator) { base_generator_fixture(new_app: true) }

    before do
      prepare_destination
      simulate_existing_rails_files(gitignore: false, spec: false)
      simulate_existing_file("config/routes.rb", "Rails.application.routes.draw do\r\nend\r\n")
      allow(generator).to receive(:say_status)
    end

    it "injects the root route without warning" do
      Dir.chdir(destination_root) do
        generator.send(:add_root_route)
      end

      expect(generator)
        .not_to have_received(:say_status)
        .with(:warn, "Could not inject root route; config/routes.rb format was unexpected", :yellow)
      expect(File.read(File.join(destination_root, "config/routes.rb"))).to include('root to: "home#index"')
    end
  end

  context "when --new-app root route injection runs in pretend mode" do
    let(:generator) { base_generator_fixture(new_app: true, pretend: true) }

    before do
      prepare_destination
      simulate_existing_rails_files(gitignore: false, spec: false)
      allow(generator).to receive(:say_status)
    end

    it "does not emit a false warning after the pretend injection" do
      Dir.chdir(destination_root) do
        generator.send(:add_root_route)
      end

      expect(generator)
        .not_to have_received(:say_status)
        .with(:warn, "Could not inject root route; config/routes.rb format was unexpected", :yellow)
    end
  end

  context "with --redux" do
    before(:all) { run_generator_test_with_args(%w[--redux], package_json: true) }

    include_examples "base_generator_common", application_js: true
    include_examples "react_with_redux_generator"
  end

  context "with legacy -R alias" do
    before(:all) { run_generator_test_with_args(%w[-R], package_json: true) }

    include_examples "base_generator_common", application_js: true
    include_examples "react_with_redux_generator"
  end

  context "with --redux --typescript" do
    before(:all) { run_generator_test_with_args(%w[--redux --typescript], package_json: true) }

    include_examples "base_generator_common", application_js: true
    include_examples "react_with_redux_generator", typescript: true

    it "keeps the hidden legacy Redux TypeScript template path covered" do
      %w[
        app/javascript/src/HelloWorldApp/actions/helloWorldActionCreators.ts
        app/javascript/src/HelloWorldApp/containers/HelloWorldContainer.ts
        app/javascript/src/HelloWorldApp/constants/helloWorldConstants.ts
        app/javascript/src/HelloWorldApp/reducers/helloWorldReducer.ts
        app/javascript/src/HelloWorldApp/store/helloWorldStore.ts
        app/javascript/src/HelloWorldApp/ror_components/HelloWorldApp.client.tsx
        app/javascript/src/HelloWorldApp/ror_components/HelloWorldApp.server.tsx
        app/javascript/src/HelloWorldApp/components/HelloWorld.tsx
      ].each { |file| assert_file(file) }

      assert_file "app/javascript/src/HelloWorldApp/components/HelloWorld.tsx" do |content|
        expect(content).to match(/type HelloWorldProps = PropsFromRedux/)
        expect(content).to match(/React\.FC<HelloWorldProps>/)
      end

      assert_file "app/javascript/src/HelloWorldApp/ror_components/HelloWorldApp.client.tsx" do |content|
        expect(content).to match(/interface HelloWorldAppProps/)
        expect(content).to match(/FC<HelloWorldAppProps>/)
      end
    end
  end

  context "with --redux --tailwind --typescript" do
    before(:all) { run_generator_test_with_args(%w[--redux --tailwind --typescript], package_json: true) }

    include_examples "base_generator_common", application_js: true, tailwind: true

    it "wires Tailwind into the Redux SSR example" do
      assert_tailwind_redux_setup(config_dir: "config/rspack", extension: "tsx")
    end
  end

  context "with --typescript" do
    before(:all) { run_generator_test_with_args(%w[--typescript], package_json: true) }

    include_examples "base_generator_common", application_js: true
    include_examples "no_redux_generator"

    it "creates TypeScript component files with .tsx extension" do
      assert_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.client.tsx"
      assert_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.server.tsx"
    end

    it "creates tsconfig.json file" do
      assert_file "tsconfig.json" do |content|
        config = JSON.parse(content)
        expect(config["compilerOptions"]["jsx"]).to eq("react-jsx")
        expect(config["compilerOptions"]["strict"]).to be true
        expect(config["include"]).to include("app/javascript/**/*")
      end
    end

    it "TypeScript component includes proper typing" do
      assert_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.client.tsx" do |content|
        expect(content).to match(/interface HelloWorldProps/)
        expect(content).to match(/React\.FC<HelloWorldProps>/)
        expect(content).to match(/onChange=\{.*e.*=>.*setName\(e\.target\.value\).*\}/)
      end
    end
  end

  describe "#expect_npm_dependency_to_satisfy" do
    it "uses npm caret upper bounds" do
      expect { expect_npm_dependency_to_satisfy("example", "^4.3.1", "^4.3.0") }.not_to raise_error
      expect { expect_npm_dependency_to_satisfy("example", "^5.0.0", "^4.3.0") }
        .to raise_error(RSpec::Expectations::ExpectationNotMetError)
      expect { expect_npm_dependency_to_satisfy("example", "^0.1.9", "^0.1.0") }.not_to raise_error
      expect { expect_npm_dependency_to_satisfy("example", "^0.2.0", "^0.1.0") }
        .to raise_error(RSpec::Expectations::ExpectationNotMetError)
      expect { expect_npm_dependency_to_satisfy("example", "^0.0.4", "^0.0.3") }
        .to raise_error(RSpec::Expectations::ExpectationNotMetError)
    end
  end

  describe "#copy_or_update_tailwind_layout" do
    let(:base_generator) { base_generator_fixture(tailwind: true) }
    let(:layout_path) { "app/views/layouts/react_on_rails_default.html.erb" }

    before do
      prepare_destination
    end

    it "updates the recognizable generated default layout" do
      simulate_existing_layout("react_on_rails_default", <<~ERB)
        <!DOCTYPE html>
        <html>
          <head>
            <title>React on Rails</title>
            <%= csrf_meta_tags %>

            <!-- Empty pack tags - React on Rails injects component CSS/JS here -->
            <%= stylesheet_pack_tag %>
            <%= javascript_pack_tag %>
          </head>
          <body>
            <%= yield %>
          </body>
        </html>
      ERB

      base_generator.send(:copy_or_update_tailwind_layout)

      assert_file layout_path do |content|
        expect(content).to include('<meta name="viewport" content="width=device-width,initial-scale=1">')
        expect(content).to include("<%= csrf_meta_tags %>")
        expect(content).to include("<%= csp_meta_tag %>")
        expect(content).to include('<% prepend_javascript_pack_tag "react_on_rails_tailwind" %>')
        expect(content).to include('<%= stylesheet_pack_tag "react_on_rails_tailwind", media: "all" %>')
        expect(content).to include("<%= javascript_pack_tag %>")
        expect(content).not_to include("<!-- Empty pack tags")
      end
    end

    it "announces generated viewport and CSP tag insertions" do
      simulate_existing_layout("react_on_rails_default", <<~ERB)
        <!DOCTYPE html>
        <html>
          <head>
            <title>React on Rails</title>
            <%= csrf_meta_tags %>

            <!-- Empty pack tags - React on Rails injects component CSS/JS here -->
            <%= stylesheet_pack_tag %>
            <%= javascript_pack_tag %>
          </head>
          <body>
            <%= yield %>
          </body>
        </html>
      ERB
      allow(base_generator).to receive(:say_status).and_call_original

      base_generator.send(:copy_or_update_tailwind_layout)

      expect(base_generator).to have_received(:say_status)
        .with(:insert, "Added viewport meta to #{layout_path}", :green)
      expect(base_generator).to have_received(:say_status)
        .with(:insert, "Added csp_meta_tag to #{layout_path}", :green)
    end

    it "adds the generated viewport tag when only the default title was customized" do
      simulate_existing_layout("react_on_rails_default", <<~ERB)
        <!DOCTYPE html>
        <html>
          <head>
            <title>Custom app</title>
            <%= csrf_meta_tags %>

            <!-- Empty pack tags - React on Rails injects component CSS/JS here -->
            <%= stylesheet_pack_tag %>
            <%= javascript_pack_tag %>
          </head>
          <body>
            <%= yield %>
          </body>
        </html>
      ERB

      base_generator.send(:copy_or_update_tailwind_layout)

      assert_file layout_path do |content|
        viewport_index = content.index('<meta name="viewport" content="width=device-width,initial-scale=1">')
        csrf_index = content.index("<%= csrf_meta_tags %>")

        expect(viewport_index).to be < csrf_index
        expect(content).to include("<%= csp_meta_tag %>")
        expect(content).to include('<% prepend_javascript_pack_tag "react_on_rails_tailwind" %>')
      end
    end

    it "does not duplicate an existing viewport tag when name is not the first attribute" do
      simulate_existing_layout("react_on_rails_default", <<~ERB)
        <!DOCTYPE html>
        <html>
          <head>
            <title>React on Rails</title>
            <meta content="width=device-width,initial-scale=1" name="viewport">
            <%= csrf_meta_tags %>

            <!-- Empty pack tags - React on Rails injects component CSS/JS here -->
            <%= stylesheet_pack_tag %>
            <%= javascript_pack_tag %>
          </head>
          <body>
            <%= yield %>
          </body>
        </html>
      ERB

      base_generator.send(:copy_or_update_tailwind_layout)

      assert_file layout_path do |content|
        expect(content.scan(/\bname=["']viewport["']/).size).to eq(1)
        expect(content).to include('<meta content="width=device-width,initial-scale=1" name="viewport">')
        expect(content).to include('<% prepend_javascript_pack_tag "react_on_rails_tailwind" %>')
      end
    end

    it "warns when the generated layout has no viewport insertion anchor" do
      simulate_existing_layout("react_on_rails_default", <<~ERB)
        <!DOCTYPE html>
        <html>
          <head>
            <title>Custom app</title>

            <!-- Empty pack tags - React on Rails injects component CSS/JS here -->
            <%= stylesheet_pack_tag %>
            <%= javascript_pack_tag %>
          </head>
          <body>
            <%= yield %>
          </body>
        </html>
      ERB
      allow(base_generator).to receive(:say_status).and_call_original

      base_generator.send(:copy_or_update_tailwind_layout)

      expect(base_generator).to have_received(:say_status)
        .with(
          :warning,
          include("Could not insert viewport meta into #{layout_path}: no title or csrf_meta_tags anchor found"),
          :yellow
        )
      expect(base_generator).to have_received(:say_status)
        .with(
          :warning,
          include("Could not insert csp_meta_tag into #{layout_path}: no csrf_meta_tags anchor found"),
          :yellow
        )
      assert_file layout_path do |content|
        expect(content).not_to include('<meta name="viewport" content="width=device-width,initial-scale=1">')
        expect(content).not_to include("<%= csp_meta_tag %>")
        expect(content).to include('<% prepend_javascript_pack_tag "react_on_rails_tailwind" %>')
      end
    end

    it "updates the generated default layout when helper indentation differs" do
      simulate_existing_layout("react_on_rails_default", <<~ERB)
        <!DOCTYPE html>
        <html>
          <head>
            <title>React on Rails</title>
            <%= csrf_meta_tags %>

            <!-- Empty pack tags - React on Rails injects component CSS/JS here -->
        \t<%= stylesheet_pack_tag %>
              <%= javascript_pack_tag %>
          </head>
          <body>
            <%= yield %>
          </body>
        </html>
      ERB

      base_generator.send(:copy_or_update_tailwind_layout)

      assert_file layout_path do |content|
        expect(content).to include('<% prepend_javascript_pack_tag "react_on_rails_tailwind" %>')
        expect(content).to include('<%= stylesheet_pack_tag "react_on_rails_tailwind", media: "all" %>')
        expect(content).to include("<%= javascript_pack_tag %>")
        expect(content).not_to include("<!-- Empty pack tags")
      end
    end

    it "does not update the recognizable generated default layout in --pretend mode" do
      original_layout = <<~ERB
        <!DOCTYPE html>
        <html>
          <head>
            <!-- Empty pack tags - React on Rails injects component CSS/JS here -->
            <%= stylesheet_pack_tag %>
            <%= javascript_pack_tag %>
          </head>
          <body>
            <%= yield %>
          </body>
        </html>
      ERB
      pretend_generator = base_generator_fixture(tailwind: true, pretend: true)
      simulate_existing_layout("react_on_rails_default", original_layout)
      allow(pretend_generator).to receive(:say_status)

      pretend_generator.send(:copy_or_update_tailwind_layout)

      expect(pretend_generator).to have_received(:say_status)
        .with(:pretend, "Would update #{layout_path} to link react_on_rails_tailwind", :yellow)
      assert_file layout_path do |content|
        expect(content).to eq(original_layout)
      end
    end

    it "reports a pretend manual step instead of warning when a customized layout needs Tailwind wiring" do
      original_layout = <<~ERB
        <!DOCTYPE html>
        <html>
          <head>
            <%= stylesheet_pack_tag "application" %>
            <%= javascript_pack_tag "application" %>
          </head>
          <body>
            <%= yield %>
          </body>
        </html>
      ERB
      pretend_generator = base_generator_fixture(tailwind: true, pretend: true)
      simulate_existing_layout("react_on_rails_default", original_layout)
      allow(pretend_generator).to receive(:say_status)
      allow(pretend_generator).to receive(:say)

      pretend_generator.send(:copy_or_update_tailwind_layout)

      expect(pretend_generator).to have_received(:say_status)
        .with(
          :pretend,
          "#{layout_path} is customized and would need the Tailwind pack-tag block added manually",
          :yellow
        )
      expect(pretend_generator).not_to have_received(:say)
      assert_file layout_path do |content|
        expect(content).to eq(original_layout)
      end
    end

    it "warns instead of rewriting layouts without the generated pack-tag comment" do
      original_layout = <<~ERB
        <!DOCTYPE html>
        <html>
          <head>
            <!-- TODO: add react_on_rails_tailwind when Tailwind is enabled -->
            <%= stylesheet_pack_tag %>
            <%= javascript_pack_tag %>
          </head>
          <body>
            <%= yield %>
          </body>
        </html>
      ERB
      simulate_existing_layout("react_on_rails_default", original_layout)
      allow(base_generator).to receive(:say_status)
      allow(base_generator).to receive(:say)

      base_generator.send(:copy_or_update_tailwind_layout)

      expect(base_generator).to have_received(:say_status)
        .with(:warning, "Could not update #{layout_path}: layout is customized.", :yellow)
      expect(base_generator).to have_received(:say)
        .with(include("preserving any existing app-specific pack tags"), :yellow)
      expect(base_generator).to have_received(:say)
        .with(include('  <% prepend_javascript_pack_tag "react_on_rails_tailwind" %>'), :yellow)
      assert_file layout_path do |content|
        expect(content).to eq(original_layout)
      end
    end

    it "warns instead of skipping Tailwind pack tags that only appear inside an HTML comment" do
      original_layout = <<~ERB
        <!DOCTYPE html>
        <html>
          <head>
            <!--
            <% prepend_javascript_pack_tag "react_on_rails_tailwind" %>
            <%= stylesheet_pack_tag "react_on_rails_tailwind", media: "all" %>
            <%= javascript_pack_tag %>
            -->
          </head>
          <body>
            <%= yield %>
          </body>
        </html>
      ERB
      simulate_existing_layout("react_on_rails_default", original_layout)
      allow(base_generator).to receive(:say_status)
      allow(base_generator).to receive(:say)

      base_generator.send(:copy_or_update_tailwind_layout)

      expect(base_generator).to have_received(:say_status)
        .with(:warning, "Could not update #{layout_path}: layout is customized.", :yellow)
      expect(base_generator).to have_received(:say)
        .with(include("preserving any existing app-specific pack tags"), :yellow)
      assert_file layout_path do |content|
        expect(content).to eq(original_layout)
      end
    end

    it "warns instead of skipping Tailwind pack tags inside HTML comments that contain double dashes" do
      original_layout = <<~ERB
        <!DOCTYPE html>
        <html>
          <head>
            <!-- disabled -- historical Tailwind block
            <% prepend_javascript_pack_tag "react_on_rails_tailwind" %>
            <%= stylesheet_pack_tag "react_on_rails_tailwind", media: "all" %>
            <%= javascript_pack_tag %>
            -->
          </head>
          <body>
            <%= yield %>
          </body>
        </html>
      ERB
      simulate_existing_layout("react_on_rails_default", original_layout)
      allow(base_generator).to receive(:say_status)
      allow(base_generator).to receive(:say)

      base_generator.send(:copy_or_update_tailwind_layout)

      expect(base_generator).to have_received(:say_status)
        .with(:warning, "Could not update #{layout_path}: layout is customized.", :yellow)
      expect(base_generator).to have_received(:say)
        .with(include("preserving any existing app-specific pack tags"), :yellow)
      assert_file layout_path do |content|
        expect(content).to eq(original_layout)
      end
    end

    it "warns instead of skipping Tailwind pack tags inside triple-dash HTML comments" do
      original_layout = <<~ERB
        <!DOCTYPE html>
        <html>
          <head>
            <!--
            <% prepend_javascript_pack_tag "react_on_rails_tailwind" %>
            <%= stylesheet_pack_tag "react_on_rails_tailwind", media: "all" %>
            <%= javascript_pack_tag %>
            --->
          </head>
          <body>
            <%= yield %>
          </body>
        </html>
      ERB
      simulate_existing_layout("react_on_rails_default", original_layout)
      allow(base_generator).to receive(:say_status)
      allow(base_generator).to receive(:say)

      base_generator.send(:copy_or_update_tailwind_layout)

      expect(base_generator).to have_received(:say_status)
        .with(:warning, "Could not update #{layout_path}: layout is customized.", :yellow)
      expect(base_generator).to have_received(:say)
        .with(include("preserving any existing app-specific pack tags"), :yellow)
      assert_file layout_path do |content|
        expect(content).to eq(original_layout)
      end
    end

    it "warns instead of skipping Tailwind pack tags that only appear inside ERB comments" do
      original_layout = <<~ERB
        <!DOCTYPE html>
        <html>
          <head>
            <%# prepend_javascript_pack_tag "react_on_rails_tailwind" %>
            <%#= stylesheet_pack_tag "react_on_rails_tailwind", media: "all" %>
            <%#= javascript_pack_tag %>
          </head>
          <body>
            <%= yield %>
          </body>
        </html>
      ERB
      simulate_existing_layout("react_on_rails_default", original_layout)
      allow(base_generator).to receive(:say_status)
      allow(base_generator).to receive(:say)

      base_generator.send(:copy_or_update_tailwind_layout)

      expect(base_generator).to have_received(:say_status)
        .with(:warning, "Could not update #{layout_path}: layout is customized.", :yellow)
      expect(base_generator).to have_received(:say)
        .with(include("preserving any existing app-specific pack tags"), :yellow)
      assert_file layout_path do |content|
        expect(content).to eq(original_layout)
      end
    end

    it "warns instead of skipping Tailwind pack tags stitched together by HTML comments" do
      original_layout = <<~ERB
        <!DOCTYPE html>
        <html>
          <head>
            <% pre<!-- hidden -->pend_javascript_pack_tag "react_on_rails_tailwind" %>
            <%= stylesheet_pack_tag "react_on_rails_tailwind", media: "all" %>
            <%= javascript_pack_tag %>
          </head>
          <body>
            <%= yield %>
          </body>
        </html>
      ERB
      simulate_existing_layout("react_on_rails_default", original_layout)
      allow(base_generator).to receive(:say_status)
      allow(base_generator).to receive(:say)

      base_generator.send(:copy_or_update_tailwind_layout)

      expect(base_generator).to have_received(:say_status)
        .with(:warning, "Could not update #{layout_path}: layout is customized.", :yellow)
      expect(base_generator).to have_received(:say)
        .with(include("preserving any existing app-specific pack tags"), :yellow)
      assert_file layout_path do |content|
        expect(content).to eq(original_layout)
      end
    end

    it "warns instead of skipping Tailwind pack tags that are not a contiguous helper block" do
      original_layout = <<~ERB
        <!DOCTYPE html>
        <html>
          <head>
            <% prepend_javascript_pack_tag "react_on_rails_tailwind" %>
            <meta name="theme-color" content="#ffffff">
            <%= stylesheet_pack_tag "react_on_rails_tailwind", media: "all" %>
            <%= javascript_pack_tag %>
          </head>
          <body>
            <%= yield %>
          </body>
        </html>
      ERB
      simulate_existing_layout("react_on_rails_default", original_layout)
      allow(base_generator).to receive(:say_status)
      allow(base_generator).to receive(:say)

      base_generator.send(:copy_or_update_tailwind_layout)

      expect(base_generator).to have_received(:say_status)
        .with(:warning, "Could not update #{layout_path}: layout is customized.", :yellow)
      expect(base_generator).to have_received(:say)
        .with(include("preserving any existing app-specific pack tags"), :yellow)
      assert_file layout_path do |content|
        expect(content).to eq(original_layout)
      end
    end

    it "skips Tailwind layouts that use keyword options and blank lines in the helper block" do
      original_layout = <<~ERB
        <!DOCTYPE html>
        <html>
          <head>
            <% prepend_javascript_pack_tag "react_on_rails_tailwind" %>

            <%= stylesheet_pack_tag "react_on_rails_tailwind", media: "all" %>

            <%= javascript_pack_tag defer: true %>
          </head>
          <body>
            <%= yield %>
          </body>
        </html>
      ERB
      simulate_existing_layout("react_on_rails_default", original_layout)
      allow(base_generator).to receive(:say_status)
      allow(base_generator).to receive(:say)

      base_generator.send(:copy_or_update_tailwind_layout)

      expect(base_generator).to have_received(:say_status)
        .with(:skip, "#{layout_path} already links react_on_rails_tailwind", :yellow)
      expect(base_generator).not_to have_received(:say)
      assert_file layout_path do |content|
        expect(content).to eq(original_layout)
      end
    end

    it "skips Tailwind layouts that use an empty-parentheses JavaScript pack flush" do
      original_layout = <<~ERB
        <!DOCTYPE html>
        <html>
          <head>
            <% prepend_javascript_pack_tag "react_on_rails_tailwind" %>
            <%= stylesheet_pack_tag "react_on_rails_tailwind", media: "all" %>
            <%= javascript_pack_tag() %>
          </head>
          <body>
            <%= yield %>
          </body>
        </html>
      ERB
      simulate_existing_layout("react_on_rails_default", original_layout)
      allow(base_generator).to receive(:say_status)
      allow(base_generator).to receive(:say)

      base_generator.send(:copy_or_update_tailwind_layout)

      expect(base_generator).to have_received(:say_status)
        .with(:skip, "#{layout_path} already links react_on_rails_tailwind", :yellow)
      expect(base_generator).not_to have_received(:say)
      assert_file layout_path do |content|
        expect(content).to eq(original_layout)
      end
    end

    it "warns instead of skipping Tailwind layouts without a JavaScript pack flush" do
      original_layout = <<~ERB
        <!DOCTYPE html>
        <html>
          <head>
            <% prepend_javascript_pack_tag "react_on_rails_tailwind" %>
            <%= stylesheet_pack_tag "react_on_rails_tailwind", media: "all" %>
          </head>
          <body>
            <%= yield %>
          </body>
        </html>
      ERB
      simulate_existing_layout("react_on_rails_default", original_layout)
      allow(base_generator).to receive(:say_status)
      allow(base_generator).to receive(:say)

      base_generator.send(:copy_or_update_tailwind_layout)

      expect(base_generator).to have_received(:say_status)
        .with(:warning, "Could not update #{layout_path}: layout is customized.", :yellow)
      expect(base_generator).to have_received(:say)
        .with(include("preserving any existing app-specific pack tags"), :yellow)
      assert_file layout_path do |content|
        expect(content).to eq(original_layout)
      end
    end

    it "warns instead of accepting a named JavaScript pack tag as the generated pack flush" do
      original_layout = <<~ERB
        <!DOCTYPE html>
        <html>
          <head>
            <% prepend_javascript_pack_tag "react_on_rails_tailwind" %>
            <%= stylesheet_pack_tag "react_on_rails_tailwind", media: "all" %>
            <%= javascript_pack_tag "application" %>
          </head>
          <body>
            <%= yield %>
          </body>
        </html>
      ERB
      simulate_existing_layout("react_on_rails_default", original_layout)
      allow(base_generator).to receive(:say_status)
      allow(base_generator).to receive(:say)

      base_generator.send(:copy_or_update_tailwind_layout)

      expect(base_generator).to have_received(:say_status)
        .with(:warning, "Could not update #{layout_path}: layout is customized.", :yellow)
      expect(base_generator).to have_received(:say)
        .with(include("preserving any existing app-specific pack tags"), :yellow)
      assert_file layout_path do |content|
        expect(content).to eq(original_layout)
      end
    end

    it "does not rewrite customized layouts without --force" do
      original_layout = <<~ERB
        <!DOCTYPE html>
        <html>
          <head>
            <%= stylesheet_pack_tag "application" %>
            <%= javascript_pack_tag "application" %>
          </head>
          <body>
            <%= yield %>
          </body>
        </html>
      ERB
      simulate_existing_layout("react_on_rails_default", original_layout)

      base_generator.send(:copy_or_update_tailwind_layout)

      assert_file layout_path do |content|
        expect(content).to eq(original_layout)
      end
    end

    it "does not rewrite existing layouts in --skip mode" do
      original_layout = <<~ERB
        <!DOCTYPE html>
        <html>
          <head>
            <!-- Empty pack tags - React on Rails injects component CSS/JS here -->
            <%= stylesheet_pack_tag %>
            <%= javascript_pack_tag %>
          </head>
          <body>
            <%= yield %>
          </body>
        </html>
      ERB
      simulate_existing_layout("react_on_rails_default", original_layout)
      skip_generator = base_generator_fixture(tailwind: true, skip: true)
      allow(skip_generator).to receive(:say_status)
      allow(skip_generator).to receive(:say)

      skip_generator.send(:copy_or_update_tailwind_layout)

      expect(skip_generator).to have_received(:say_status)
        .with(:skip, "#{layout_path} exists and was not updated (--skip)", :yellow)
      expect(skip_generator).not_to have_received(:say)
      assert_file layout_path do |content|
        expect(content).to eq(original_layout)
      end
    end

    it "warns when --skip leaves the existing HelloWorldController default layout without Tailwind tags" do
      skip_generator = base_generator_fixture(tailwind: true, skip: true)
      simulate_existing_file("app/controllers/application_controller.rb", <<~RUBY)
        class ApplicationController < ActionController::Base
          layout "react_on_rails_default"
        end
      RUBY
      simulate_existing_file("app/controllers/hello_world_controller.rb", <<~RUBY)
        class HelloWorldController < ApplicationController
          def index
          end
        end
      RUBY
      simulate_existing_layout("react_on_rails_default", <<~ERB)
        <!DOCTYPE html>
        <html>
          <head>
            <%= stylesheet_pack_tag "application" %>
            <%= javascript_pack_tag "application" %>
          </head>
          <body>
            <%= yield %>
          </body>
        </html>
      ERB
      GeneratorMessages.clear

      skip_generator.send(:warn_existing_hello_world_tailwind_layout)

      warning_text = GeneratorMessages.messages.join("\n")
      expect(warning_text).to include(
        "app/controllers/hello_world_controller.rb may not use the Tailwind-aware React on Rails layout."
      )
      expect(warning_text).to include("app/views/layouts/react_on_rails_default.html.erb")
    end

    it "warns when the existing HelloWorldController renders through a non-Tailwind layout" do
      simulate_existing_file("app/controllers/hello_world_controller.rb", <<~RUBY)
        class HelloWorldController < ApplicationController
          layout "hello_world"

          def index
          end
        end
      RUBY
      simulate_named_pack_tag_layout("hello_world")
      allow(base_generator).to receive(:say_status)
      allow(base_generator).to receive(:say)
      GeneratorMessages.clear

      base_generator.send(:warn_existing_hello_world_tailwind_layout)

      warning_text = GeneratorMessages.messages.join("\n")
      expect(warning_text).to include(
        "app/controllers/hello_world_controller.rb may not use the Tailwind-aware React on Rails layout."
      )
      expect(warning_text).to include("preserving any existing app-specific pack names")
      expect(warning_text).to include("Keep an existing javascript_pack_tag call if it already renders your app packs")
      expect(warning_text).to include('  <% prepend_javascript_pack_tag "react_on_rails_tailwind" %>')
      expect(base_generator).not_to have_received(:say_status)
      expect(base_generator).not_to have_received(:say)
    end

    it "does not duplicate the manual Tailwind warning for the default generated layout" do
      simulate_existing_file("app/controllers/application_controller.rb", <<~RUBY)
        class ApplicationController < ActionController::Base
          layout "react_on_rails_default"
        end
      RUBY
      simulate_existing_file("app/controllers/hello_world_controller.rb", <<~RUBY)
        class HelloWorldController < ApplicationController
          def index
          end
        end
      RUBY
      simulate_named_pack_tag_layout("application")
      simulate_existing_layout("react_on_rails_default", <<~ERB)
        <!DOCTYPE html>
        <html>
          <head>
            <%= stylesheet_pack_tag "application" %>
            <%= javascript_pack_tag "application" %>
          </head>
          <body>
            <%= yield %>
          </body>
        </html>
      ERB
      GeneratorMessages.clear

      base_generator.send(:warn_existing_hello_world_tailwind_layout)

      expect(GeneratorMessages.messages.join("\n")).not_to include(
        "app/controllers/hello_world_controller.rb may not use the Tailwind-aware React on Rails layout."
      )
    end

    it "does not warn when HelloWorldController inherits a Tailwind-aware ApplicationController layout" do
      simulate_existing_file("app/controllers/application_controller.rb", <<~RUBY)
        class ApplicationController < ActionController::Base
          layout "react_on_rails_default"
        end
      RUBY
      simulate_existing_file("app/controllers/hello_world_controller.rb", <<~RUBY)
        class HelloWorldController < ApplicationController
          def index
          end
        end
      RUBY
      simulate_named_pack_tag_layout("application")
      simulate_existing_layout("react_on_rails_default", <<~ERB)
        <!DOCTYPE html>
        <html>
          <head>
            <% prepend_javascript_pack_tag "react_on_rails_tailwind" %>
            <%= stylesheet_pack_tag "react_on_rails_tailwind", media: "all" %>
            <%= javascript_pack_tag %>
          </head>
          <body>
            <%= yield %>
          </body>
        </html>
      ERB
      allow(base_generator).to receive(:say_status)
      allow(base_generator).to receive(:say)
      GeneratorMessages.clear

      base_generator.send(:warn_existing_hello_world_tailwind_layout)

      expect(GeneratorMessages.messages.join("\n")).not_to include(
        "app/controllers/hello_world_controller.rb may not use the Tailwind-aware React on Rails layout."
      )
      expect(base_generator).not_to have_received(:say)
    end
  end

  describe "#announce_skipped_layout_fallback" do
    let(:rsc_generator) { rsc_generator_fixture(tailwind: true) }

    before do
      allow(rsc_generator).to receive(:say)
    end

    it "names missing basic pack tags before Tailwind-specific layout requirements" do
      rsc_generator.send(
        :announce_skipped_layout_fallback,
        [{ path: "app/views/layouts/application.html.erb", classification: :missing_pack_tags }],
        "app/views/layouts/react_on_rails_rsc.html.erb"
      )

      expect(rsc_generator).to have_received(:say)
        .with(include("do not include both `stylesheet_pack_tag` and `javascript_pack_tag`"), :yellow)
      expect(rsc_generator).not_to have_received(:say)
        .with(include("do not include the layout-owned Tailwind pack block"), :yellow)
    end

    it "uses the Tailwind-specific reason when basic pack tags are present" do
      rsc_generator.send(
        :announce_skipped_layout_fallback,
        [{ path: "app/views/layouts/application.html.erb", classification: :missing_tailwind_pack }],
        "app/views/layouts/react_on_rails_rsc.html.erb"
      )

      expect(rsc_generator).to have_received(:say)
        .with(include("lack the Tailwind pack block"), :yellow)
      expect(rsc_generator).to have_received(:say)
        .with(include("update/remove the old layout if replacing"), :yellow)
    end
  end

  context "with --tailwind --no-rspack" do
    before(:all) { run_generator_test_with_args(%w[--tailwind --no-rspack], package_json: true) }

    include_examples "base_generator_common", application_js: true, tailwind: true
    include_examples "no_redux_generator"

    it "generates a layout-owned Tailwind v4 SSR setup for Webpack" do
      assert_tailwind_ssr_setup(config_dir: "config/webpack", extension: "jsx")
    end
  end

  context "with --tailwind --rspack --typescript" do
    before(:all) { run_generator_test_with_args(%w[--tailwind --rspack --typescript], package_json: true) }

    include_examples "base_generator_common", application_js: true, tailwind: true
    include_examples "no_redux_generator"

    it "generates a layout-owned Tailwind v4 SSR setup for Rspack" do
      assert_tailwind_ssr_setup(config_dir: "config/rspack", extension: "tsx")
    end
  end

  context "with -T" do
    before(:all) { run_generator_test_with_args(%w[-T], package_json: true) }

    include_examples "base_generator_common", application_js: true
    include_examples "no_redux_generator"

    it "creates TypeScript component files with .tsx extension" do
      assert_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.client.tsx"
      assert_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.server.tsx"
    end
  end

  context "without existing application.js or application.js.coffee file" do
    before(:all) { run_generator_test_with_args([], application_js: false, package_json: true) }

    include_examples "base_generator", application_js: false
  end

  context "with existing application.js or application.js.coffee file" do
    before(:all) { run_generator_test_with_args([], application_js: true, package_json: true) }

    include_examples "base_generator", application_js: true
  end

  context "with rails_helper" do
    before(:all) { run_generator_test_with_args([], spec: true, package_json: true) }

    it "adds ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)" do
      assert_file("spec/rails_helper.rb") do |contents|
        expect(contents).to include("ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)")
      end
    end
  end

  context "with minitest test_helper and no rspec files" do
    before(:all) do
      run_generator_test_with_args([], spec: false, package_json: true) do
        simulate_existing_file("test/test_helper.rb", <<~RUBY)
          ENV["RAILS_ENV"] ||= "test"
          require_relative "../config/environment"
          require "rails/test_help"

          class ActiveSupport::TestCase
          end
        RUBY
      end
    end

    it "adds ReactOnRails::TestHelper.ensure_assets_compiled for minitest" do
      expected = ReactOnRails::Generators::BaseGenerator::CONFIGURE_MINITEST_TO_COMPILE_ASSETS
      assert_file("test/test_helper.rb") { |contents| expect(contents).to match(expected) }
    end

    it "CI workflow uses bin/rails test when RSpec is absent" do
      assert_file ".github/workflows/ci.yml" do |content|
        expect(content).to include("bin/rails test")
        expect(content).not_to include("bundle exec rspec")
      end
    end
  end

  context "with both rspec and minitest helpers present" do
    before(:all) do
      run_generator_test_with_args([], spec: true, package_json: true) do
        simulate_existing_file("test/test_helper.rb", <<~RUBY)
          ENV["RAILS_ENV"] ||= "test"
          require_relative "../config/environment"
          require "rails/test_help"

          class ActiveSupport::TestCase
          end
        RUBY
      end
    end

    it "adds ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config) for rspec" do
      assert_file("spec/rails_helper.rb") do |contents|
        expect(contents).to include("ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)")
      end
    end

    it "adds ReactOnRails::TestHelper.ensure_assets_compiled for minitest" do
      expected = ReactOnRails::Generators::BaseGenerator::CONFIGURE_MINITEST_TO_COMPILE_ASSETS
      assert_file("test/test_helper.rb") { |contents| expect(contents).to match(expected) }
    end
  end

  context "when Shakapacker was pre-installed" do
    # Tests behavior when Shakapacker was already installed before running react_on_rails:install.
    # Uses --skip so template() preserves the pre-existing shakapacker.yml,
    # while gsub_file patchers (configure_precompile_hook) still run on it.
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)

      # Simulate Shakapacker being already installed (config files pre-exist)
      # with a shakapacker.yml with the default Shakapacker format (precompile_hook commented out)
      simulate_existing_file("config/shakapacker.yml", <<~YAML)
        # Note: You must restart bin/shakapacker-dev-server for changes to take effect
        default: &default
          source_path: app/javascript
          source_entry_path: packs
          public_root_path: public
          public_output_path: packs
          # private_output_path: ssr-generated
          cache_path: tmp/shakapacker
          webpack_compile_output: true
          shakapacker_precompile: true
          additional_paths: []
          cache_manifest: false
          assets_bundler: "webpack"
          # Example: precompile_hook: 'bin/shakapacker-precompile-hook'
          # precompile_hook: ~

        development:
          <<: *default

        test:
          <<: *default
          compile: true

        production:
          <<: *default
      YAML
      simulate_existing_file("bin/shakapacker", "")
      simulate_existing_file("bin/shakapacker-dev-server", "")
      simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
        const { generateWebpackConfig } = require('shakapacker')
        const webpackConfig = generateWebpackConfig()
        module.exports = webpackConfig
      JS

      Dir.chdir(destination_root) do
        run_generator(["--ignore-warnings", "--skip"])
      end
    end

    it "configures precompile_hook in shakapacker.yml" do
      assert_file "config/shakapacker.yml" do |content|
        # The commented placeholder should be replaced with the actual value
        expect(content).to include("precompile_hook: 'bin/shakapacker-precompile-hook'")
        # The example comment should be preserved
        expect(content).to include("# Example: precompile_hook:")
        # The old commented-out line should be gone
        expect(content).not_to match(/^\s*#\s*precompile_hook:\s*~/)
      end
    end

    it "configures private_output_path for SSR bundles on Shakapacker 9+" do
      assert_file "config/shakapacker.yml" do |content|
        if ReactOnRails::PackerUtils.shakapacker_version_requirement_met?("9.0.0")
          expect(content).to include("private_output_path: ssr-generated")
          expect(content).not_to match(/^\s*#\s*private_output_path:/)
        else
          expect(content).to match(/^\s*#\s*private_output_path:/)
        end
      end
    end

    it "preserves other shakapacker.yml settings and comments" do
      assert_file "config/shakapacker.yml" do |content|
        # Comments should be preserved
        expect(content).to include("# Note: You must restart bin/shakapacker-dev-server")
        # YAML anchors should be preserved
        expect(content).to include("default: &default")
        expect(content).to include("<<: *default")
        # Other settings should be preserved
        expect(content).to include("source_path: app/javascript")
        expect(content).to include("assets_bundler: \"webpack\"")
      end
    end
  end

  context "when Shakapacker was pre-installed with an inactive unquoted precompile_hook value" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)

      simulate_existing_file("config/shakapacker.yml", <<~YAML)
        default: &default
          source_path: app/javascript
          source_entry_path: packs
          public_output_path: packs
          assets_bundler: "webpack"
          precompile_hook: false

        development:
          <<: *default

        test:
          <<: *default
          compile: true
          # precompile_hook: ~

        production:
          <<: *default
      YAML
      simulate_existing_file("bin/shakapacker", "")
      simulate_existing_file("bin/shakapacker-dev-server", "")
      simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
        const { generateWebpackConfig } = require('shakapacker')
        const webpackConfig = generateWebpackConfig()
        module.exports = webpackConfig
      JS

      Dir.chdir(destination_root) do
        run_generator(["--ignore-warnings", "--skip"])
      end
    end

    it "configures the commented generated hook placeholder" do
      assert_file "config/shakapacker.yml" do |content|
        expect(content).to match(/^\s+precompile_hook: false$/)
        expect(content).to include("precompile_hook: 'bin/shakapacker-precompile-hook'")
      end
    end
  end

  context "when Shakapacker was pre-installed with an active unquoted precompile_hook value" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)

      simulate_existing_file("config/shakapacker.yml", <<~YAML)
        default: &default
          source_path: app/javascript
          source_entry_path: packs
          public_output_path: packs
          assets_bundler: "webpack"
          precompile_hook: bin/custom-precompile-hook
          # precompile_hook: ~

        development:
          <<: *default

        test:
          <<: *default
          compile: true

        production:
          <<: *default
      YAML
      simulate_existing_file("bin/shakapacker", "")
      simulate_existing_file("bin/shakapacker-dev-server", "")
      simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
        const { generateWebpackConfig } = require('shakapacker')
        const webpackConfig = generateWebpackConfig()
        module.exports = webpackConfig
      JS

      Dir.chdir(destination_root) do
        run_generator(["--ignore-warnings", "--skip"])
      end
    end

    it "leaves the custom hook under Shakapacker control" do
      assert_file "config/shakapacker.yml" do |content|
        expect(content).to include("precompile_hook: bin/custom-precompile-hook")
        expect(content).not_to include("precompile_hook: 'bin/shakapacker-precompile-hook'")
      end
    end
  end

  context "when Shakapacker was pre-installed with an inherited custom precompile_hook value" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)

      simulate_existing_file("config/shakapacker.yml", <<~YAML)
        default: &default
          source_path: app/javascript
          source_entry_path: packs
          public_output_path: packs
          assets_bundler: "webpack"
          precompile_hook: bin/custom-precompile-hook

        development:
          <<: *default

        test:
          <<: *default
          compile: true
          # precompile_hook: ~

        production:
          <<: *default
      YAML
      simulate_existing_file("bin/shakapacker", "")
      simulate_existing_file("bin/shakapacker-dev-server", "")
      simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
        const { generateWebpackConfig } = require('shakapacker')
        const webpackConfig = generateWebpackConfig()
        module.exports = webpackConfig
      JS

      Dir.chdir(destination_root) do
        run_generator(["--ignore-warnings", "--skip"])
      end
    end

    it "leaves the inherited custom hook under Shakapacker control" do
      assert_file "config/shakapacker.yml" do |content|
        expect(content).to include("precompile_hook: bin/custom-precompile-hook")
        expect(content).to include("# precompile_hook: ~")
        expect(content).not_to include("precompile_hook: 'bin/shakapacker-precompile-hook'")
      end

      assert_file "package.json" do |content|
        scripts = JSON.parse(content).fetch("scripts")
        expect(scripts["build:test"]).to eq("RAILS_ENV=test NODE_ENV=test bin/shakapacker")
      end
    end
  end

  context "when Shakapacker was pre-installed with an active hook in an unrelated environment" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)

      simulate_existing_file("config/shakapacker.yml", <<~YAML)
        default: &default
          source_path: app/javascript
          source_entry_path: packs
          public_output_path: packs
          assets_bundler: "webpack"
          # precompile_hook: ~

        development:
          <<: *default
          precompile_hook: bin/development-precompile-hook

        test:
          <<: *default
          compile: true

        production:
          <<: *default
      YAML
      simulate_existing_file("bin/shakapacker", "")
      simulate_existing_file("bin/shakapacker-dev-server", "")
      simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
        const { generateWebpackConfig } = require('shakapacker')
        const webpackConfig = generateWebpackConfig()
        module.exports = webpackConfig
      JS

      Dir.chdir(destination_root) do
        run_generator(["--ignore-warnings", "--skip"])
      end
    end

    it "still configures the generated hook placeholder" do
      assert_file "config/shakapacker.yml" do |content|
        expect(content).to include("precompile_hook: bin/development-precompile-hook")
        expect(content).to include("precompile_hook: 'bin/shakapacker-precompile-hook'")
      end
    end
  end

  context "when shakapacker.yml already has a custom precompile_hook" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)

      simulate_existing_file("config/shakapacker.yml", <<~YAML)
        default: &default
          source_path: app/javascript
          source_entry_path: packs
          public_output_path: packs
          assets_bundler: "webpack"
          precompile_hook: 'bundle exec rake react_on_rails:locale'

        development:
          <<: *default

        test:
          <<: *default
          compile: true
          precompile_hook: 'bundle exec rake react_on_rails:test_locale'

        production:
          <<: *default
          precompile_hook: 'bundle exec rake react_on_rails:build_locale'
      YAML
      simulate_existing_file("bin/shakapacker", "")
      simulate_existing_file("bin/shakapacker-dev-server", "")
      simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
        const { generateWebpackConfig } = require('shakapacker')
        const webpackConfig = generateWebpackConfig()
        module.exports = webpackConfig
      JS

      base_generator = ReactOnRails::Generators::BaseGenerator.new([], {}, destination_root:)
      generator = described_class.new([], {}, destination_root:)
      Dir.chdir(destination_root) do
        base_generator.send(:copy_base_files)
        generator.send(:add_package_json_scripts)
        generator.send(:add_ci_workflow)
      end
    end

    it "leaves custom hooks under Shakapacker control" do
      assert_file "config/shakapacker.yml" do |content|
        expect(content).to include("precompile_hook: 'bundle exec rake react_on_rails:locale'")
      end

      assert_file "package.json" do |content|
        scripts = JSON.parse(content).fetch("scripts")
        expect(scripts["build"]).to eq("RAILS_ENV=production NODE_ENV=production bin/shakapacker")
        expect(scripts["build:test"]).to eq("RAILS_ENV=test NODE_ENV=test bin/shakapacker")
      end

      assert_file "config/initializers/react_on_rails.rb" do |content|
        expect(content).to include('config.build_test_command = "RAILS_ENV=test NODE_ENV=test bin/shakapacker"')
        expect(content).not_to include("bin/shakapacker-precompile-hook")
      end

      assert_file ".github/workflows/ci.yml" do |content|
        expect(content).to include("bin/shakapacker")
        expect(content).not_to include("react_on_rails:test_locale")
        expect(content).not_to include("SHAKAPACKER_SKIP_PRECOMPILE_HOOK")
      end
    end
  end

  context "when shakapacker.yml has a default hook that the test environment does not merge" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)

      simulate_existing_file("config/shakapacker.yml", <<~YAML)
        default: &default
          source_path: app/javascript
          source_entry_path: packs
          public_output_path: packs
          precompile_hook: 'bin/shakapacker-precompile-hook'

        test:
          compile: true
      YAML
      simulate_existing_file("bin/shakapacker", "")
      simulate_existing_file("bin/shakapacker-dev-server", "")
      simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
        const { generateWebpackConfig } = require('shakapacker')
        const webpackConfig = generateWebpackConfig()
        module.exports = webpackConfig
      JS

      generator = described_class.new([], {}, destination_root:)
      Dir.chdir(destination_root) do
        generator.send(:add_package_json_scripts)
        generator.send(:add_ci_workflow)
      end
    end

    it "does not run the default hook for test builds" do
      assert_file "package.json" do |content|
        scripts = JSON.parse(content).fetch("scripts")
        expect(scripts["build:test"]).to eq("RAILS_ENV=test NODE_ENV=test bin/shakapacker")
      end

      assert_file ".github/workflows/ci.yml" do |content|
        expect(content).to include("bin/shakapacker")
        expect(content).not_to include("bin/shakapacker-precompile-hook")
        expect(content).not_to include("SHAKAPACKER_SKIP_PRECOMPILE_HOOK")
      end
    end
  end

  context "when shakapacker.yml has a commented generated hook placeholder and test does not merge defaults" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)

      simulate_existing_file("config/shakapacker.yml", <<~YAML)
        default: &default
          source_path: app/javascript
          source_entry_path: packs
          public_output_path: packs
          # precompile_hook: ~

        test:
          compile: true
      YAML
      simulate_existing_file("bin/shakapacker", "")
      simulate_existing_file("bin/shakapacker-dev-server", "")
      simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
        const { generateWebpackConfig } = require('shakapacker')
        const webpackConfig = generateWebpackConfig()
        module.exports = webpackConfig
      JS

      base_generator = ReactOnRails::Generators::BaseGenerator.new([], {}, destination_root:)
      generator = described_class.new([], {}, destination_root:)
      Dir.chdir(destination_root) do
        base_generator.send(:copy_base_files)
        generator.send(:add_package_json_scripts)
        generator.send(:add_ci_workflow)
      end
    end

    it "does not add the generated hook to test build commands before the environment inherits it" do
      assert_file "config/initializers/react_on_rails.rb" do |content|
        expect(content).to include('config.build_test_command = "RAILS_ENV=test NODE_ENV=test bin/shakapacker"')
        expect(content).not_to include("bin/shakapacker-precompile-hook")
      end

      assert_file "package.json" do |content|
        scripts = JSON.parse(content).fetch("scripts")
        expect(scripts["build:test"]).to eq("RAILS_ENV=test NODE_ENV=test bin/shakapacker")
      end

      assert_file ".github/workflows/ci.yml" do |content|
        expect(content).to include("bin/shakapacker")
        expect(content).not_to include("bin/shakapacker-precompile-hook")
        expect(content).not_to include("SHAKAPACKER_SKIP_PRECOMPILE_HOOK")
      end
    end
  end

  context "when shakapacker.yml has a commented generated hook placeholder and test merges defaults" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)

      simulate_existing_file("config/shakapacker.yml", <<~YAML)
        default: &default
          source_path: app/javascript
          source_entry_path: packs
          public_output_path: packs
          # precompile_hook: ~

        test:
          <<: *default
          compile: true
      YAML
      simulate_existing_file("bin/shakapacker", "")
      simulate_existing_file("bin/shakapacker-dev-server", "")
      simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
        const { generateWebpackConfig } = require('shakapacker')
        const webpackConfig = generateWebpackConfig()
        module.exports = webpackConfig
      JS

      generator = described_class.new([], {}, destination_root:)
      Dir.chdir(destination_root) do
        generator.send(:add_package_json_scripts)
        generator.send(:add_ci_workflow)
      end
    end

    it "uses the generated hook for scripts and CI before shakapacker.yml is rewritten" do
      assert_file "package.json" do |content|
        scripts = JSON.parse(content).fetch("scripts")
        expect(scripts["build:test"]).to eq(
          "RAILS_ENV=test NODE_ENV=test bin/shakapacker-precompile-hook && " \
          "SHAKAPACKER_SKIP_PRECOMPILE_HOOK=true RAILS_ENV=test NODE_ENV=test bin/shakapacker"
        )
      end

      assert_file ".github/workflows/ci.yml" do |content|
        expect(content).to include("bin/shakapacker-precompile-hook")
        expect(content).to include("SHAKAPACKER_SKIP_PRECOMPILE_HOOK")
      end
    end
  end

  context "when shakapacker.yml already has private_output_path key without a value" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)

      simulate_existing_file("config/shakapacker.yml", <<~YAML)
        default: &default
          source_path: app/javascript
          source_entry_path: packs
          public_output_path: packs
          private_output_path:
          assets_bundler: "webpack"
          # precompile_hook: ~

        development:
          <<: *default

        test:
          <<: *default
          compile: true

        production:
          <<: *default
      YAML
      simulate_existing_file("bin/shakapacker", "")
      simulate_existing_file("bin/shakapacker-dev-server", "")
      simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
        const { generateWebpackConfig } = require('shakapacker')
        const webpackConfig = generateWebpackConfig()
        module.exports = webpackConfig
      JS

      Dir.chdir(destination_root) do
        run_generator(["--ignore-warnings", "--skip"])
      end
    end

    it "does not insert duplicate private_output_path entries" do
      skip "private_output_path requires Shakapacker >= 9.0.0" unless
        ReactOnRails::PackerUtils.shakapacker_version_requirement_met?("9.0.0")

      assert_file "config/shakapacker.yml" do |content|
        expect(content.scan(/^\s*private_output_path:/).size).to eq(1)
      end
    end
  end

  # Regression test for https://github.com/shakacode/react_on_rails/issues/2289
  # When Shakapacker is freshly installed by the generator, the RoR template must be applied
  # (with force: true) so that version-conditional settings like private_output_path are configured.
  context "when Shakapacker was just installed (regression #2289)" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)

      # Simulate Shakapacker's installer having created its default config
      # with private_output_path commented out (the bug scenario)
      simulate_existing_file("config/shakapacker.yml", <<~YAML)
        default: &default
          source_path: app/javascript
          source_entry_path: packs
          # private_output_path: ssr-generated
          # precompile_hook: ~

        development:
          <<: *default

        test:
          <<: *default
          compile: true

        production:
          <<: *default
      YAML
      simulate_existing_file("bin/shakapacker", "")
      simulate_existing_file("bin/shakapacker-dev-server", "")
      simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
        const { generateWebpackConfig } = require('shakapacker')
        const webpackConfig = generateWebpackConfig()
        module.exports = webpackConfig
      JS

      Dir.chdir(destination_root) do
        # Run without --force: the fix must work via --shakapacker-just-installed alone,
        # not rely on the global --force flag overwriting all conflicting files.
        run_generator(["--shakapacker-just-installed", "--ignore-warnings"])
      end
    end

    it "uncomments private_output_path for Shakapacker 9+" do
      unless ReactOnRails::PackerUtils.shakapacker_version_requirement_met?("9.0.0")
        skip "Only applies to Shakapacker 9+"
      end

      assert_file "config/shakapacker.yml" do |content|
        expect(content).to match(/^\s+private_output_path: ssr-generated/)
        expect(content).not_to match(/^\s+#\s*private_output_path/)
      end
    end

    it "applies the full RoR template (not Shakapacker's default)" do
      assert_file "config/shakapacker.yml" do |content|
        # RoR's template includes precompile_hook configured (not commented)
        expect(content).to include("precompile_hook: 'bin/shakapacker-precompile-hook'")
        # RoR's template includes nested_entries
        expect(content).to include("nested_entries: true")
      end
    end
  end

  describe "copy_packer_config force behavior" do
    let(:destination) { File.expand_path("../dummy-for-generators", __dir__) }

    it "passes force: true when shakapacker_just_installed is true" do
      gen = BaseGenerator.new([], { shakapacker_just_installed: true, force: false },
                              { destination_root: destination })
      allow(gen).to receive(:template)
      allow(gen).to receive(:configure_rspack_in_shakapacker)
      allow(gen).to receive(:configure_precompile_hook_in_shakapacker)

      gen.copy_packer_config

      expect(gen).to have_received(:template)
        .with("base/base/config/shakapacker.yml.tt", "config/shakapacker.yml", force: true)
    end

    it "calls template without force when shakapacker_just_installed is false" do
      gen = BaseGenerator.new([], { shakapacker_just_installed: false, force: false },
                              { destination_root: destination })
      allow(gen).to receive(:template)
      allow(gen).to receive(:configure_rspack_in_shakapacker)
      allow(gen).to receive(:configure_precompile_hook_in_shakapacker)

      gen.copy_packer_config

      expect(gen).to have_received(:template)
        .with("base/base/config/shakapacker.yml.tt", "config/shakapacker.yml")
    end

    it "preserves an existing Rspack choice before overwriting the Shakapacker config" do
      shakapacker_yml_path = File.join(destination, "config/shakapacker.yml")
      FileUtils.mkdir_p(File.dirname(shakapacker_yml_path))
      File.write(shakapacker_yml_path, <<~YAML)
        default:
          assets_bundler: "rspack"
      YAML

      gen = BaseGenerator.new([], { force: true }, { destination_root: destination })
      allow(gen).to receive(:template) do |_source, target, *_args|
        File.write(File.join(destination, target), <<~YAML)
          default:
            assets_bundler: "webpack"
        YAML
      end
      allow(gen).to receive(:configure_rspack_in_shakapacker)
      allow(gen).to receive(:configure_precompile_hook_in_shakapacker)
      allow(gen).to receive(:configure_private_output_path_in_shakapacker)

      gen.copy_packer_config

      expect(gen).to have_received(:configure_rspack_in_shakapacker)
      expect(gen.using_rspack?).to be(true)
    ensure
      FileUtils.rm_rf(File.join(destination, "config"))
    end

    it "raises when path helpers memoize before copy_packer_config runs" do
      gen = BaseGenerator.new([], {}, { destination_root: destination })
      gen.instance_variable_set(:@shakapacker_source_path, "client/app")

      expect { gen.copy_packer_config }
        .to raise_error(Thor::Error, /copy_packer_config must run before path-dependent generator actions/)
    end

    it "raises when source_entry_path memoizes before copy_packer_config runs" do
      gen = BaseGenerator.new([], {}, { destination_root: destination })
      gen.instance_variable_set(:@shakapacker_source_entry_path, "entrypoints")

      expect { gen.copy_packer_config }
        .to raise_error(Thor::Error, /copy_packer_config must run before path-dependent generator actions/)
    end
  end

  context "with --rspack" do
    # Uses --skip so template() preserves the pre-existing shakapacker.yml,
    # while gsub_file patchers (configure_rspack_in_shakapacker) still run on it.
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)

      # Simulate Shakapacker being already installed (config files pre-exist)
      # This allows testing that configure_rspack_in_shakapacker properly updates the config
      simulate_existing_file("config/shakapacker.yml", <<~YAML)
        # Note: You must restart bin/shakapacker-dev-server for changes to take effect
        default: &default
          source_path: app/javascript
          source_entry_path: packs
          public_root_path: public
          public_output_path: packs
          cache_path: tmp/shakapacker
          webpack_compile_output: true
          shakapacker_precompile: true
          additional_paths: []
          cache_manifest: false
          javascript_transpiler: "babel"
          assets_bundler: "webpack"
          # precompile_hook: ~

        development:
          <<: *default

        test:
          <<: *default
          compile: true

        production:
          <<: *default
      YAML
      simulate_existing_file("bin/shakapacker", "")
      simulate_existing_file("bin/shakapacker-dev-server", "")
      simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
        const { generateWebpackConfig } = require('shakapacker')
        const webpackConfig = generateWebpackConfig()
        module.exports = webpackConfig
      JS

      Dir.chdir(destination_root) do
        run_generator(["--rspack", "--ignore-warnings", "--skip"])
      end
    end

    include_examples "base_generator", application_js: true
    include_examples "no_redux_generator"

    it "creates bin/switch-bundler script" do
      assert_file "bin/switch-bundler" do |content|
        expect(content).to include("class BundlerSwitcher")
        expect(content).to include("RSPACK_DEPS")
        expect(content).to include("WEBPACK_DEPS")
      end
    end

    it "switch-bundler has version-pinned deps and strips versions before deletion" do
      assert_file "bin/switch-bundler" do |content|
        # Version pins are present in the constants
        expect(content).to include("@rspack/core@^2.0.0-0")
        expect(content).to include("@rspack/cli@^2.0.0-0")
        expect(content).to include("@rspack/dev-server@^2.0.0")
        expect(content).to include("@rspack/plugin-react-refresh@^2.0.0")
        expect(content).to match(%r{@rspack/plugin-react-refresh@\^2\.0\.0\s+react-refresh})
        expect(content).to include("webpack@^5.0.0")
        # Version-stripping regex is used for package.json key deletion
        expect(content).to include('dep[%r{\A(@[^/]+/[^@]+|[^@]+)}]')
      end
    end

    it "installs rspack dependencies in package.json" do
      assert_file "package.json" do |content|
        package_json = JSON.parse(content)
        expect(package_json["dependencies"]).to include("@rspack/core")
        expect(package_json["dependencies"]).to include("rspack-manifest-plugin")
        expect(package_json["devDependencies"]).to include("@rspack/cli")
        expect(package_json["devDependencies"]).to include("@rspack/dev-server")
        expect(package_json["devDependencies"]).to include("@rspack/plugin-react-refresh")
      end
    end

    it "does not install webpack-specific dependencies" do
      assert_file "package.json" do |content|
        package_json = JSON.parse(content)
        expect(package_json["dependencies"]).not_to include("webpack")
        expect(package_json["devDependencies"]).not_to include("webpack-cli")
        expect(package_json["devDependencies"]).not_to include("@pmmmwh/react-refresh-webpack-plugin")
      end
    end

    it "generates unified rspack config with bundler detection" do
      assert_file "config/rspack/development.js" do |content|
        expect(content).to include("const { devServer, inliningCss, config } = require('shakapacker')")
        expect(content).to include("if (config.assets_bundler === 'rspack')")
        expect(content).to include("@rspack/plugin-react-refresh")
        expect(content).to include("@pmmmwh/react-refresh-webpack-plugin")
      end
    end

    it "generates server rspack config with bundler variable" do
      assert_file "config/rspack/serverWebpackConfig.js" do |content|
        expect(content).to include("const bundler = config.assets_bundler === 'rspack'")
        expect(content).to include("? require('@rspack/core')")
        expect(content).to include(": require('webpack')")
        expect(content).to include("new bundler.optimize.LimitChunkCountPlugin")
      end
    end

    it "writes the main rspack config to config/rspack/rspack.config.js" do
      assert_file "config/rspack/rspack.config.js" do |content|
        expect(content).to include("const envSpecificConfig = () =>")
        expect(content).to include("const path = resolve(__dirname, `${env.nodeEnv}.js`)")
      end
    end

    it "removes stale stock config/webpack files after switching to rspack" do
      expect(File).not_to exist(File.join(destination_root, "config/webpack"))
    end

    it "configures rspack in shakapacker.yml" do
      assert_file "config/shakapacker.yml" do |content|
        # Should have rspack as the bundler (inherited by all environments via YAML anchor)
        expect(content).to include("assets_bundler: rspack")
        # Should not have webpack as the bundler
        expect(content).not_to match(/assets_bundler:\s*["']?webpack["']?/)
        # Should use swc loader (rspack works best with SWC)
        expect(content).to include("javascript_transpiler: swc")
        expect(content).not_to match(/javascript_transpiler:\s*["']?babel["']?/)
      end
    end

    it "adds private_output_path on Shakapacker 9+ when missing" do
      assert_file "config/shakapacker.yml" do |content|
        if ReactOnRails::PackerUtils.shakapacker_version_requirement_met?("9.0.0")
          expect(content).to include("private_output_path: ssr-generated")
        end
      end
    end

    it "preserves YAML structure in shakapacker.yml" do
      assert_file "config/shakapacker.yml" do |content|
        # YAML anchors should be preserved
        expect(content).to include("default: &default")
        expect(content).to include("<<: *default")
        # Comments should be preserved
        expect(content).to include("# Note: You must restart")
      end
    end
  end

  shared_context "with webpack to rspack migration base" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/shakapacker.yml", <<~YAML)
        default: &default
          source_path: app/javascript
          source_entry_path: packs
          javascript_transpiler: "babel"
          assets_bundler: "webpack"
          # precompile_hook: ~

        development:
          <<: *default

        test:
          <<: *default
          compile: true

        production:
          <<: *default
      YAML
      simulate_existing_file("bin/shakapacker", "")
      simulate_existing_file("bin/shakapacker-dev-server", "")
    end
  end

  context "with --rspack and custom webpack files" do
    include_context "with webpack to rspack migration base"

    before(:all) do
      simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
        const { generateWebpackConfig } = require('shakapacker')
        const webpackConfig = generateWebpackConfig()
        module.exports = webpackConfig
      JS
      simulate_existing_file("config/webpack/custom-banner.js", "module.exports = { custom: true };\n")

      Dir.chdir(destination_root) do
        run_generator(["--rspack", "--ignore-warnings", "--skip"])
      end
    end

    it "keeps config/webpack when custom files are detected" do
      assert_file "config/webpack/custom-banner.js"
      assert_file "config/rspack/rspack.config.js"
    end
  end

  context "with --rspack and dotfiles in config/webpack" do
    include_context "with webpack to rspack migration base"

    before(:all) do
      simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
        const { generateWebpackConfig } = require('shakapacker')
        const webpackConfig = generateWebpackConfig()
        module.exports = webpackConfig
      JS
      simulate_existing_file("config/webpack/.gitkeep", "")

      Dir.chdir(destination_root) do
        run_generator(["--rspack", "--ignore-warnings", "--skip"])
      end
    end

    it "removes stale managed files but keeps config/webpack when dotfiles are present" do
      assert_file "config/webpack/.gitkeep"
      assert_no_file "config/webpack/webpack.config.js"
      assert_file "config/rspack/rspack.config.js"
    end
  end

  context "with --rspack and empty config/webpack directory" do
    include_context "with webpack to rspack migration base"

    before(:all) do
      FileUtils.mkdir_p(File.join(destination_root, "config/webpack"))

      Dir.chdir(destination_root) do
        run_generator(["--rspack", "--ignore-warnings", "--skip"])
      end
    end

    it "keeps config/webpack when directory is empty" do
      assert_directory "config/webpack"
      assert_file "config/rspack/rspack.config.js"
    end
  end

  context "with --rspack and full managed stock webpack files" do
    include_context "with webpack to rspack migration base"

    before(:all) do
      simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
        const { generateWebpackConfig } = require('shakapacker')
        const webpackConfig = generateWebpackConfig()
        module.exports = webpackConfig
      JS
      simulate_managed_stock_webpack_files

      Dir.chdir(destination_root) do
        run_generator(["--rspack", "--ignore-warnings", "--skip"])
      end
    end

    it "removes config/webpack when only managed stock files are present" do
      expect(File).not_to exist(File.join(destination_root, "config/webpack"))
      assert_file "config/rspack/rspack.config.js"
    end
  end

  context "with --rspack and symlinked webpack entries" do
    include_context "with webpack to rspack migration base"

    before(:all) do
      simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
        const { generateWebpackConfig } = require('shakapacker')
        const webpackConfig = generateWebpackConfig()
        module.exports = webpackConfig
      JS

      symlink_target = File.join(destination_root, "tmp/clientWebpackConfig.js")
      FileUtils.mkdir_p(File.dirname(symlink_target))
      File.write(
        symlink_target,
        render_stock_webpack_template("base/base/config/webpack/clientWebpackConfig.js.tt")
      )
      File.symlink(symlink_target, File.join(destination_root, "config/webpack/clientWebpackConfig.js"))

      Dir.chdir(destination_root) do
        run_generator(["--rspack", "--ignore-warnings", "--skip"])
      end
    end

    it "keeps config/webpack when symlink entries are present" do
      assert_directory "config/webpack"
      expect(File.symlink?(File.join(destination_root, "config/webpack/clientWebpackConfig.js"))).to be(true)
      assert_file "config/rspack/rspack.config.js"
    end
  end

  context "with --rspack and nested config/webpack directory" do
    include_context "with webpack to rspack migration base"

    before(:all) do
      simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
        const { generateWebpackConfig } = require('shakapacker')
        const webpackConfig = generateWebpackConfig()
        module.exports = webpackConfig
      JS
      simulate_existing_file("config/webpack/custom/.keep", "")

      Dir.chdir(destination_root) do
        run_generator(["--rspack", "--ignore-warnings", "--skip"])
      end
    end

    it "keeps config/webpack when nested directories are present" do
      assert_file "config/webpack/custom/.keep"
      assert_file "config/rspack/rspack.config.js"
    end
  end

  context "with --rspack and customized webpack.config.js only" do
    include_context "with webpack to rspack migration base"

    before(:all) do
      simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
        const { env } = require('shakapacker')
        const { existsSync } = require('fs')
        const { resolve } = require('path')

        const envSpecificConfig = () => {
          const path = resolve(__dirname, `${env.nodeEnv}.js`)
          if (existsSync(path)) return require(path)
          throw new Error(`Could not find file to load ${path}`)
        }

        const config = envSpecificConfig()
        config.resolve = config.resolve || {}
        module.exports = config
      JS

      Dir.chdir(destination_root) do
        run_generator(["--rspack", "--ignore-warnings", "--skip"])
      end
    end

    it "keeps config/webpack when webpack.config.js is customized" do
      assert_file "config/webpack/webpack.config.js"
      assert_file "config/rspack/rspack.config.js"
    end
  end

  context "with --rspack and comment-only notes in webpack.config.js" do
    include_context "with webpack to rspack migration base"

    before(:all) do
      simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
        // Team note: keep webpack fallback while validating rspack migration.
        const { generateWebpackConfig } = require('shakapacker')
        const webpackConfig = generateWebpackConfig()
        module.exports = webpackConfig
      JS

      Dir.chdir(destination_root) do
        run_generator(["--rspack", "--ignore-warnings", "--skip"])
      end
    end

    it "keeps config/webpack when files include comment-only customizations" do
      assert_file "config/webpack/webpack.config.js"
      assert_file "config/rspack/rspack.config.js"
    end
  end

  context "with --rspack and legacy generateWebpackConfigs.js" do
    include_context "with webpack to rspack migration base"

    before(:all) do
      simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
        const { generateWebpackConfig } = require('shakapacker')
        const webpackConfig = generateWebpackConfig()
        module.exports = webpackConfig
      JS
      # Render from the current template so fixture content stays in sync with generator output.
      simulate_existing_file(
        "config/webpack/generateWebpackConfigs.js",
        render_stock_webpack_template("base/base/config/webpack/ServerClientOrBoth.js.tt")
      )

      Dir.chdir(destination_root) do
        run_generator(["--rspack", "--ignore-warnings", "--skip"])
      end
    end

    it "removes legacy generateWebpackConfigs.js along with stale config/webpack directory" do
      expect(File).not_to exist(File.join(destination_root, "config/webpack"))
      assert_file "config/rspack/rspack.config.js"
    end
  end

  context "with --rspack and legacy generateWebpackConfigs.js generated with --rsc" do
    include_context "with webpack to rspack migration base"

    before(:all) do
      simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
        const { generateWebpackConfig } = require('shakapacker')
        const webpackConfig = generateWebpackConfig()
        module.exports = webpackConfig
      JS
      simulate_existing_file("config/webpack/generateWebpackConfigs.js", <<~JS)
        const clientWebpackConfig = require('./clientWebpackConfig');
        const serverWebpackConfig = require('./serverWebpackConfig');
        const rscWebpackConfig = require('./rscWebpackConfig');

        const serverClientOrBoth = (envSpecific) => {
          const clientConfig = clientWebpackConfig();
          const serverConfig = serverWebpackConfig();
          const rscConfig = rscWebpackConfig();
          if (envSpecific) envSpecific(clientConfig, serverConfig, rscConfig);
          return [clientConfig, serverConfig, rscConfig];
        };

        module.exports = serverClientOrBoth;
      JS

      Dir.chdir(destination_root) do
        run_generator(["--rspack", "--ignore-warnings", "--skip"])
      end
    end

    it "keeps config/webpack when legacy content no longer matches current options" do
      assert_file "config/webpack/generateWebpackConfigs.js"
      assert_file "config/rspack/rspack.config.js"
    end
  end

  context "with --rsc app switching from webpack to rspack" do
    include_context "with webpack to rspack migration base"

    before(:all) do
      simulate_existing_file(
        "config/webpack/webpack.config.js",
        render_stock_webpack_template("base/base/config/webpack/webpack.config.js.tt", rsc: true)
      )
      simulate_existing_file(
        "config/webpack/rscWebpackConfig.js",
        render_stock_webpack_template("rsc/base/config/webpack/rscWebpackConfig.js.tt", rsc: true)
      )

      Dir.chdir(destination_root) do
        run_generator(["--rsc", "--rspack", "--ignore-warnings", "--skip"])
      end
    end

    it "removes stale stock config/webpack files including rscWebpackConfig.js" do
      assert_no_file "config/webpack"
      assert_file "config/rspack/rspack.config.js"
      assert_file "config/rspack/rscWebpackConfig.js"
    end
  end

  # Tests a fresh rspack install where Shakapacker was installed directly with rspack
  # (no prior webpack config). This exercises different code paths than "with --rspack":
  # - shakapacker_config_file_exists? falls through to the rspack branches (lines 333-334)
  # - copy_webpack_main_config finds the existing stock rspack config and auto-replaces it
  # - configure_rspack_in_shakapacker is a no-op (already rspack)
  context "with --rspack and pre-existing rspack config (fresh rspack install)" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)

      # Simulate Shakapacker installed directly with SHAKAPACKER_ASSETS_BUNDLER=rspack.
      # No config/webpack/ directory exists — only config/rspack/.
      simulate_existing_file("config/shakapacker.yml", <<~YAML)
        default: &default
          source_path: app/javascript
          source_entry_path: packs
          public_root_path: public
          public_output_path: packs
          cache_path: tmp/shakapacker
          webpack_compile_output: true
          shakapacker_precompile: true
          additional_paths: []
          cache_manifest: false
          javascript_transpiler: "swc"
          assets_bundler: "rspack"
          # precompile_hook: ~

        development:
          <<: *default

        test:
          <<: *default
          compile: true

        production:
          <<: *default
      YAML
      simulate_existing_file("bin/shakapacker", "")
      simulate_existing_file("bin/shakapacker-dev-server", "")
      # Stock rspack config — exact content from Shakapacker 9.4.0
      simulate_existing_file("config/rspack/rspack.config.js", <<~JS)
        // See the shakacode/shakapacker README and docs directory for advice on customizing your rspackConfig.
        const { generateRspackConfig } = require('shakapacker/rspack')

        const rspackConfig = generateRspackConfig()

        module.exports = rspackConfig
      JS

      Dir.chdir(destination_root) do
        run_generator(["--rspack", "--ignore-warnings", "--skip"])
      end
    end

    include_examples "base_generator", application_js: true
    include_examples "no_redux_generator"

    it "auto-replaces stock rspack config with React on Rails environment loader" do
      assert_file "config/rspack/rspack.config.js" do |content|
        expect(content).to include("const envSpecificConfig = () =>")
        expect(content).not_to include("generateRspackConfig")
      end
    end

    it "generates all bundler configs in config/rspack/" do
      %w[serverWebpackConfig.js clientWebpackConfig.js commonWebpackConfig.js
         ServerClientOrBoth.js development.js production.js test.js].each do |file|
        assert_file "config/rspack/#{file}"
      end
    end

    it "does not create any config/webpack/ files" do
      assert_no_file "config/webpack/webpack.config.js"
      assert_no_file "config/webpack/serverWebpackConfig.js"
      assert_no_file "config/webpack/clientWebpackConfig.js"
    end

    it "preserves rspack bundler setting in shakapacker.yml" do
      assert_file "config/shakapacker.yml" do |content|
        expect(content).to include("assets_bundler: \"rspack\"")
        expect(content).not_to match(/assets_bundler:\s*["']?webpack["']?/)
      end
    end

    it "installs rspack dependencies in package.json" do
      assert_file "package.json" do |content|
        package_json = JSON.parse(content)
        expect(package_json["dependencies"]).to include("@rspack/core")
        expect(package_json["dependencies"]).to include("rspack-manifest-plugin")
        expect(package_json["devDependencies"]).to include("@rspack/cli")
      end
    end

    it "does not install webpack-specific dependencies" do
      assert_file "package.json" do |content|
        package_json = JSON.parse(content)
        expect(package_json["dependencies"]).not_to include("webpack")
        expect(package_json["devDependencies"]).not_to include("webpack-cli")
      end
    end
  end

  context "with --rspack --redux" do
    # Uses --skip so template() preserves the pre-existing shakapacker.yml,
    # while gsub_file patchers (configure_rspack_in_shakapacker) still run on it.
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)

      simulate_existing_file("config/shakapacker.yml", <<~YAML)
        # Note: You must restart bin/shakapacker-dev-server for changes to take effect
        default: &default
          source_path: app/javascript
          source_entry_path: packs
          public_root_path: public
          public_output_path: packs
          cache_path: tmp/shakapacker
          webpack_compile_output: true
          shakapacker_precompile: true
          additional_paths: []
          cache_manifest: false
          javascript_transpiler: "babel"
          assets_bundler: "webpack"
          # precompile_hook: ~

        development:
          <<: *default

        test:
          <<: *default
          compile: true

        production:
          <<: *default
      YAML
      simulate_existing_file("bin/shakapacker", "")
      simulate_existing_file("bin/shakapacker-dev-server", "")
      simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
        const { generateWebpackConfig } = require('shakapacker')
        const webpackConfig = generateWebpackConfig()
        module.exports = webpackConfig
      JS

      Dir.chdir(destination_root) do
        run_generator(["--rspack", "--redux", "--ignore-warnings", "--skip"])
      end
    end

    include_examples "base_generator_common", application_js: true
    include_examples "react_with_redux_generator"

    it "installs both Rspack and Redux dependencies" do
      assert_file "package.json" do |content|
        package_json = JSON.parse(content)
        deps = package_json["dependencies"] || {}
        expect(deps).to include("@rspack/core")
        expect(deps).to include("redux")
      end
    end
  end

  context "with --rspack --typescript" do
    # Uses --skip so template() preserves the pre-existing shakapacker.yml,
    # while gsub_file patchers (configure_rspack_in_shakapacker) still run on it.
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)

      # Simulate Shakapacker being already installed (config files pre-exist)
      simulate_existing_file("config/shakapacker.yml", <<~YAML)
        # Note: You must restart bin/shakapacker-dev-server for changes to take effect
        default: &default
          source_path: app/javascript
          source_entry_path: packs
          javascript_transpiler: "babel"
          assets_bundler: "webpack"
          # precompile_hook: ~

        development:
          <<: *default

        test:
          <<: *default
          compile: true

        production:
          <<: *default
      YAML
      simulate_existing_file("bin/shakapacker", "")
      simulate_existing_file("bin/shakapacker-dev-server", "")
      simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
        const { generateWebpackConfig } = require('shakapacker')
        const webpackConfig = generateWebpackConfig()
        module.exports = webpackConfig
      JS

      Dir.chdir(destination_root) do
        run_generator(["--rspack", "--typescript", "--ignore-warnings", "--skip"])
      end
    end

    include_examples "base_generator_common", application_js: true
    include_examples "no_redux_generator"

    it "creates TypeScript component files with .tsx extension" do
      assert_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.client.tsx"
      assert_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.server.tsx"
    end

    it "creates tsconfig.json file" do
      assert_file "tsconfig.json" do |content|
        config = JSON.parse(content)
        expect(config["compilerOptions"]["jsx"]).to eq("react-jsx")
        expect(config["compilerOptions"]["strict"]).to be true
        expect(config["include"]).to include("app/javascript/**/*")
      end
    end

    it "installs both rspack and typescript dependencies" do
      assert_file "package.json" do |content|
        package_json = JSON.parse(content)
        # Rspack dependencies
        expect(package_json["dependencies"]).to include("@rspack/core")
        expect(package_json["devDependencies"]).to include("@rspack/cli")
        # TypeScript dependencies
        expect(package_json["devDependencies"]).to include("typescript")
        expect(package_json["devDependencies"]).to include("@types/react")
        expect(package_json["devDependencies"]).to include("@types/react-dom")
      end
    end

    it "TypeScript component includes proper typing" do
      assert_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.client.tsx" do |content|
        expect(content).to match(/interface HelloWorldProps/)
        expect(content).to match(/React\.FC<HelloWorldProps>/)
      end
    end
  end

  context "with --pro" do
    # Pin to --no-rspack so this context keeps exercising the Webpack Pro transforms.
    # Rspack is the default now and is covered by the "with --pro --rspack" context.
    before(:all) { run_generator_test_with_args(%w[--pro --no-rspack], package_json: true) }

    include_examples "base_generator", application_js: true
    include_examples "no_redux_generator"

    it "creates Pro initializer and node-renderer.js with matching random passwords" do
      ruby_password = nil
      assert_file "config/initializers/react_on_rails_pro.rb" do |content|
        expect(content).to include("ReactOnRailsPro.configure")
        expect(content).to include('config.server_renderer = "NodeRenderer"')
        expect(content).to include("config.renderer_url")
        expect(content).to include("config.renderer_password")
        expect(content).to include("config.ssr_timeout")
        expect(content).not_to include("devPassword")
        password_match = content.match(/ENV\.fetch\("RENDERER_PASSWORD",\s*"([^"]+)"\)/)
        expect(password_match).not_to be_nil
        expect(password_match[1].length).to eq(64)
        ruby_password = password_match[1]
      end

      assert_file "renderer/node-renderer.js" do |content|
        expect(content).to include("reactOnRailsProNodeRenderer")
        expect(content).to include("require('react-on-rails-pro-node-renderer')")
        expect(content).to include("serverBundleCachePath")
        expect(content).to include("port:")
        expect(content).to include("password:")
        expect(content).to include("const configuredWorkersCount =")
        expect(content).to include("workersCount:")
        expect(content).to include("if (env.CI && configuredWorkersCount == null)")
        expect(content).not_to include("devPassword")
        password_match = content.match(/RENDERER_PASSWORD\s*\?\?\s*'([^']+)'/)
        expect(password_match).not_to be_nil
        expect(password_match[1].length).to eq(64)
        expect(password_match[1]).to eq(ruby_password)
      end
    end

    it "adds node-renderer process to every bin/dev Procfile that can serve SSR pages" do
      %w[Procfile.dev Procfile.dev-static-assets Procfile.dev-prod-assets].each do |procfile|
        assert_file procfile do |content|
          expect(content).to include("node-renderer:")
          expect(content).to include("RENDERER_PORT=${RENDERER_PORT:-3800}")
          expect(content).to include("node renderer/node-renderer.js")
        end
      end
    end

    it "installs Pro npm dependencies" do
      assert_file "package.json" do |content|
        package_json = JSON.parse(content)
        deps = package_json["dependencies"] || {}
        expect(deps).to include("react-on-rails-pro")
        expect(deps).to include("react-on-rails-pro-node-renderer")
      end
    end

    it "serverWebpackConfig includes Pro features" do
      assert_file "config/webpack/serverWebpackConfig.js" do |content|
        expect(content).to include("libraryTarget: 'commonjs2',")
        expect(content).to include("function extractLoader")
        expect(content).to include("serverWebpackConfig.target = 'node'")
      end
    end

    it "Pro initializer does not include RSC configuration" do
      assert_file "config/initializers/react_on_rails_pro.rb" do |content|
        expect(content).not_to include("enable_rsc_support")
        expect(content).not_to include("rsc_bundle_js_file")
      end
    end
  end

  context "with --pro --redux" do
    before(:all) { run_generator_test_with_args(%w[--pro --redux], package_json: true) }

    include_examples "base_generator_common", application_js: true
    include_examples "react_with_redux_generator"
    include_examples "pro_common_files"

    it "installs both Pro and Redux dependencies" do
      assert_file "package.json" do |content|
        package_json = JSON.parse(content)
        deps = package_json["dependencies"] || {}
        expect(deps).to include("react-on-rails-pro")
        expect(deps).to include("redux")
      end
    end
  end

  context "with --pro --typescript" do
    before(:all) { run_generator_test_with_args(%w[--pro --typescript], package_json: true) }

    include_examples "base_generator_common", application_js: true
    include_examples "no_redux_generator"
    include_examples "pro_common_files"

    it "creates TypeScript component files with .tsx extension" do
      assert_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.client.tsx"
      assert_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.server.tsx"
    end

    it "creates tsconfig.json file" do
      assert_file "tsconfig.json" do |content|
        config = JSON.parse(content)
        expect(config["compilerOptions"]["jsx"]).to eq("react-jsx")
      end
    end

    it "installs both Pro and TypeScript dependencies" do
      assert_file "package.json" do |content|
        package_json = JSON.parse(content)
        deps = package_json["dependencies"] || {}
        dev_deps = package_json["devDependencies"] || {}
        expect(deps).to include("react-on-rails-pro")
        expect(dev_deps).to include("typescript")
        expect(dev_deps).to include("@types/react")
      end
    end
  end

  context "with --pro --rspack" do
    before(:all) do
      run_generator_test_with_args(%w[--pro --rspack], package_json: true) do
        simulate_existing_file("config/shakapacker.yml", <<~YAML)
          # Note: You must restart bin/shakapacker-dev-server for changes to take effect
          default: &default
            source_path: app/javascript
            source_entry_path: packs
            public_root_path: public
            public_output_path: packs
            cache_path: tmp/shakapacker
            webpack_compile_output: true
            shakapacker_precompile: true
            additional_paths: []
            cache_manifest: false
            javascript_transpiler: "babel"
            assets_bundler: "webpack"
            # precompile_hook: ~

          development:
            <<: *default

          test:
            <<: *default
            compile: true

          production:
            <<: *default
        YAML
        simulate_existing_file("bin/shakapacker", "")
        simulate_existing_file("bin/shakapacker-dev-server", "")
        simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
          const { generateWebpackConfig } = require('shakapacker')
          const webpackConfig = generateWebpackConfig()
          module.exports = webpackConfig
        JS
      end
    end

    include_examples "base_generator", application_js: true
    include_examples "no_redux_generator"
    include_examples "pro_common_files"

    it "installs both Pro and Rspack dependencies" do
      assert_file "package.json" do |content|
        package_json = JSON.parse(content)
        deps = package_json["dependencies"] || {}
        expect(deps).to include("react-on-rails-pro")
        expect(deps).to include("@rspack/core")
      end
    end

    describe "Pro webpack config transforms in config/rspack/" do
      it "applies Pro transforms to serverWebpackConfig in config/rspack/" do
        assert_file "config/rspack/serverWebpackConfig.js" do |content|
          expect(content).to include("libraryTarget: 'commonjs2',")
          expect(content).to include("function extractLoader")
          expect(content).to include("serverWebpackConfig.target = 'node';")
          expect(content).to include("module.exports = {")
        end
      end

      it "updates ServerClientOrBoth to destructured import in config/rspack/" do
        assert_file "config/rspack/ServerClientOrBoth.js" do |content|
          expect(content).to include("{ default: serverWebpackConfig }")
        end
      end
    end
  end

  context "when Pro initializer already exists" do
    before(:all) do
      run_generator_test_with_args(%w[--pro], package_json: true) do
        simulate_existing_file("config/initializers/react_on_rails_pro.rb", "# existing Pro config\n")
      end
    end

    it "does not overwrite existing Pro initializer" do
      assert_file "config/initializers/react_on_rails_pro.rb" do |content|
        expect(content).to include("# existing Pro config")
        expect(content).not_to include("ReactOnRailsPro.configure")
      end
    end
  end

  context "when node-renderer.js already exists" do
    before(:all) do
      run_generator_test_with_args(%w[--pro], package_json: true) do
        simulate_existing_dir("renderer")
        simulate_existing_file("renderer/node-renderer.js", "// existing node-renderer\n")
      end
    end

    it "does not overwrite existing node-renderer.js" do
      assert_file "renderer/node-renderer.js" do |content|
        expect(content).to include("// existing node-renderer")
        expect(content).not_to include("reactOnRailsProNodeRenderer")
      end
    end

    # Regression: a new Pro initializer must not embed a fresh random literal
    # password when the existing Node renderer file already contains its own
    # literal — Rails and Node would otherwise disagree.
    it "creates the Pro initializer with env-only password (no literal) so it cannot mismatch the existing renderer" do
      assert_file "config/initializers/react_on_rails_pro.rb" do |content|
        expect(content).to include("ReactOnRailsPro.configure")
        expect(content).to include('config.renderer_password = ENV["RENDERER_PASSWORD"]')
        expect(content).not_to match(/ENV\.fetch\("RENDERER_PASSWORD",\s*"[^"]+"\)/)
      end
    end
  end

  context "when Procfile.dev already contains node-renderer" do
    let(:install_generator) { described_class.new([], { pro: true }, destination_root: "/fake/path") }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with("/fake/path/Procfile.dev").and_return(true)
      allow(File).to receive(:exist?).with("/fake/path/Procfile.dev-static-assets").and_return(false)
      allow(File).to receive(:exist?).with("/fake/path/Procfile.dev-prod-assets").and_return(false)
      allow(File).to receive(:read).with("/fake/path/Procfile.dev")
                                   .and_return("rails: bundle exec rails s\nnode-renderer: existing config\n")
    end

    specify "add_pro_to_procfiles does not append duplicate entry" do
      expect(install_generator).not_to receive(:append_to_file)
      install_generator.send(:add_pro_to_procfiles)
    end
  end

  context "when Procfile.dev exists without node-renderer" do
    let(:install_generator) { described_class.new([], { pro: true }, destination_root: "/fake/path") }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with("/fake/path/Procfile.dev").and_return(true)
      allow(File).to receive(:exist?).with("/fake/path/Procfile.dev-static-assets").and_return(false)
      allow(File).to receive(:exist?).with("/fake/path/Procfile.dev-prod-assets").and_return(false)
      allow(File).to receive(:read).with("/fake/path/Procfile.dev")
                                   .and_return("rails: bundle exec rails s\ndev-server: bin/shakapacker\n")
    end

    specify "add_pro_to_procfiles appends node-renderer entry" do
      expect(install_generator).to receive(:append_to_file).with("Procfile.dev", include("node-renderer:"))
      install_generator.send(:add_pro_to_procfiles)
    end
  end

  context "when Procfile.dev contains an unrelated renderer process" do
    let(:install_generator) { described_class.new([], { pro: true }, destination_root: "/fake/path") }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with("/fake/path/Procfile.dev").and_return(true)
      allow(File).to receive(:exist?).with("/fake/path/Procfile.dev-static-assets").and_return(false)
      allow(File).to receive(:exist?).with("/fake/path/Procfile.dev-prod-assets").and_return(false)
      allow(File).to receive(:read).with("/fake/path/Procfile.dev")
                                   .and_return("rails: bundle exec rails s\nrenderer: vite\n")
    end

    specify "add_pro_to_procfiles still appends node-renderer alongside" do
      expect(install_generator).to receive(:append_to_file).with("Procfile.dev", include("node-renderer:"))
      install_generator.send(:add_pro_to_procfiles)
    end
  end

  context "when Procfile.dev has a node-renderer entry that is missing RENDERER_PORT" do
    let(:install_generator) { described_class.new([], { pro: true }, destination_root: "/fake/path") }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with("/fake/path/Procfile.dev").and_return(true)
      allow(File).to receive(:exist?).with("/fake/path/Procfile.dev-static-assets").and_return(false)
      allow(File).to receive(:exist?).with("/fake/path/Procfile.dev-prod-assets").and_return(false)
      allow(File).to receive(:read).with("/fake/path/Procfile.dev")
                                   .and_return("rails: bundle exec rails s\n" \
                                               "node-renderer: node renderer/node-renderer.js\n")
    end

    specify "add_pro_to_procfiles surfaces an update-it-manually warning so the doctor agrees" do
      # The doctor's PROCESS_WITH_RENDERER_PORT_REGEX warns when an entry is missing
      # RENDERER_PORT, so the generator must not silently treat this as "already correct".
      expect(install_generator).not_to receive(:append_to_file)
      expect(install_generator).to receive(:say).with(
        a_string_matching(/has a renderer entry that doesn't reference/), :yellow
      )
      allow(install_generator).to receive(:say)
      install_generator.send(:add_pro_to_procfiles)
    end
  end

  context "with --rsc" do
    # Pin to --no-rspack so this context keeps exercising the Webpack RSC transforms.
    # Rspack is the default now and is covered by the "with --rsc --rspack" context.
    before(:all) { run_generator_test_with_args(%w[--rsc --no-rspack], package_json: true) }

    include_examples "rsc_common_files"
    include_examples "scaffold_ci_and_scripts"

    it "creates node-renderer.js" do
      assert_file "renderer/node-renderer.js" do |content|
        expect(content).to include("reactOnRailsProNodeRenderer")
        expect(content).to include("require('react-on-rails-pro-node-renderer')")
      end
    end

    it "adds RSC bundle watcher to Procfile.dev" do
      assert_file "Procfile.dev" do |content|
        expect(content).to include("RSC_BUNDLE_ONLY=true")
        expect(content).to include("rsc-bundle:")
        expect(content).to include("bin/shakapacker-watch --watch")
      end
    end

    it "installs RSC npm dependencies with matched version pins" do
      expected_npm_version = ReactOnRails::VersionSyntaxConverter.new.rubygem_to_npm(ReactOnRails::VERSION)

      assert_file "package.json" do |content|
        package_json = JSON.parse(content)
        deps = package_json["dependencies"] || {}
        assert_rsc_dependency_requirements(deps)
        expect(deps["react-on-rails-pro"]).to eq(expected_npm_version)
        expect(deps["react-on-rails-pro-node-renderer"]).to eq(expected_npm_version)
      end
    end

    it "creates rscWebpackConfig.js" do
      assert_file "config/webpack/rscWebpackConfig.js" do |content|
        expect(content).to include("const serverWebpackModule = require('./serverWebpackConfig')")
        expect(content).to include("const serverWebpackConfig = serverWebpackModule.default || serverWebpackModule")
        expect(content).to include("serverWebpackConfig(true)")
        expect(content).to include("rsc-bundle")
        expect(content).to include("react-server")
        expect(content).to include("const reactPackageRoot = dirname(require.resolve('react/package.json'))")
        expect(content).to include("const resolveReactServerEntry = (entryFilename) =>")
        expect(content).to include("existsSync(entryPath)")
        expect(content).to include("delete rscAliases.react")
        expect(content).to include("delete rscAliases['react$']")
        expect(content).to include("delete rscAliases['react/jsx-runtime']")
        expect(content).to include("delete rscAliases['react/jsx-runtime$']")
        expect(content).to include("delete rscAliases['react/jsx-dev-runtime']")
        expect(content).to include("delete rscAliases['react/jsx-dev-runtime$']")
        expect(content).to include("delete rscAliases['react-dom/server']")
        expect(content).to include("delete rscAliases['react-dom/server$']")
        expect(content).to include("react$: resolveReactServerEntry('react.react-server.js')")
        expect(content).to include("'react/jsx-runtime$': resolveReactServerEntry('jsx-runtime.react-server.js')")
        expect(content).to include(
          "'react/jsx-dev-runtime$': resolveReactServerEntry('jsx-dev-runtime.react-server.js')"
        )
        expect(content).to include("process.env.REACT_ON_RAILS_RSC_REGISTRATION_ENTRY_PATH")
        expect(content).to include("defaultServerComponentRegistrationEntry")
      end
    end

    it "serverWebpackConfig includes RSCWebpackPlugin import" do
      assert_file "config/webpack/serverWebpackConfig.js" do |content|
        expect(content).to include("RSCWebpackPlugin")
        expect(content).to include("react-on-rails-rsc/WebpackPlugin")
        expect(content).to include("clientReferences: rscClientReferences")
        expect(content).to include("directory: resolve(config.source_path)")
      end
    end

    it "serverWebpackConfig has rscBundle parameter" do
      assert_file "config/webpack/serverWebpackConfig.js" do |content|
        expect(content).to match(/configureServer\s*=\s*\(rscBundle\s*=\s*false\)/)
        expect(content).to include("if (!rscBundle)")
      end
    end

    it "creates HelloServer instead of HelloWorld (controller, route, and components)" do
      # HelloWorld should NOT exist - HelloServer replaces it entirely
      assert_no_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.client.jsx"
      assert_no_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.server.jsx"
      assert_no_file "app/controllers/hello_world_controller.rb"
      assert_file "config/routes.rb" do |content|
        expect(content).not_to include("hello_world")
      end

      # HelloServer should exist
      assert_file "app/javascript/src/HelloServer/ror_components/HelloServer.jsx"
      assert_file "app/javascript/src/HelloServer/components/HelloServer.jsx"
      assert_file "app/javascript/src/HelloServer/components/LikeButton.jsx"
    end

    include_examples "rsc_hello_server_files"

    it "adds HelloServer route" do
      assert_file "config/routes.rb" do |content|
        expect(content).to include("hello_server")
        expect(content).to include("rsc_payload")
      end
    end

    it "sets DEFAULT_ROUTE to hello_server in bin/dev" do
      assert_file "bin/dev" do |content|
        expect(content).to include('DEFAULT_ROUTE = "hello_server"')
      end
    end
  end

  describe "#add_rsc_dependencies" do
    let(:install_generator) { described_class.new([], { rsc: true }, destination_root:) }
    let(:rsc_pin) { ReactOnRails::Generators::JsDependencyManager::RSC_PACKAGE_VERSION_PIN }

    before do
      GeneratorMessages.clear
      allow(install_generator).to receive(:say)
      allow(install_generator).to receive(:fallback_package_manager).and_return("pnpm")
    end

    it "explains why every RSC install is pinned to the stable package" do
      allow(install_generator).to receive(:add_packages).and_return(true)

      install_generator.send(:add_rsc_dependencies)

      message_text = GeneratorMessages.messages.join("\n")
      expect(message_text).to include("all --rsc installs")
      expect(message_text).to include("react-on-rails-rsc@#{rsc_pin}")
      expect(message_text).to include("react-on-rails-rsc/RspackPlugin")
      expect(message_text).to include("Webpack")
      expect(message_text).not_to include("temporarily")
      expect(message_text).not_to include("prerelease")
      expect(message_text).not_to include("until stable")
    end

    it "keeps the version pin and uses the detected package manager when manual RSC recovery is needed" do
      allow(install_generator).to receive(:add_packages).and_return(false)

      install_generator.send(:add_rsc_dependencies)

      warning_text = GeneratorMessages.messages.join("\n")
      expect(warning_text).to include("pnpm add --save-exact react-on-rails-rsc@#{rsc_pin}")
      expect(warning_text).to include("left the version pin in package.json")
      expect(warning_text).not_to include("npm install react-on-rails-rsc")
      expect(warning_text).not_to include("Retrying latest available package")
    end

    it "uses yarn add syntax in the RSC pin failure warning when yarn is detected" do
      allow(install_generator).to receive_messages(
        add_packages: false,
        fallback_package_manager: "yarn"
      )

      install_generator.send(:add_rsc_dependencies)

      warning_text = GeneratorMessages.messages.join("\n")
      expect(warning_text).to include("yarn add --exact react-on-rails-rsc@#{rsc_pin}")
      expect(warning_text).not_to include("npm install react-on-rails-rsc")
    end
  end

  context "with --new-app and a preexisting root route" do
    before(:all) do
      run_generator_test_with_args(%w[--new-app], package_json: true) do
        simulate_existing_file("config/routes.rb", <<~RUBY)
          Rails.application.routes.draw do
            root to: "existing#home"
          end
        RUBY
      end
    end

    it "keeps the existing root route and does not scaffold the landing page" do
      assert_file "config/routes.rb" do |content|
        expect(content).to include('root to: "existing#home"')
        expect(content).not_to include('root to: "home#index"')
      end

      assert_no_file "app/controllers/home_controller.rb"
      assert_no_file "app/views/home/index.html.erb"
    end

    it "still uses the root path in bin/dev" do
      assert_file "bin/dev" do |content|
        expect(content).to include('DEFAULT_ROUTE = "/"')
      end
    end
  end

  context "with --new-app routes.rb in an unexpected format" do
    before(:all) do
      run_generator_test_with_args(%w[--new-app], package_json: true) do
        simulate_existing_file("config/routes.rb", "draw_routes do\nend\n")
      end
    end

    it "skips the landing page and falls back to the hello_world route in bin/dev" do
      assert_file "config/routes.rb" do |content|
        expect(content).not_to include('root to: "home#index"')
      end

      assert_no_file "app/controllers/home_controller.rb"
      assert_no_file "app/views/home/index.html.erb"

      assert_file "bin/dev" do |content|
        expect(content).to include('DEFAULT_ROUTE = "hello_world"')
      end
    end

    it "does not render a broken return-to-home quick link on the SSR demo page" do
      assert_file "app/views/hello_world/index.html.erb" do |content|
        expect(content).not_to include("Return to the generated home page")
      end
    end
  end

  context "with --new-app --rsc" do
    before(:all) { run_generator_test_with_args(%w[--new-app --rsc], package_json: true) }

    it "creates a landing page that links to the RSC example" do
      assert_file "config/routes.rb" do |content|
        expect(content).to include('root to: "home#index"')
      end
      assert_file "app/views/home/index.html.erb" do |content|
        expect(content).to include("/hello_server")
        expect(content).to include("React Server Components")
        expect(content).to include("https://reactonrails.com/docs/pro/react-server-components/tutorial/")
        expect(content).to include("https://github.com/shakacode/react-on-rails-demo-marketplace-rsc")
      end
    end

    it "keeps the root path as the default bin/dev URL" do
      assert_file "bin/dev" do |content|
        expect(content).to include('DEFAULT_ROUTE = "/"')
        expect(content).to include("AUTO_OPEN_BROWSER_ONCE = true")
      end
    end

    it "adds a return link from the RSC demo to the landing page" do
      assert_file "app/views/hello_server/index.html.erb" do |content|
        expect(content).to include("Return to the generated home page")
      end
    end
  end

  context "with --rsc --redux" do
    before(:all) { run_generator_test_with_args(%w[--rsc --redux], package_json: true) }

    include_examples "react_with_redux_generator"
    include_examples "rsc_common_files"

    it "creates both HelloWorldApp and HelloServer" do
      assert_file "app/javascript/src/HelloWorldApp/ror_components/HelloWorldApp.client.jsx"
      assert_file "app/javascript/src/HelloWorldApp/ror_components/HelloWorldApp.server.jsx"
      assert_file "app/javascript/src/HelloServer/ror_components/HelloServer.jsx"
      assert_file "app/javascript/src/HelloServer/components/HelloServer.jsx"
      assert_file "app/javascript/src/HelloServer/components/LikeButton.jsx"
    end

    it "links the Redux SSR demo to the RSC demo" do
      assert_file "app/views/hello_world/index.html.erb" do |content|
        expect(content).to include("/hello_server")
        expect(content).to include("Open the RSC demo")
      end
    end

    it "creates hello_world route and controller for Redux" do
      assert_file "config/routes.rb" do |content|
        expect(content).to include("hello_world")
      end
      assert_file "app/controllers/hello_world_controller.rb"
    end

    it "installs both RSC and Redux dependencies" do
      assert_file "package.json" do |content|
        package_json = JSON.parse(content)
        deps = package_json["dependencies"] || {}
        expect(deps).to include("react-on-rails-rsc")
        expect(deps).to include("redux")
      end
    end

    include_examples "rsc_hello_server_files"
  end

  context "with --rsc --typescript" do
    before(:all) { run_generator_test_with_args(%w[--rsc --typescript], package_json: true) }

    include_examples "rsc_common_files"

    it "creates TypeScript HelloServer component" do
      assert_no_file "app/javascript/src/HelloServer/ror_components/HelloServer.jsx"
      assert_no_file "app/javascript/src/HelloServer/components/HelloServer.jsx"
      assert_file "app/javascript/src/HelloServer/ror_components/HelloServer.tsx"
      assert_file "app/javascript/src/HelloServer/components/HelloServer.tsx"
      assert_file "app/javascript/src/HelloServer/components/LikeButton.tsx"
    end

    it "creates tsconfig.json file" do
      assert_file "tsconfig.json" do |content|
        config = JSON.parse(content)
        expect(config["compilerOptions"]["jsx"]).to eq("react-jsx")
      end
    end

    it "installs both RSC and TypeScript dependencies" do
      assert_file "package.json" do |content|
        package_json = JSON.parse(content)
        deps = package_json["dependencies"] || {}
        dev_deps = package_json["devDependencies"] || {}
        expect(deps).to include("react-on-rails-rsc")
        expect(dev_deps).to include("typescript")
        expect(dev_deps).to include("@types/react")
      end
    end

    include_examples "rsc_hello_server_files"
  end

  context "with --rsc --rspack --tailwind --typescript" do
    before(:all) { run_generator_test_with_args(%w[--rsc --rspack --tailwind --typescript], package_json: true) }

    include_examples "rsc_common_files", tailwind: true

    it "wires Tailwind into the generated RSC client component" do
      assert_no_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.client.tsx"
      assert_tailwind_rsc_setup(config_dir: "config/rspack", extension: "tsx")
    end
  end

  context "with --rsc --rspack" do
    before(:all) { run_generator_test_with_args(%w[--rsc --rspack], package_json: true) }

    include_examples "rsc_common_files"

    it "creates rscWebpackConfig.js in config/rspack/ (not config/webpack/)" do
      assert_file "config/rspack/rscWebpackConfig.js" do |content|
        expect(content).to include("serverWebpackConfig(true)")
      end
      assert_no_file "config/webpack/rscWebpackConfig.js"
    end

    describe "RSC webpack config transforms in config/rspack/" do
      it "adds the native RSCRspackPlugin to serverWebpackConfig" do
        assert_file "config/rspack/serverWebpackConfig.js" do |content|
          expect(content).to include("RSCRspackPlugin")
          expect(content).to include("react-on-rails-rsc/RspackPlugin")
          expect(content).to include("clientReferences: rscClientReferences")
          expect(content).to include("directory: resolve(config.source_path)")
          # Native rspack plugin replaces the webpack plugin entirely under rspack.
          expect(content).not_to include("RSCWebpackPlugin")
          expect(content).not_to include("react-on-rails-rsc/WebpackPlugin")
        end
      end

      it "adds the native RSCRspackPlugin to clientWebpackConfig" do
        assert_file "config/rspack/clientWebpackConfig.js" do |content|
          expect(content).to include("RSCRspackPlugin")
          expect(content).to include("react-on-rails-rsc/RspackPlugin")
          expect(content).to include("clientReferences: rscClientReferences")
          expect(content).to include("directory: resolve(config.source_path)")
          expect(content).not_to include("RSCWebpackPlugin")
          expect(content).not_to include("react-on-rails-rsc/WebpackPlugin")
        end
      end

      it "adds RSC handling to ServerClientOrBoth" do
        assert_file "config/rspack/ServerClientOrBoth.js" do |content|
          expect(content).to include("rscWebpackConfig")
          expect(content).to include("RSC_BUNDLE_ONLY")
          expect(content).to include("rscConfig")
        end
      end

      it "disables Rspack lazy compilation while serving RSC apps" do
        assert_file "config/rspack/development.js" do |content|
          expect(content).to include(
            "const developmentEnvOnly = (clientWebpackConfig, _serverWebpackConfig, rscWebpackConfig)"
          )
          expect(content).to include("if (rscWebpackConfig)")
          expect(content).to include("clientWebpackConfig.lazyCompilation = false")
          expect(content).not_to include("existsSync(resolve(__dirname, 'rscWebpackConfig.js'))")
        end
      end

      it "checks RSC discovery support in the generated Rspack config directory" do
        assert_file "config/rspack/clientWebpackConfig.js" do |content|
          expect(content).to include("const rscWebpackConfig = resolve(__dirname, 'rscWebpackConfig.js')")
          expect(content).not_to include("config/webpack/rscWebpackConfig.js")
        end
      end
    end

    it "installs both RSC and Rspack dependencies" do
      assert_file "package.json" do |content|
        package_json = JSON.parse(content)
        deps = package_json["dependencies"] || {}
        assert_rsc_dependency_requirements(deps)
        expect(deps).to include("@rspack/core")
      end
    end

    include_examples "rsc_hello_server_files"
  end

  context "when rscWebpackConfig.js already exists" do
    before(:all) do
      run_generator_test_with_args(%w[--rsc], package_json: true) do
        simulate_existing_dir("config/webpack")
        simulate_existing_file("config/webpack/rscWebpackConfig.js", "// existing RSC config\n")
      end
    end

    it "does not overwrite existing rscWebpackConfig.js" do
      assert_file "config/webpack/rscWebpackConfig.js" do |content|
        expect(content).to include("// existing RSC config")
        expect(content).not_to include("serverWebpackConfig(true)")
      end
    end
  end

  context "when .github/workflows/ci.yml already exists" do
    before(:all) do
      run_generator_test_with_args(%w[], package_json: true, force: false) do
        simulate_existing_dir(".github/workflows")
        simulate_existing_file(".github/workflows/ci.yml", "# custom CI\n")
      end
    end

    it "does not overwrite existing CI workflow" do
      assert_file ".github/workflows/ci.yml" do |content|
        expect(content).to include("# custom CI")
        expect(content).not_to include("actions/checkout")
      end
    end
  end

  context "when package.json already defines build and build:test scripts" do
    before(:all) do
      existing_package_json = JSON.pretty_generate(
        "name" => "existing-app",
        "private" => true,
        "scripts" => {
          "build" => "custom-build",
          "build:test" => "custom-build-test"
        }
      )
      run_generator_test_with_args(%w[], package_json: true) do
        simulate_existing_file("package.json", "#{existing_package_json}\n")
      end
    end

    it "preserves the user's existing build and build:test scripts" do
      assert_file "package.json" do |content|
        scripts = JSON.parse(content).fetch("scripts", {})
        expect(scripts["build"]).to eq("custom-build")
        expect(scripts["build:test"]).to eq("custom-build-test")
      end
    end
  end

  context "when package.json has scripts after other top-level keys" do
    before(:all) do
      # Real-world layout: "name", "version", etc. come before "scripts". The
      # previous indent regex anchored to `\A\{\n` and silently fell back to
      # column 0 for the closing `}` of the scripts block.
      existing_package_json = <<~JSON
        {
          "name": "existing-app",
          "version": "0.1.0",
          "private": true,
          "scripts": {
            "lint": "eslint src"
          },
          "devDependencies": {}
        }
      JSON
      run_generator_test_with_args(%w[], package_json: true) do
        simulate_existing_file("package.json", existing_package_json)
      end
    end

    it "indents the rebuilt scripts block under the surrounding object" do
      assert_file "package.json" do |content|
        # The closing `}` of the scripts block must align with two-space indent,
        # not be emitted at column 0.
        expect(content).to match(/\n {2}},\n {2}"devDependencies"/)
        scripts = JSON.parse(content).fetch("scripts", {})
        expect(scripts.keys).to include("lint", "build", "build:test")
      end
    end
  end

  context "when an existing script value contains a literal `}`" do
    before(:all) do
      # `[^}]*` would have matched the `}` inside "lint" and produced invalid JSON.
      # The brace-depth walker must respect string literals.
      existing_package_json = <<~JSON
        {
          "name": "existing-app",
          "scripts": {
            "lint": "eslint '{src,test}/**/*.js'"
          }
        }
      JSON
      run_generator_test_with_args(%w[], package_json: true) do
        simulate_existing_file("package.json", existing_package_json)
      end
    end

    it "produces valid JSON and preserves the brace-containing script value" do
      assert_file "package.json" do |content|
        parsed = JSON.parse(content)
        expect(parsed.fetch("scripts", {})["lint"]).to eq("eslint '{src,test}/**/*.js'")
        expect(parsed.fetch("scripts", {}).keys).to include("build", "build:test")
      end
    end
  end

  context "when Active Record is absent (no config/database.yml)" do
    before(:all) do
      run_generator_test_with_args(%w[], package_json: true) do
        # Remove the database.yml that simulate_existing_rails_files creates
        FileUtils.rm_f(File.join(destination_root, "config/database.yml"))
      end
    end

    it "CI workflow omits db:prepare step" do
      assert_file ".github/workflows/ci.yml" do |content|
        expect(content).not_to include("db:prepare")
      end
    end
  end

  context "when yarn is the detected package manager" do
    before(:all) do
      run_generator_test_with_args(%w[], package_json: true) do
        simulate_existing_file("yarn.lock", "")
      end
    end

    # Yarn Berry requires Corepack to be enabled before actions/setup-node so
    # the `cache: "yarn"` option can resolve Yarn Berry's cache directory.
    it "runs Enable Corepack before actions/setup-node" do
      assert_file ".github/workflows/ci.yml" do |content|
        corepack_pos = content.index("Enable Corepack")
        setup_node_pos = content.index("actions/setup-node@v4")
        expect(corepack_pos).not_to be_nil
        expect(setup_node_pos).not_to be_nil
        expect(corepack_pos).to be < setup_node_pos
      end
    end
  end

  context "when packageManager declares pnpm but only yarn.lock exists" do
    before(:all) do
      run_generator_test_with_args(%w[], package_json: true) do
        # User declared pnpm via Corepack but hasn't committed pnpm-lock.yaml yet —
        # only a stale yarn.lock is on disk. `cache: "pnpm"` would fail setup-node.
        simulate_existing_file("yarn.lock", "")
        simulate_existing_file(
          "package.json",
          "#{JSON.pretty_generate('name' => 'app', 'packageManager' => 'pnpm@9.0.0')}\n"
        )
      end
    end

    it "omits cache when no lockfile exists for the detected package manager" do
      assert_file ".github/workflows/ci.yml" do |content|
        expect(content).not_to include('cache: "pnpm"')
        # Falls back to frozen-lockfile-safe install so the workflow still runs.
        expect(content).to include("pnpm install --no-frozen-lockfile")
      end
    end

    it "omits the pnpm fallback version when packageManager is declared" do
      assert_file ".github/workflows/ci.yml" do |content|
        expect(content).to include("uses: pnpm/action-setup@v4")
        # `pnpm/action-setup` reads the version from `packageManager` when declared,
        # so the scaffold must not inject a `with: version:` that would override it.
        # Mirrors the regex used in the "pins a pnpm version" test, minus the value.
        expect(content).not_to match(
          %r{pnpm/action-setup@v4\n\s+with:\n(?:\s+\#[^\n]*\n)*\s+version:}
        )
        expect(content).to match(
          %r{uses: pnpm/action-setup@v4\n\s+- name: Set up Node}
        )
      end
    end
  end

  context "when pnpm is detected from lockfile only (no packageManager field)" do
    before(:all) do
      # Existing Shakapacker app: pre-create binaries + config so `ensure_shakapacker_installed`
      # short-circuits and the `seed_package_manager_in_package_json_from_lockfile!` path
      # (which would otherwise add `packageManager` to package.json) is skipped.
      run_generator_test_with_args(%w[], package_json: true) do
        simulate_existing_file("pnpm-lock.yaml", "")
        simulate_existing_file("bin/shakapacker", "")
        simulate_existing_file("bin/shakapacker-dev-server", "")
        simulate_existing_file("config/shakapacker.yml", "default: &default\n")
        simulate_existing_file("config/webpack/webpack.config.js", "")
      end
    end

    # Issue #3172: pnpm/action-setup@v4 requires `version:` unless packageManager is declared.
    # Existing Shakapacker apps skip the seeding path, so the CI scaffold has to pin the
    # version itself or the workflow fails before dependency install.
    it "pins a pnpm version in the setup step" do
      fallback_version = repo_pinned_pnpm_version

      assert_file ".github/workflows/ci.yml" do |content|
        expect(content).to include("uses: pnpm/action-setup@v4")
        expect(content).to match(
          %r{pnpm/action-setup@v4\n\s+with:\n(?:\s+\#[^\n]*\n)*\s+version: "#{Regexp.escape(fallback_version)}"}
        )
        expect(content).to match(
          /version: "#{Regexp.escape(fallback_version)}"\n\s+- name: Set up Node/
        )
      end
    end
  end

  it "keeps the fallback pin tied to a version-specific pnpm release note" do
    fallback_version = repo_pinned_pnpm_version
    next_pnpm_major = fallback_version.split(".").first.to_i + 1
    expected_renovate_directive =
      "renovate: datasource=github-releases depName=pnpm/pnpm " \
      "extractVersion=^v(?<version>.+)$ allowedVersions=<#{next_pnpm_major}"
    renovate_directive_mismatch_message =
      "Renovate directive in install_generator.rb must match allowedVersions=<#{next_pnpm_major} " \
      "(derived from repo pnpm major). Update the # renovate: comment line when bumping " \
      "CI_PNPM_FALLBACK_VERSION."
    fallback_guide_heading = "Updating the pnpm Fallback Version for Scaffolded CI"
    contributing_guide = File.read(
      File.expand_path("../../../../CONTRIBUTING.md", __dir__)
    )
    generator_source = File.read(
      File.expand_path("../../../lib/generators/react_on_rails/install_generator.rb", __dir__)
    )

    expect(fallback_version).to match(/\A\d+\.\d+\.\d+\z/)
    expect(generator_source).to include(%(CI_PNPM_FALLBACK_VERSION = "#{fallback_version}"))
    expect(generator_source).to include(
      "https://github.com/pnpm/pnpm/releases/tag/v#{fallback_version}"
    )
    # Keep the full directive in source order so failures point at the exact Renovate comment to update.
    expect(generator_source).to include(expected_renovate_directive), renovate_directive_mismatch_message
    expect(generator_source).to include(
      "renovate: datasource=github-releases depName=pnpm/pnpm"
    )
    expect(generator_source).to include(
      %(CONTRIBUTING.md > "#{fallback_guide_heading}")
    )
    expect(contributing_guide).to include("## #{fallback_guide_heading}")
  end

  context "when env selects pnpm but packageManager declares yarn" do
    around do |example|
      previous_package_manager = ENV.fetch("REACT_ON_RAILS_PACKAGE_MANAGER", nil)
      ENV["REACT_ON_RAILS_PACKAGE_MANAGER"] = "pnpm"
      run_generator_test_with_args(%w[], package_json: true) do
        simulate_existing_file("pnpm-lock.yaml", "")
        simulate_existing_file("bin/shakapacker", "")
        simulate_existing_file("bin/shakapacker-dev-server", "")
        simulate_existing_file("config/shakapacker.yml", "default: &default\n")
        simulate_existing_file("config/webpack/webpack.config.js", "")
        simulate_existing_file(
          "package.json",
          "#{JSON.pretty_generate('name' => 'app', 'packageManager' => 'yarn@1.22.0')}\n"
        )
      end

      example.run
    ensure
      if previous_package_manager.nil?
        ENV.delete("REACT_ON_RAILS_PACKAGE_MANAGER")
      else
        ENV["REACT_ON_RAILS_PACKAGE_MANAGER"] = previous_package_manager
      end
    end

    it "pins the pnpm fallback version in the setup step" do
      fallback_version = repo_pinned_pnpm_version

      assert_file ".github/workflows/ci.yml" do |content|
        expect(content).to include("uses: pnpm/action-setup@v4")
        expect(content).to match(
          %r{pnpm/action-setup@v4\n\s+with:\n(?:\s+\#[^\n]*\n)*\s+version: "#{Regexp.escape(fallback_version)}"}
        )
      end
    end
  end

  # Yarn (Berry) on first CI run without a committed lockfile is covered indirectly
  # by the pnpm test above and by unit tests for GeneratorMessages.lockfile_for_manager?.
  # An end-to-end yarn test is not reliable here because yarn 1.x is globally installed
  # in the spec environment and `setup_js_dependencies` creates yarn.lock before the
  # CI template renders, defeating the "no lockfile" scenario.

  context "when Procfile.dev already contains RSC watcher" do
    let(:install_generator) { described_class.new([], { rsc: true }, destination_root: "/fake/path") }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with("/fake/path/Procfile.dev").and_return(true)
      procfile_content = "rails: bundle exec rails s\nrsc-bundle: RSC_BUNDLE_ONLY=true bin/shakapacker\n"
      allow(File).to receive(:read).with("/fake/path/Procfile.dev").and_return(procfile_content)
    end

    specify "add_rsc_to_procfile does not append duplicate entry" do
      expect(install_generator).not_to receive(:append_to_file)
      install_generator.send(:add_rsc_to_procfile)
    end
  end

  describe "interactive Pro selection" do
    it "defaults to Pro when an existing-app user accepts the interactive prompt" do
      install_generator = install_generator_fixture
      allow(install_generator).to receive_messages(interactive_install_session?: true, ask: "")
      allow(install_generator).to receive(:say)

      install_generator.send(:prompt_for_pro_features_if_applicable)

      expect(install_generator.send(:use_pro?)).to be(true)
      expect(install_generator.send(:use_rsc?)).to be_falsey
      expect(install_generator).to have_received(:ask).with(
        a_string_including("Enable React on Rails Pro features", "RSC available separately", "[Y/n]"),
        :cyan
      )
    end

    it "keeps Pro off when an existing-app user answers no" do
      install_generator = install_generator_fixture
      allow(install_generator).to receive_messages(interactive_install_session?: true, ask: "n")
      allow(install_generator).to receive(:say)

      install_generator.send(:prompt_for_pro_features_if_applicable)

      expect(install_generator.send(:use_pro?)).to be(false)
    end

    it "prints the trust-license note and upgrade documentation before asking" do
      install_generator = install_generator_fixture
      allow(install_generator).to receive_messages(interactive_install_session?: true, ask: "Y")
      allow(install_generator).to receive(:say)

      install_generator.send(:prompt_for_pro_features_if_applicable)

      expect(install_generator).to have_received(:say)
        .with(a_string_including("free for evaluation", "production use requires a subscription"))
      expect(install_generator).to have_received(:say)
        .with(a_string_including("https://reactonrails.com/docs/pro/upgrading-to-pro/"))
    end

    it "preserves the noninteractive Pro-off default without asking" do
      install_generator = install_generator_fixture
      allow(install_generator).to receive(:interactive_install_session?).and_return(false)

      expect(install_generator).not_to receive(:ask)

      install_generator.send(:prompt_for_pro_features_if_applicable)

      expect(install_generator.send(:use_pro?)).to be_falsey
    end

    it "does not prompt on the new-app path" do
      install_generator = install_generator_fixture(new_app: true)
      allow(install_generator).to receive(:interactive_install_session?).and_return(true)

      expect(install_generator).not_to receive(:ask)

      install_generator.send(:prompt_for_pro_features_if_applicable)
    end

    it "does not prompt in CI even when stdin and stdout are TTYs" do
      install_generator = install_generator_fixture
      allow($stdin).to receive(:tty?).and_return(true)
      allow($stdout).to receive(:tty?).and_return(true)
      allow(install_generator).to receive(:ask)

      original_ci = ENV.fetch("CI", nil)
      ENV["CI"] = "true"
      install_generator.send(:prompt_for_pro_features_if_applicable)

      expect(install_generator).not_to have_received(:ask)
      expect(install_generator.send(:use_pro?)).to be(false)
    ensure
      original_ci.nil? ? ENV.delete("CI") : ENV["CI"] = original_ci
    end

    {
      { pro: true } => true,
      { pro: false } => false,
      { rsc: true } => true,
      { rsc: false } => false,
      { standard_only: true } => false
    }.each do |product_options, expected_pro|
      it "does not prompt when #{product_options.inspect} makes the product choice explicit" do
        install_generator = install_generator_fixture(product_options)
        allow(install_generator).to receive(:interactive_install_session?).and_return(true)

        expect(install_generator).not_to receive(:ask)

        install_generator.send(:prompt_for_pro_features_if_applicable)

        expect(install_generator.send(:use_pro?)).to eq(expected_pro)
      end
    end

    standard_only_options = { standard_only: true }
    [{ pro: true }, { rsc: true }].each do |pro_option|
      it "rejects --standard-only combined with #{pro_option.inspect}" do
        install_generator = install_generator_fixture(standard_only_options.merge(pro_option))

        expect do
          install_generator.send(:prompt_for_pro_features_if_applicable)
        end.to raise_error(Thor::Error, /--standard-only cannot be combined/)
      end
    end
  end

  context "with helpful message" do
    before do
      # Clear any previous messages to ensure clean test state
      GeneratorMessages.clear
    end

    specify "base generator contains a helpful message" do
      run_generator_test_with_args(%w[], package_json: true) do
        simulate_existing_file("bin/shakapacker", "")
        simulate_existing_file("bin/shakapacker-dev-server", "")
        simulate_existing_file("config/shakapacker.yml", "default: {}\n")
        simulate_existing_file("config/webpack/webpack.config.js", "// mock webpack config\n")
      end
      # Check that the success message is present (flexible matching)
      output_text = GeneratorMessages.output.join("\n")
      expect(output_text).to include("🎉 React on Rails Successfully Installed!")
      expect(output_text).to include("📋 QUICK START:")
      expect(output_text).to include("✨ KEY FEATURES:")
      expect(output_text).to match(/bundle && (npm|yarn|pnpm) install/)
      expect(output_text).to include("💡 TIP: Run 'bin/dev help'")
    end

    specify "react with redux generator contains a helpful message" do
      run_generator_test_with_args(%w[--redux], package_json: true) do
        simulate_existing_file("bin/shakapacker", "")
        simulate_existing_file("bin/shakapacker-dev-server", "")
        simulate_existing_file("config/shakapacker.yml", "default: {}\n")
        simulate_existing_file("config/webpack/webpack.config.js", "// mock webpack config\n")
      end
      # Check that the success message is present (flexible matching)
      output_text = GeneratorMessages.output.join("\n")
      expect(output_text).to include("🎉 React on Rails Successfully Installed!")
      expect(output_text).to include("📋 QUICK START:")
      expect(output_text).to include("✨ KEY FEATURES:")
      expect(output_text).to match(/bundle && (npm|yarn|pnpm) install/)
      expect(output_text).to include("💡 TIP: Run 'bin/dev help'")
    end

    specify "run_generators adds post-install messaging for redux installs" do
      install_generator = install_generator_fixture(redux: true)
      allow(install_generator).to receive(:installation_prerequisites_met?).and_return(true)
      allow(install_generator).to receive(:invoke_generators)
      allow(install_generator).to receive(:add_bin_scripts)
      allow(install_generator).to receive(:print_generator_messages)

      expect(install_generator).to receive(:add_post_install_message)
      install_generator.run_generators
    end

    specify "run_generators warns hidden redux users when prerequisites fail" do
      install_generator = install_generator_fixture(redux: true)
      allow(install_generator).to receive(:installation_prerequisites_met?).and_return(false)
      allow(install_generator).to receive(:print_generator_messages)

      install_generator.run_generators
      output_text = GeneratorMessages.messages.join("\n")

      expect(output_text).to include("legacy Redux generator path")
      expect(output_text).to include("React on Rails generator prerequisites not met")
      expect(output_text.index("legacy Redux generator path"))
        .to be > output_text.index("React on Rails generator prerequisites not met")
    end

    specify "shows incomplete-installation guidance when shakapacker setup fails" do
      install_generator = install_generator_fixture
      install_generator.instance_variable_set(:@shakapacker_setup_incomplete, true)

      install_generator.send(:add_post_install_message)
      output_text = GeneratorMessages.output.join("\n")

      expect(output_text).to include("React on Rails installation is incomplete")
      expect(output_text).to include("Avoid running ./bin/dev")
      expect(output_text).to include("Some generator files may have been partially created during this run")
      expect(output_text).to include("clean up your working tree before rerunning")
      expect(output_text).to include("commit, stash, or discard the partial changes")
      expect(output_text).to include("--ignore-warnings")
      expect(output_text).not_to include("🎉 React on Rails Successfully Installed!")
      expect(output_text).not_to include("📋 QUICK START:")
    end

    specify "incomplete-installation guidance uses detected package manager install command" do
      install_generator = install_generator_fixture
      install_generator.instance_variable_set(:@shakapacker_setup_incomplete, true)
      allow(GeneratorMessages).to receive(:detect_package_manager).and_return("pnpm")

      install_generator.send(:add_post_install_message)
      output_text = GeneratorMessages.output.join("\n")

      expect(output_text).to include("pnpm install")
    end

    specify "incomplete-installation guidance preserves original install flags" do
      install_generator = install_generator_fixture(redux: true, typescript: true, rspack: true, rsc: true)
      install_generator.instance_variable_set(:@shakapacker_setup_incomplete, true)

      install_generator.send(:add_post_install_message)
      output_text = GeneratorMessages.output.join("\n")

      expect(output_text).to include("rails generate react_on_rails:install --redux --typescript --rspack --rsc")
      expect(output_text).not_to include(
        "rails generate react_on_rails:install --redux --typescript --rspack --rsc --ignore-warnings"
      )
    end

    specify "post-install message disables landing-page hints when root route is unavailable" do
      install_generator = install_generator_fixture(new_app: true)
      allow(install_generator).to receive_messages(
        shakapacker_setup_incomplete?: false,
        new_app_root_route_available?: false,
        use_rsc?: false,
        use_pro?: false,
        shakapacker_just_installed?: false
      )

      allow(GeneratorMessages).to receive(:helpful_message_after_installation)
        .with(hash_including(landing_page: false))
        .and_return("stubbed")
      allow(GeneratorMessages).to receive(:add_info)

      install_generator.send(:add_post_install_message)

      expect(GeneratorMessages).to have_received(:helpful_message_after_installation)
        .with(hash_including(landing_page: false))
      expect(GeneratorMessages).to have_received(:add_info).with("stubbed")
    end

    specify "recovery_install_command keeps meaningful flags only" do
      install_generator = install_generator_fixture(
        redux: true,
        typescript: true,
        tailwind: true,
        rspack: true,
        rsc: true,
        pro: true,
        ignore_warnings: true,
        force: true,
        skip: true,
        pretend: true
      )

      command = install_generator.send(:recovery_install_command)

      expect(command).to eq("rails generate react_on_rails:install --redux --typescript --tailwind --rspack --rsc")
      expect(command).not_to include("--ignore-warnings")
      expect(command).not_to include("--force")
      expect(command).not_to include("--skip")
      expect(command).not_to include("--pretend")
      expect(command).not_to include("--pro")
    end

    specify "recovery_install_command includes --pro when requested without --rsc" do
      install_generator = install_generator_fixture(pro: true)

      command = install_generator.send(:recovery_install_command)

      expect(command).to eq("rails generate react_on_rails:install --pro")
    end

    specify "recovery_install_command preserves an accepted interactive Pro selection" do
      install_generator = install_generator_fixture
      allow(install_generator).to receive_messages(interactive_install_session?: true, ask: "Y")
      allow(install_generator).to receive(:say)
      install_generator.send(:prompt_for_pro_features_if_applicable)

      expect(install_generator.send(:recovery_install_command)).to eq(
        "rails generate react_on_rails:install --pro"
      )
    end

    specify "recovery_install_command preserves a declined interactive Pro selection" do
      install_generator = install_generator_fixture
      allow(install_generator).to receive_messages(interactive_install_session?: true, ask: "n")
      allow(install_generator).to receive(:say)
      install_generator.send(:prompt_for_pro_features_if_applicable)

      expect(install_generator.send(:recovery_install_command)).to eq(
        "rails generate react_on_rails:install --standard-only"
      )
    end

    {
      { pro: false } => "--no-pro",
      { rsc: false } => "--no-rsc",
      { standard_only: true } => "--standard-only"
    }.each do |product_options, expected_flag|
      specify "recovery_install_command preserves #{product_options.inspect}" do
        install_generator = install_generator_fixture(product_options)

        expect(install_generator.send(:recovery_install_command)).to eq(
          "rails generate react_on_rails:install #{expected_flag}"
        )
      end
    end

    specify "recovery_install_command normalizes the --webpack alias to --no-rspack" do
      install_generator = install_generator_fixture(webpack: true)

      command = install_generator.send(:recovery_install_command)

      expect(command).to eq("rails generate react_on_rails:install --no-rspack")
    end

    specify "shakapacker install error preserves original install flags" do
      install_generator = install_generator_fixture(redux: true, typescript: true, ignore_warnings: true)

      install_generator.send(:handle_shakapacker_install_error)
      output_text = GeneratorMessages.output.join("\n")

      expect(output_text).to include("clean up your working tree before rerunning")
      expect(output_text).to include("Re-run: rails generate react_on_rails:install --redux --typescript")
      expect(output_text).to include("Failed to install Shakapacker")
      expect(output_text).to include("legacy Redux generator path")
      expect(output_text.index("legacy Redux generator path"))
        .to be > output_text.index("Failed to install Shakapacker")
    end

    specify "hidden install --redux emits a legacy warning" do
      install_generator = install_generator_fixture(redux: true)

      install_generator.send(:add_legacy_redux_install_warning)
      output_text = GeneratorMessages.messages.join("\n")

      expect(output_text).to include("legacy Redux generator path")
      expect(output_text).to include("rails generate react_on_rails:react_with_redux")
    end

    specify "hidden install --redux --typescript legacy warning preserves the TypeScript flag" do
      install_generator = install_generator_fixture(redux: true, typescript: true)

      install_generator.send(:add_legacy_redux_install_warning)
      output_text = GeneratorMessages.messages.join("\n")

      expect(output_text).to include("rails generate react_on_rails:react_with_redux --typescript")
    end

    specify "hidden install --redux legacy warning is only added once" do
      install_generator = install_generator_fixture(redux: true)

      install_generator.send(:add_legacy_redux_install_warning_once)
      install_generator.send(:add_legacy_redux_install_warning_once)
      output_text = GeneratorMessages.messages.join("\n")

      expect(output_text.scan("legacy Redux generator path").size).to eq(1)
    end

    specify "hidden install --redux legacy warning is retried if adding it fails" do
      install_generator = install_generator_fixture(redux: true)

      allow(install_generator).to receive(:add_legacy_redux_install_warning).and_raise(StandardError, "warning failed")
      expect do
        install_generator.send(:add_legacy_redux_install_warning_once)
      end.to raise_error(StandardError, "warning failed")

      allow(install_generator).to receive(:add_legacy_redux_install_warning).and_call_original
      install_generator.send(:add_legacy_redux_install_warning_once)

      expect(GeneratorMessages.messages.join("\n")).to include("legacy Redux generator path")
    end

    specify "hidden install --redux legacy warning is printed when invoked generators fail" do
      install_generator = install_generator_fixture(redux: true)

      allow(install_generator).to receive(:installation_prerequisites_met?).and_return(true)
      allow(install_generator).to receive(:invoke_generators).and_raise(Thor::Error, "generator failed")
      allow(install_generator).to receive(:print_generator_messages)

      expect { install_generator.run_generators }.to raise_error(Thor::Error, "generator failed")
      expect(GeneratorMessages.messages.join("\n")).to include("legacy Redux generator path")
    end

    specify "warning failures do not suppress queued generator messages" do
      install_generator = install_generator_fixture(redux: true)

      allow(install_generator).to receive(:installation_prerequisites_met?).and_return(true)
      allow(install_generator).to receive(:invoke_generators).and_raise(Thor::Error, "generator failed")
      allow(install_generator).to receive(:add_legacy_redux_install_warning)
        .and_raise(StandardError, "warning failed")
      allow(install_generator).to receive(:print_generator_messages)
      allow(install_generator).to receive(:warn)

      expect { install_generator.run_generators }.to raise_error(Thor::Error, "generator failed")
      expect(install_generator).to have_received(:print_generator_messages)
    end

    specify "warning failures do not mask shakapacker gemfile errors" do
      install_generator = install_generator_fixture(redux: true)

      allow(install_generator).to receive(:add_legacy_redux_install_warning)
        .and_raise(StandardError, "warning failed")
      allow(install_generator).to receive(:warn)

      expect do
        install_generator.send(:handle_shakapacker_gemfile_error)
      end.to raise_error(Thor::Error, /Failed to add Shakapacker/)
    end

    specify "warning failures do not mask shakapacker install errors" do
      install_generator = install_generator_fixture(redux: true)

      allow(install_generator).to receive(:add_legacy_redux_install_warning)
        .and_raise(StandardError, "warning failed")
      allow(install_generator).to receive(:warn)

      expect do
        install_generator.send(:handle_shakapacker_install_error)
      end.to raise_error(Thor::Error, /Failed to install Shakapacker/)
    end

    specify "hidden install --redux --tailwind warning preserves meaningful install flags" do
      install_generator = install_generator_fixture(redux: true, tailwind: true, typescript: true)

      install_generator.send(:add_legacy_redux_install_warning)
      output_text = GeneratorMessages.messages.join("\n")

      expect(output_text).to include("Redux with Tailwind")
      expect(output_text).to include("rails generate react_on_rails:install --redux --typescript --tailwind")
      expect(output_text).not_to include("react_on_rails:react_with_redux")
    end

    specify "shakapacker gemfile error preserves original install flags" do
      # ignore_warnings: true is required so handle_shakapacker_gemfile_error logs
      # the error instead of raising Thor::Error, which lets this example inspect output.
      install_generator = install_generator_fixture(rspack: true, pro: true, ignore_warnings: true)

      install_generator.send(:handle_shakapacker_gemfile_error)
      output_text = GeneratorMessages.output.join("\n")

      expect(output_text).to include("clean up your working tree before rerunning")
      expect(output_text).to include("Then re-run: rails generate react_on_rails:install --rspack --pro")
    end

    specify "shakapacker gemfile error warns for hidden redux recovery" do
      install_generator = install_generator_fixture(redux: true, ignore_warnings: true)

      install_generator.send(:handle_shakapacker_gemfile_error)
      output_text = GeneratorMessages.output.join("\n")

      expect(output_text).to include("Then re-run: rails generate react_on_rails:install --redux")
      expect(output_text).to include("Failed to add Shakapacker")
      expect(output_text).to include("legacy Redux generator path")
      expect(output_text.index("legacy Redux generator path")).to be > output_text.index("Failed to add Shakapacker")
    end

    specify "rsc installs include the Pro verification checklist message" do
      run_generator_test_with_args(%w[--rsc], package_json: true) do
        simulate_existing_file("bin/shakapacker", "")
        simulate_existing_file("bin/shakapacker-dev-server", "")
        simulate_existing_file("config/shakapacker.yml", "default: {}\n")
        simulate_existing_file("config/webpack/webpack.config.js", "// mock webpack config\n")
      end

      output_text = GeneratorMessages.output.join("\n")
      expect(output_text).to include("RSC Pro Verification")
      expect(output_text).to include("http://localhost:<port>/hello_server")
      expect(output_text).to include("Like button hydrates on click")
    end
  end

  describe "--pretend mode behavior" do
    let(:install_generator) { install_generator_fixture(pretend: true) }
    let(:typescript_install_generator) { install_generator_fixture(pretend: true, typescript: true) }

    it "skips automatic shakapacker installation commands" do
      allow(install_generator).to receive(:shakapacker_configured?).and_return(false)

      expect(install_generator).to receive(:say_status)
        .with(:pretend, "Skipping automatic Shakapacker installation in --pretend mode", :yellow)
      expect(install_generator).not_to receive(:print_shakapacker_setup_banner)
      expect(install_generator).not_to receive(:ensure_shakapacker_in_gemfile)
      expect(install_generator).not_to receive(:install_shakapacker)
      expect(install_generator).not_to receive(:finalize_shakapacker_setup)

      install_generator.send(:ensure_shakapacker_installed)
    end

    it "does not chmod copied bin scripts in pretend mode" do
      allow(install_generator).to receive(:directory)
      allow(install_generator).to receive(:use_rsc?).and_return(false)

      expect(install_generator).to receive(:say_status)
        .with(:gsub, "bin/dev", true)
        .twice
      expect(install_generator).to receive(:say_status)
        .with(:pretend, "Skipping chmod on bin scripts in --pretend mode", :yellow)
      expect(Dir).not_to receive(:chdir)
      expect(File).not_to receive(:chmod)

      install_generator.send(:add_bin_scripts)
    end

    it "does not install typescript dependencies in pretend mode" do
      expect(typescript_install_generator).to receive(:say_status)
        .with(:pretend, "Skipping TypeScript dependency installation in --pretend mode", :yellow)
      expect(typescript_install_generator).not_to receive(:add_typescript_dependencies)

      typescript_install_generator.send(:install_typescript_dependencies)
    end

    it "does not set up react dependencies in pretend mode" do
      expect(install_generator).to receive(:say_status)
        .with(:pretend, "Skipping React dependency setup in --pretend mode", :yellow)
      expect(install_generator).not_to receive(:setup_js_dependencies)

      install_generator.send(:setup_react_dependencies)
    end

    it "does not create css module type files in pretend mode" do
      expect(install_generator).to receive(:say_status)
        .with(:pretend, "Skipping CSS module type definitions in --pretend mode", :yellow)
      expect(FileUtils).not_to receive(:mkdir_p)
      expect(File).not_to receive(:write)

      install_generator.send(:create_css_module_types)
    end

    it "does not write tsconfig.json in pretend mode" do
      expect(install_generator).to receive(:say_status)
        .with(:pretend, "Skipping tsconfig.json creation in --pretend mode", :yellow)
      expect(File).not_to receive(:write)

      install_generator.send(:create_typescript_config)
    end

    it "forwards pretend mode to base and react_no_redux generators" do
      allow(install_generator).to receive(:ensure_shakapacker_installed)
      allow(install_generator).to receive(:setup_react_dependencies)
      allow(install_generator).to receive_messages(use_pro?: false, use_rsc?: false)

      expect(install_generator).to receive(:invoke)
        .with("react_on_rails:base", [], hash_including(pretend: true))
      expect(install_generator).to receive(:invoke)
        .with("react_on_rails:react_no_redux", [], hash_including(pretend: true))

      install_generator.send(:invoke_generators)
    end

    it "forwards pretend mode to redux, pro, and rsc generators" do
      redux_pro_rsc_install_generator = install_generator_fixture(pretend: true, redux: true, pro: true, rsc: true)

      allow(redux_pro_rsc_install_generator).to receive(:ensure_shakapacker_installed)
      allow(redux_pro_rsc_install_generator).to receive(:setup_react_dependencies)
      allow(redux_pro_rsc_install_generator).to receive_messages(use_pro?: true, use_rsc?: true)

      expect(redux_pro_rsc_install_generator).to receive(:invoke)
        .with("react_on_rails:base", [], hash_including(pretend: true))
      expect(redux_pro_rsc_install_generator).to receive(:invoke)
        .with("react_on_rails:react_with_redux", [], hash_including(pretend: true))
      expect(redux_pro_rsc_install_generator).to receive(:invoke)
        .with("react_on_rails:pro", [], hash_including(pretend: true))
      expect(redux_pro_rsc_install_generator).to receive(:invoke)
        .with("react_on_rails:rsc", [], hash_including(pretend: true))

      redux_pro_rsc_install_generator.send(:invoke_generators)
    end

    it "does not read the copied Redux Tailwind entry in pretend mode" do
      redux_generator = redux_generator_fixture(pretend: true, tailwind: true)
      client_entry = "app/javascript/src/HelloWorldApp/ror_components/HelloWorldApp.client.jsx"
      simulate_existing_file("config/shakapacker.yml", <<~YAML)
        default: &default
          source_path: app/javascript

        development:
          <<: *default
      YAML

      allow(redux_generator).to receive(:copy_file)
      allow(redux_generator).to receive(:gsub_file)
      allow(redux_generator).to receive(:prepend_to_file)
      allow(File).to receive(:read).and_call_original

      expect(File).not_to receive(:read).with(File.join(destination_root, client_entry))
      expect(redux_generator).not_to receive(:say_status)
        .with(:pretend, "Tailwind stylesheet would be linked from the React on Rails layout", :yellow)

      redux_generator.send(:copy_base_files)
    end

    it "rejects standalone Redux Tailwind setup instead of creating unstyled components" do
      redux_generator = redux_generator_fixture(tailwind: true)
      GeneratorMessages.clear

      expect { redux_generator.send(:validate_standalone_tailwind) }
        .to raise_error(Thor::Error, /react_with_redux generator does not support --tailwind/)

      error_text = GeneratorMessages.messages.join("\n")
      expect(error_text).to include("Tailwind setup requires the base React on Rails installer")
      expect(error_text).not_to include("standalone react_on_rails:react_with_redux generator does not support")
      expect(error_text).to include("rails generate react_on_rails:install --redux --tailwind")
      expect(error_text).to include("rails generate react_on_rails:install --tailwind")
    end

    it "allows Redux Tailwind setup when invoked by the install generator" do
      redux_generator = redux_generator_fixture(tailwind: true, invoked_by_install: true)
      GeneratorMessages.clear

      expect { redux_generator.send(:validate_standalone_tailwind) }.not_to raise_error
      expect(GeneratorMessages.messages.join("\n")).not_to include(
        "standalone react_on_rails:react_with_redux generator does not support --tailwind"
      )
    end

    it "warns that direct standalone Redux generation is legacy" do
      redux_generator = redux_generator_fixture

      redux_generator.send(:add_legacy_redux_generator_warning)

      message_text = GeneratorMessages.messages.join("\n")
      expect(message_text).to include("legacy Redux generator path")
      expect(message_text).to match(/not\s+recommended for new React on Rails apps/)
    end

    it "does not warn from the standalone Redux generator when invoked by install" do
      redux_generator = redux_generator_fixture(invoked_by_install: true)
      GeneratorMessages.clear

      redux_generator.send(:add_legacy_redux_generator_warning)

      expect(GeneratorMessages.messages.join("\n")).not_to include("legacy Redux generator path")
    end

    it "queues the standalone Redux warning before fallible scaffold work" do
      redux_generator = redux_generator_fixture
      allow(redux_generator).to receive(:create_redux_directories).and_raise(Thor::Error, "copy failed")
      allow(redux_generator).to receive(:print_generator_messages)

      expect { redux_generator.run_generator }.to raise_error(Thor::Error, "copy failed")

      message_text = GeneratorMessages.messages.join("\n")
      expect(message_text).to include("legacy Redux generator path")
      expect(redux_generator).to have_received(:print_generator_messages)
    end

    it "prints queued messages when standalone Redux Tailwind validation fails" do
      redux_generator = redux_generator_fixture(tailwind: true)
      allow(redux_generator).to receive(:print_generator_messages)

      expect { redux_generator.run_generator }
        .to raise_error(Thor::Error, /react_with_redux generator does not support --tailwind/)

      expect(redux_generator).to have_received(:print_generator_messages)
    end
  end

  describe "#create_css_module_types" do
    it "uses Thor file creation at the configured Shakapacker source path" do
      install_generator = install_generator_fixture(skip: true)
      allow(install_generator).to receive(:shakapacker_source_path).and_return("client/app")

      expect(install_generator).to receive(:create_file)
        .with("client/app/types/css-modules.d.ts", a_string_including('declare module "*.module.css"'))

      install_generator.send(:create_css_module_types)
    end
  end

  context "when detecting node availability" do
    let(:install_generator) { install_generator_fixture }

    specify "missing_node? returns false when node is on PATH" do
      allow(ReactOnRails::Utils).to receive(:command_available?).with("node").and_return(true)
      allow(install_generator).to receive(:`).with("node --version 2>/dev/null").and_return("v20.0.0")

      expect(install_generator.send(:missing_node?)).to be false
    end

    specify "missing_node? returns true when node is missing" do
      allow(ReactOnRails::Utils).to receive(:command_available?).with("node").and_return(false)

      expect(install_generator.send(:missing_node?)).to be true
    end
  end

  # Tests for ensure_shakapacker_installed detection path:
  # the config_changed detection and @shakapacker_just_installed assignment in
  # finalize_shakapacker_setup — the runtime path that fires during a real
  # `rails g react_on_rails:install` when Shakapacker wasn't pre-configured.
  describe "ensure_shakapacker_installed detection path" do
    let(:install_generator) { install_generator_fixture }

    before do
      allow(install_generator).to receive(:print_shakapacker_setup_banner)
      allow(install_generator).to receive(:ensure_shakapacker_in_gemfile)
      allow(install_generator).to receive_messages(shakapacker_configured?: false, install_shakapacker: true)
      allow(install_generator).to receive(:puts)
    end

    it "sets @shakapacker_just_installed=true when yml did not exist before install" do
      Dir.mktmpdir do |dir|
        yml_path = File.join(dir, "config/shakapacker.yml")

        allow(install_generator).to receive(:install_shakapacker) do
          # Simulate shakapacker creating the yml from scratch
          FileUtils.mkdir_p(File.dirname(yml_path))
          File.write(yml_path, "new: shakapacker defaults\n")
          true
        end

        Dir.chdir(dir) { install_generator.send(:ensure_shakapacker_installed) }
        expect(install_generator.instance_variable_get(:@shakapacker_just_installed)).to be true
      end
    end

    it "sets @shakapacker_just_installed=true when yml existed but was overwritten (user said y)" do
      Dir.mktmpdir do |dir|
        yml_path = File.join(dir, "config/shakapacker.yml")
        FileUtils.mkdir_p(File.dirname(yml_path))
        File.write(yml_path, "old: content\n")

        allow(install_generator).to receive(:install_shakapacker) do
          File.write(yml_path, "new: shakapacker defaults\n")
          true
        end

        Dir.chdir(dir) { install_generator.send(:ensure_shakapacker_installed) }
        expect(install_generator.instance_variable_get(:@shakapacker_just_installed)).to be true
      end
    end

    it "sets @shakapacker_just_installed=false when yml existed and was preserved (user said n)" do
      Dir.mktmpdir do |dir|
        yml_path = File.join(dir, "config/shakapacker.yml")
        FileUtils.mkdir_p(File.dirname(yml_path))
        File.write(yml_path, "custom: config\n")

        allow(install_generator).to receive(:install_shakapacker).and_return(true)
        Dir.chdir(dir) { install_generator.send(:ensure_shakapacker_installed) }
        expect(install_generator.instance_variable_get(:@shakapacker_just_installed)).to be false
      end
    end

    it "sets @shakapacker_just_installed=false when yml did not exist before or after install (nil→nil)" do
      Dir.mktmpdir do |dir|
        # install_shakapacker returns true but does not write the yml
        allow(install_generator).to receive(:install_shakapacker).and_return(true)
        Dir.chdir(dir) { install_generator.send(:ensure_shakapacker_installed) }
        expect(install_generator.instance_variable_get(:@shakapacker_just_installed)).to be false
      end
    end

    it "does not call finalize_shakapacker_setup when install_shakapacker fails" do
      Dir.mktmpdir do |dir|
        allow(install_generator).to receive(:install_shakapacker).and_return(false)

        Dir.chdir(dir) { install_generator.send(:ensure_shakapacker_installed) }
        expect(install_generator.instance_variable_get(:@shakapacker_just_installed)).to be_nil
        expect(install_generator.instance_variable_get(:@shakapacker_setup_incomplete)).to be true
      end
    end

    it "keeps setup incomplete when adding shakapacker to Gemfile fails, even if install succeeds" do
      Dir.mktmpdir do |dir|
        allow(install_generator).to receive_messages(ensure_shakapacker_in_gemfile: false, install_shakapacker: true)
        allow(install_generator).to receive(:finalize_shakapacker_setup)

        Dir.chdir(dir) { install_generator.send(:ensure_shakapacker_installed) }

        expect(install_generator.instance_variable_get(:@shakapacker_setup_incomplete)).to be true
        expect(install_generator).to have_received(:install_shakapacker)
        expect(install_generator).to have_received(:finalize_shakapacker_setup)
      end
    end
  end

  describe "#shakapacker_configured?" do
    let(:install_generator) { install_generator_fixture }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(install_generator).to receive(:shakapacker_binaries_exist?).and_return(true)
      allow(File).to receive(:exist?).with("config/shakapacker.yml").and_return(true)
    end

    it "returns true when rspack config exists in config/rspack" do
      allow(File).to receive(:exist?).with("config/webpack/webpack.config.js").and_return(false)
      allow(File).to receive(:exist?).with("config/webpack/webpack.config.ts").and_return(false)
      allow(File).to receive(:exist?).with("config/rspack/rspack.config.js").and_return(true)
      allow(File).to receive(:exist?).with("config/rspack/rspack.config.ts").and_return(false)

      expect(install_generator.send(:shakapacker_configured?)).to be true
    end

    it "returns true when webpack TypeScript config exists" do
      allow(File).to receive(:exist?).with("config/webpack/webpack.config.js").and_return(false)
      allow(File).to receive(:exist?).with("config/webpack/webpack.config.ts").and_return(true)

      expect(install_generator.send(:shakapacker_configured?)).to be true
    end

    it "returns true when rspack TypeScript config exists" do
      allow(File).to receive(:exist?).with("config/webpack/webpack.config.js").and_return(false)
      allow(File).to receive(:exist?).with("config/webpack/webpack.config.ts").and_return(false)
      allow(File).to receive(:exist?).with("config/rspack/rspack.config.js").and_return(false)
      allow(File).to receive(:exist?).with("config/rspack/rspack.config.ts").and_return(true)

      expect(install_generator.send(:shakapacker_configured?)).to be true
    end

    it "returns false when no supported bundler config file exists" do
      allow(File).to receive(:exist?).with("config/webpack/webpack.config.js").and_return(false)
      allow(File).to receive(:exist?).with("config/webpack/webpack.config.ts").and_return(false)
      allow(File).to receive(:exist?).with("config/rspack/rspack.config.js").and_return(false)
      allow(File).to receive(:exist?).with("config/rspack/rspack.config.ts").and_return(false)

      expect(install_generator.send(:shakapacker_configured?)).to be false
    end
  end

  describe "#standard_shakapacker_config?" do
    let(:destination) { File.expand_path("../dummy-for-generators", __dir__) }
    let(:generator) { BaseGenerator.new([], {}, { destination_root: destination }) }

    it "recognizes stock webpack config with comments (Shakapacker 9.x)" do
      # Exact content from shakapacker 9.4.0 lib/install/config/webpack/webpack.config.js
      content = <<~JS
        // See the shakacode/shakapacker README and docs directory for advice on customizing your webpackConfig.
        const { generateWebpackConfig } = require('shakapacker')

        const webpackConfig = generateWebpackConfig()

        module.exports = webpackConfig
      JS
      expect(generator.send(:standard_shakapacker_config?, content)).to be true
    end

    it "recognizes stock webpack config without comments" do
      content = <<~JS
        const { generateWebpackConfig } = require('shakapacker')
        const webpackConfig = generateWebpackConfig()
        module.exports = webpackConfig
      JS
      expect(generator.send(:standard_shakapacker_config?, content)).to be true
    end

    it "recognizes stock webpack config with extra comments when comment-insensitive matching is enabled" do
      content = <<~JS
        // team-specific note
        const { generateWebpackConfig } = require('shakapacker')
        const webpackConfig = generateWebpackConfig()
        module.exports = webpackConfig
      JS
      expect(generator.send(:standard_shakapacker_config?, content)).to be false
      expect(generator.send(:standard_shakapacker_config?, content, strip_comments: true)).to be true
    end

    it "recognizes stock rspack config with comments (Shakapacker 9.x)" do
      # Exact content from shakapacker 9.4.0 lib/install/config/rspack/rspack.config.js
      content = <<~JS
        // See the shakacode/shakapacker README and docs directory for advice on customizing your rspackConfig.
        const { generateRspackConfig } = require('shakapacker/rspack')

        const rspackConfig = generateRspackConfig()

        module.exports = rspackConfig
      JS
      expect(generator.send(:standard_shakapacker_config?, content)).to be true
    end

    it "recognizes stock rspack config without comments" do
      content = <<~JS
        const { generateRspackConfig } = require('shakapacker/rspack')
        const rspackConfig = generateRspackConfig()
        module.exports = rspackConfig
      JS
      expect(generator.send(:standard_shakapacker_config?, content)).to be true
    end

    it "rejects custom config with user modifications" do
      content = <<~JS
        const { generateRspackConfig } = require('shakapacker/rspack')
        const rspackConfig = generateRspackConfig()
        rspackConfig.module.rules.push({ test: /\\.svg$/, type: 'asset' })
        module.exports = rspackConfig
      JS
      expect(generator.send(:standard_shakapacker_config?, content)).to be false
    end

    it "rejects React on Rails environment-loader config" do
      content = <<~JS
        const { env } = require('shakapacker')
        const { existsSync } = require('fs')
        const { resolve } = require('path')
        const envSpecificConfig = () => {
          const path = resolve(__dirname, `${env.nodeEnv}.js`)
          if (existsSync(path)) { return require(path) }
          else { throw new Error(`Could not find file to load ${path}`) }
        }
        module.exports = envSpecificConfig()
      JS
      expect(generator.send(:standard_shakapacker_config?, content)).to be false
    end

    it "recognizes stock TypeScript webpack config with type import (Shakapacker 9.4+)" do
      content = <<~TS
        import { generateWebpackConfig } from 'shakapacker'
        import type { Configuration } from 'webpack'
        const webpackConfig: Configuration = generateWebpackConfig()
        export default webpackConfig
      TS
      expect(generator.send(:standard_shakapacker_config?, content)).to be true
    end

    it "recognizes stock TypeScript webpack config without type import" do
      content = <<~TS
        import { generateWebpackConfig } from 'shakapacker'
        const webpackConfig = generateWebpackConfig()
        export default webpackConfig
      TS
      expect(generator.send(:standard_shakapacker_config?, content)).to be true
    end

    it "recognizes stock TypeScript configs with double quotes" do
      content = <<~TS
        import { generateWebpackConfig } from "shakapacker"
        const webpackConfig = generateWebpackConfig()
        export default webpackConfig
      TS
      expect(generator.send(:standard_shakapacker_config?, content)).to be true
    end

    it "recognizes stock TypeScript rspack config with type import (Shakapacker 9.4+)" do
      content = <<~TS
        import { generateRspackConfig } from 'shakapacker/rspack'
        import type { RspackOptions } from '@rspack/core'
        const rspackConfig: RspackOptions = generateRspackConfig()
        export default rspackConfig
      TS
      expect(generator.send(:standard_shakapacker_config?, content)).to be true
    end

    it "recognizes stock TypeScript rspack config without type import" do
      content = <<~TS
        import { generateRspackConfig } from 'shakapacker/rspack'
        const rspackConfig = generateRspackConfig()
        export default rspackConfig
      TS
      expect(generator.send(:standard_shakapacker_config?, content)).to be true
    end

    it "rejects customized TypeScript config with user modifications" do
      content = <<~TS
        import { generateWebpackConfig } from 'shakapacker'
        import type { Configuration } from 'webpack'
        const webpackConfig: Configuration = generateWebpackConfig()
        webpackConfig.resolve!.extensions!.push('.graphql')
        export default webpackConfig
      TS
      expect(generator.send(:standard_shakapacker_config?, content)).to be false
    end
  end

  describe "#bundler_main_config_path" do
    let(:destination) { File.expand_path("../dummy-for-generators", __dir__) }

    context "when using webpack" do
      let(:generator) { BaseGenerator.new([], { rspack: false }, { destination_root: destination }) }

      it "returns .ts path when TypeScript config exists" do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with("config/webpack/webpack.config.ts").and_return(true)
        expect(generator.send(:bundler_main_config_path)).to eq("config/webpack/webpack.config.ts")
      end

      it "returns .js path when no TypeScript config exists" do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with("config/webpack/webpack.config.ts").and_return(false)
        expect(generator.send(:bundler_main_config_path)).to eq("config/webpack/webpack.config.js")
      end
    end

    context "when using rspack" do
      let(:generator) { BaseGenerator.new([], { rspack: true }, { destination_root: destination }) }

      it "returns .ts path when TypeScript config exists" do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with("config/rspack/rspack.config.ts").and_return(true)
        expect(generator.send(:bundler_main_config_path)).to eq("config/rspack/rspack.config.ts")
      end

      it "returns .js path when no TypeScript config exists" do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with("config/rspack/rspack.config.ts").and_return(false)
        expect(generator.send(:bundler_main_config_path)).to eq("config/rspack/rspack.config.js")
      end
    end
  end

  describe "#copy_webpack_main_config" do
    let(:destination) { File.expand_path("../dummy-for-generators", __dir__) }
    let(:generator) { BaseGenerator.new([], {}, { destination_root: destination }) }

    it "uses TypeScript template when target config path ends with .ts" do
      allow(generator).to receive(:bundler_main_config_path).and_return("config/webpack/webpack.config.ts")
      allow(File).to receive(:exist?).with("config/webpack/webpack.config.ts").and_return(false)
      allow(generator).to receive(:template)

      generator.send(:copy_webpack_main_config, "base/base", {})

      expect(generator).to have_received(:template).with(
        "base/base/config/webpack/webpack.config.ts.tt",
        "config/webpack/webpack.config.ts",
        {}
      )
    end

    it "uses rspack template when target config path is rspack config" do
      allow(generator).to receive(:bundler_main_config_path).and_return("config/rspack/rspack.config.ts")
      allow(File).to receive(:exist?).with("config/rspack/rspack.config.ts").and_return(false)
      allow(generator).to receive(:template)

      generator.send(:copy_webpack_main_config, "base/base", {})

      expect(generator).to have_received(:template).with(
        "base/base/config/webpack/rspack.config.ts.tt",
        "config/rspack/rspack.config.ts",
        {}
      )
    end

    it "replaces existing stock TypeScript webpack config in place" do
      ts_path = "config/webpack/webpack.config.ts"
      ts_template = "base/base/config/webpack/webpack.config.ts.tt"
      stock_ts_config = <<~TS
        import { generateWebpackConfig } from 'shakapacker'
        const webpackConfig = generateWebpackConfig()
        export default webpackConfig
      TS

      allow(generator).to receive(:bundler_main_config_path).and_return(ts_path)
      allow(generator).to receive(:bundler_main_config_template_path).with("base/base", ts_path).and_return(ts_template)
      allow(File).to receive(:exist?).with(ts_path).and_return(true)
      allow(File).to receive(:read).with(ts_path).and_return(stock_ts_config)
      allow(generator).to receive(:standard_shakapacker_config?).with(stock_ts_config,
                                                                      strip_comments: true).and_return(true)
      allow(generator).to receive(:remove_file)
      allow(generator).to receive(:template)

      generator.send(:copy_webpack_main_config, "base/base", {})

      expect(generator).to have_received(:remove_file).with(ts_path, verbose: false)
      expect(generator).to have_received(:template).with(ts_template, ts_path, {})
    end

    it "routes existing custom TypeScript webpack config through custom replacement flow" do
      ts_path = "config/webpack/webpack.config.ts"
      ts_template = "base/base/config/webpack/webpack.config.ts.tt"
      custom_ts_config = <<~TS
        import { generateWebpackConfig } from 'shakapacker'
        const webpackConfig = generateWebpackConfig()
        webpackConfig.resolve?.extensions?.push('.graphql')
        export default webpackConfig
      TS

      allow(generator).to receive(:bundler_main_config_path).and_return(ts_path)
      allow(generator).to receive(:bundler_main_config_template_path).with("base/base", ts_path).and_return(ts_template)
      allow(File).to receive(:exist?).with(ts_path).and_return(true)
      allow(File).to receive(:read).with(ts_path).and_return(custom_ts_config)
      allow(generator).to receive(:standard_shakapacker_config?).with(custom_ts_config,
                                                                      strip_comments: true).and_return(false)
      allow(generator).to receive(:react_on_rails_config?).with(custom_ts_config).and_return(false)
      allow(generator).to receive(:handle_custom_webpack_config)

      generator.send(:copy_webpack_main_config, "base/base", {})

      expect(generator).to have_received(:handle_custom_webpack_config).with("base/base", {}, ts_path)
    end
  end

  describe "TypeScript bundler main config templates" do
    let(:webpack_ts_template_path) do
      File.expand_path(
        "../../../lib/generators/react_on_rails/templates/base/base/config/webpack/webpack.config.ts.tt",
        __dir__
      )
    end
    let(:rspack_ts_template_path) do
      File.expand_path(
        "../../../lib/generators/react_on_rails/templates/base/base/config/webpack/rspack.config.ts.tt",
        __dir__
      )
    end

    it "keeps the webpack TypeScript template compatible with Shakapacker's require-based loader" do
      content = File.read(webpack_ts_template_path)

      expect(content).to include("resolve(__dirname, `${env.nodeEnv}.js`)")
      expect(content).to include("return require(path)")
      expect(content).not_to include("import.meta.url")
      expect(content).not_to include("createRequire")
    end

    it "keeps the rspack TypeScript template compatible with Shakapacker's require-based loader" do
      content = File.read(rspack_ts_template_path)

      expect(content).to include("resolve(__dirname, `${env.nodeEnv}.js`)")
      expect(content).to include("return require(path)")
      expect(content).not_to include("import.meta.url")
      expect(content).not_to include("createRequire")
    end
  end

  describe "#using_rspack?" do
    # Regression guard for the load-bearing Thor invariant: --rspack must declare NO static
    # default. If a `default:` is ever added, Thor always includes :rspack in the options hash,
    # so options.key?(:rspack) is always true and the fresh-install Rspack default silently
    # breaks (every unflagged CLI run would fall back to Webpack). Verified empirically against
    # Thor 1.5.0: a no-default boolean option is absent from the options hash unless its flag is
    # passed on the CLI, whereas a `default:`-bearing option (e.g. --typescript) is always present.
    it "declares --rspack without a static default so the fresh-install default applies" do
      expect(described_class.class_options[:rspack].default).to be_nil
    end

    context "when --rspack option is provided" do
      let(:install_generator) { install_generator_fixture(rspack: true) }

      it "returns true" do
        expect(install_generator.send(:using_rspack?)).to be true
      end
    end

    context "when --no-rspack is passed" do
      let(:install_generator) { install_generator_fixture(rspack: false) }

      # --rspack declares no default, so options.key?(:rspack) is true only when the flag
      # is explicitly passed. --no-rspack sets it to false, selecting Webpack.
      it "returns false" do
        expect(install_generator.send(:using_rspack?)).to be false
      end
    end

    context "when --webpack is passed (alias for --no-rspack)" do
      let(:install_generator) { install_generator_fixture(webpack: true) }

      it "returns false" do
        expect(install_generator.send(:using_rspack?)).to be false
      end
    end

    context "when --no-webpack is passed" do
      let(:install_generator) { install_generator_fixture(webpack: false) }

      it "returns true" do
        expect(install_generator.send(:using_rspack?)).to be true
      end
    end

    context "when --rspack and --webpack contradict each other" do
      let(:install_generator) { install_generator_fixture(rspack: true, webpack: true) }

      it "raises a Thor::Error" do
        expect { install_generator.send(:using_rspack?) }
          .to raise_error(Thor::Error, /Conflicting bundler flags/)
      end
    end

    context "when --no-rspack and --webpack agree (both Webpack)" do
      let(:install_generator) { install_generator_fixture(rspack: false, webpack: true) }

      it "returns false without raising" do
        expect(install_generator.send(:using_rspack?)).to be false
      end
    end

    context "when no bundler flag is passed (fresh install)" do
      let(:install_generator) { install_generator_fixture }

      # With no flag and no existing bundler choice, the default resolves to Rspack when
      # Shakapacker supports it (Rspack landed in 9.0).
      it "defaults to Rspack" do
        allow(install_generator).to receive_messages(project_declares_assets_bundler?: false,
                                                     shakapacker_version_9_or_higher?: true)

        expect(install_generator.send(:using_rspack?)).to be true
      end

      # Twin of base_generator_spec's fallback case: InstallGenerator has its own
      # rspack_bundler_default override (delegating to fresh_install_rspack_default) and is the
      # primary CLI entry point, so the < 9.0 fallback to Webpack is asserted here too.
      it "falls back to Webpack when Rspack is unsupported (Shakapacker < 9.0)" do
        allow(install_generator).to receive_messages(project_declares_assets_bundler?: false,
                                                     shakapacker_version_9_or_higher?: false)

        expect(install_generator.send(:using_rspack?)).to be false
      end
    end
  end

  describe "#destination_config_path" do
    context "with --rspack" do
      let(:install_generator) { install_generator_fixture(rspack: true) }

      it "remaps config/webpack/ to config/rspack/" do
        expect(install_generator.send(:destination_config_path, "config/webpack/serverWebpackConfig.js"))
          .to eq("config/rspack/serverWebpackConfig.js")
      end

      it "leaves paths without config/webpack/ unchanged" do
        expect(install_generator.send(:destination_config_path, "app/javascript/packs/server-bundle.js"))
          .to eq("app/javascript/packs/server-bundle.js")
      end
    end

    context "with --no-rspack" do
      let(:install_generator) { install_generator_fixture(rspack: false) }

      it "returns path unchanged" do
        expect(install_generator.send(:destination_config_path, "config/webpack/serverWebpackConfig.js"))
          .to eq("config/webpack/serverWebpackConfig.js")
      end
    end
  end

  # Regression test for https://github.com/shakacode/react_on_rails/issues/2287
  # Bundler subprocess commands must run in unbundled environment to prevent
  # BUNDLE_GEMFILE inheritance from parent process
  describe "bundler environment isolation" do
    # Pin to Webpack (--no-rspack) so this shared fixture covers the explicit Webpack install path.
    let(:install_generator) { install_generator_fixture(rspack: false) }
    let(:webpack_install_env) { { "SHAKAPACKER_ASSETS_BUNDLER" => "webpack" } }
    let(:rspack_install_env) { { "SHAKAPACKER_ASSETS_BUNDLER" => "rspack" } }

    it "clears BUNDLE_GEMFILE when running bundle add" do
      allow(install_generator).to receive(:shakapacker_in_gemfile?).and_return(false)
      allow(install_generator).to receive(:system).with("bundle add shakapacker --strict").and_return(true)

      expect(Bundler).to receive(:with_unbundled_env).and_yield

      install_generator.send(:ensure_shakapacker_in_gemfile)
    end

    it "clears BUNDLE_GEMFILE when running bundle install and shakapacker:install" do
      # Verify both system calls run inside with_unbundled_env
      allow(Bundler).to receive(:with_unbundled_env).and_yield
      allow(install_generator).to receive(:system).with("bundle install").and_return(true)
      allow(install_generator).to receive(:system)
        .with(webpack_install_env, "bundle exec rails shakapacker:install")
        .and_return(true)

      install_generator.send(:install_shakapacker)

      expect(install_generator).to have_received(:system).with("bundle install")
      expect(install_generator).to have_received(:system)
        .with(webpack_install_env, "bundle exec rails shakapacker:install")
      expect(Bundler).to have_received(:with_unbundled_env).at_least(:twice)
    end

    it "passes SHAKAPACKER_ASSETS_BUNDLER=webpack to shakapacker:install when --webpack is set" do
      webpack_generator = install_generator_fixture(webpack: true)
      allow(Bundler).to receive(:with_unbundled_env).and_yield
      allow(webpack_generator).to receive(:system).with("bundle install").and_return(true)
      allow(webpack_generator).to receive(:system)
        .with(webpack_install_env, "bundle exec rails shakapacker:install")
        .and_return(true)

      webpack_generator.send(:install_shakapacker)

      expect(webpack_generator).to have_received(:system)
        .with(webpack_install_env, "bundle exec rails shakapacker:install")
    end

    it "passes the resolved SHAKAPACKER_ASSETS_BUNDLER to shakapacker:install when no bundler flag is set" do
      default_generator = install_generator_fixture
      allow(default_generator).to receive_messages(project_declares_assets_bundler?: false,
                                                   shakapacker_version_9_or_higher?: true)
      allow(Bundler).to receive(:with_unbundled_env).and_yield
      allow(default_generator).to receive(:system).with("bundle install").and_return(true)
      allow(default_generator).to receive(:system)
        .with(rspack_install_env, "bundle exec rails shakapacker:install")
        .and_return(true)

      default_generator.send(:install_shakapacker)

      expect(default_generator).to have_received(:system)
        .with(rspack_install_env, "bundle exec rails shakapacker:install")
    end

    it "passes SHAKAPACKER_ASSETS_BUNDLER=rspack to shakapacker:install when --rspack is set" do
      rspack_generator = install_generator_fixture(rspack: true)
      allow(Bundler).to receive(:with_unbundled_env).and_yield
      allow(rspack_generator).to receive(:system).with("bundle install").and_return(true)
      allow(rspack_generator).to receive(:system)
        .with(rspack_install_env, "bundle exec rails shakapacker:install")
        .and_return(true)

      rspack_generator.send(:install_shakapacker)

      expect(rspack_generator).to have_received(:system)
        .with(rspack_install_env, "bundle exec rails shakapacker:install")
    end

    context "with fake BUNDLE_GEMFILE set" do
      around do |example|
        original_gemfile = ENV.fetch("BUNDLE_GEMFILE", nil)
        example.run
      ensure
        if original_gemfile
          ENV["BUNDLE_GEMFILE"] = original_gemfile
        else
          ENV.delete("BUNDLE_GEMFILE")
        end
      end

      it "Bundler.with_unbundled_env clears BUNDLE_GEMFILE in block" do
        ENV["BUNDLE_GEMFILE"] = "/fake/parent/Gemfile"

        bundler_env_in_block = nil
        Bundler.with_unbundled_env do
          bundler_env_in_block = ENV.fetch("BUNDLE_GEMFILE", nil)
        end

        expect(bundler_env_in_block).to be_nil
      end

      it "checks local Gemfile regardless of BUNDLE_GEMFILE env var" do
        ENV["BUNDLE_GEMFILE"] = "/some/other/project/Gemfile"

        # The method should check "Gemfile" not ENV["BUNDLE_GEMFILE"]
        # We verify this by checking it does NOT try to access the env var path
        allow(File).to receive(:file?).with("Gemfile").and_return(false)
        allow(File).to receive(:file?).with("/some/other/project/Gemfile").and_return(true)

        result = install_generator.send(:shakapacker_in_gemfile_text?, "shakapacker")

        # If it checked ENV["BUNDLE_GEMFILE"], it would find the file and continue
        # Since we return false for "Gemfile", the result should be false
        expect(result).to be false
      end

      it "checks local Gemfile.lock regardless of BUNDLE_GEMFILE env var" do
        ENV["BUNDLE_GEMFILE"] = "/some/other/project/Gemfile"

        # The method should check "Gemfile.lock" not derived from ENV["BUNDLE_GEMFILE"]
        allow(File).to receive(:file?).with("Gemfile.lock").and_return(false)
        allow(File).to receive(:file?).with("/some/other/project/Gemfile.lock").and_return(true)

        result = install_generator.send(:shakapacker_in_lockfile?, "shakapacker")

        # If it derived path from ENV["BUNDLE_GEMFILE"], it would find the file
        # Since we return false for "Gemfile.lock", the result should be false
        expect(result).to be false
      end
    end
  end

  # Pro/RSC prerequisite validation tests

  context "when using --pro flag without Pro gem installed" do
    let(:install_generator) { install_generator_fixture(pro: true) }
    # Pin to a stable version so this test exercises the pessimistic (~>) branch
    # of pro_gem_version_requirement regardless of whether the live VERSION is a
    # prerelease (the prerelease branch is covered by a separate context below).
    let(:expected_pro_version) { "16.5.0" }
    let(:fake_pid) { 12_345 }

    before do
      stub_const("ReactOnRails::VERSION", expected_pro_version)
      allow(Gem).to receive(:loaded_specs).and_return({})
      allow(install_generator).to receive(:gem_in_lockfile?).with("react_on_rails_pro").and_return(false)
      allow(Bundler).to receive(:with_unbundled_env).and_yield
      allow(Process).to receive(:spawn).and_return(fake_pid)
      allow(install_generator).to receive(:wait_for_bundle_process)
        .with(fake_pid).and_return(instance_double(Process::Status, success?: false))
    end

    specify "missing_pro_gem? returns true and error mentions --pro flag" do
      expect(install_generator.send(:missing_pro_gem?)).to be true
      expect(Bundler).to have_received(:with_unbundled_env)
      expect(Process).to have_received(:spawn)
      error_text = GeneratorMessages.messages.join("\n")
      expect(error_text).to include("--pro")
      expect(error_text).to include("react_on_rails_pro")
      expect(error_text).to include("~> #{expected_pro_version}")
      expect(error_text).to include("https://reactonrails.com/docs/pro/upgrading-to-pro/")
    end
  end

  context "when using --rsc flag without Pro gem installed" do
    let(:install_generator) { install_generator_fixture(rsc: true) }
    let(:fake_pid) { 12_345 }

    before do
      allow(Gem).to receive(:loaded_specs).and_return({})
      allow(install_generator).to receive(:gem_in_lockfile?).with("react_on_rails_pro").and_return(false)
      allow(Bundler).to receive(:with_unbundled_env).and_yield
      allow(Process).to receive(:spawn).and_return(fake_pid)
      allow(install_generator).to receive(:wait_for_bundle_process)
        .with(fake_pid).and_return(instance_double(Process::Status, success?: false))
    end

    specify "missing_pro_gem? returns true and error mentions --rsc flag" do
      expect(install_generator.send(:missing_pro_gem?)).to be true
      expect(Bundler).to have_received(:with_unbundled_env)
      expect(Process).to have_received(:spawn)
      error_text = GeneratorMessages.messages.join("\n")
      expect(error_text).to include("--rsc")
    end
  end

  context "when using --rsc flag with a prerelease ReactOnRails version" do
    let(:install_generator) { install_generator_fixture(rsc: true) }
    let(:fake_pid) { 12_345 }

    before do
      stub_const("ReactOnRails::VERSION", "16.4.0.rc.5")
      allow(Gem).to receive(:loaded_specs).and_return({})
      allow(install_generator).to receive(:gem_in_lockfile?).with("react_on_rails_pro").and_return(false)
      allow(Bundler).to receive(:with_unbundled_env).and_yield
      allow(Process).to receive(:spawn).and_return(fake_pid)
      allow(install_generator).to receive(:wait_for_bundle_process)
        .with(fake_pid).and_return(instance_double(Process::Status, success?: false))
    end

    specify "missing_pro_gem? uses exact version pin and surfaces a prerelease note" do
      expect(install_generator.send(:missing_pro_gem?)).to be true
      expect(Process).to have_received(:spawn)
        .with("bundle add react_on_rails_pro --version='16.4.0.rc.5' --strict",
              out: anything,
              err: anything)
      error_text = GeneratorMessages.messages.join("\n")
      expect(error_text).to include("--rsc")
      expect(error_text).to include("gem 'react_on_rails_pro', '16.4.0.rc.5'")
      expect(error_text).to include("may not be published yet")
      expect(error_text).to include("path:")
    end
  end

  context "when auto-installing Pro gem succeeds" do
    let(:install_generator) { install_generator_fixture(pro: true) }
    let(:fake_pid) { 12_345 }

    before do
      allow(Gem).to receive(:loaded_specs).and_return({})
      allow(install_generator).to receive(:gem_in_lockfile?).with("react_on_rails_pro").and_return(false)
      allow(Bundler).to receive(:with_unbundled_env).and_yield
      allow(Process).to receive(:spawn).and_return(fake_pid)
      allow(install_generator).to receive(:wait_for_bundle_process)
        .with(fake_pid).and_return(instance_double(Process::Status, success?: true))

      # Simulate stale memoized value from an earlier check.
      install_generator.instance_variable_set(:@pro_gem_installed, false)
    end

    specify "missing_pro_gem? invalidates memoized pro_gem_installed? cache so it re-reads the lockfile" do
      expect(install_generator.send(:missing_pro_gem?)).to be false
      expect(Bundler).to have_received(:with_unbundled_env)
      expect(Process).to have_received(:spawn)
      # bundle add updated the lockfile, so the stale `false` cache must be cleared.
      expect(install_generator.instance_variable_defined?(:@pro_gem_installed)).to be false
      # Auto-install is a real install, not a deferred one; the deferred flag must stay false.
      expect(install_generator.send(:pro_gem_install_deferred?)).to be false
      # Re-stub gem_in_lockfile? to simulate what bundle add wrote, then verify the re-read.
      allow(install_generator).to receive(:gem_in_lockfile?).with("react_on_rails_pro").and_return(true)
      expect(install_generator.send(:pro_gem_installed?)).to be true
    end
  end

  context "when auto-install times out" do
    let(:install_generator) { install_generator_fixture(pro: true) }
    let(:fake_pid) { 12_345 }

    before do
      allow(Gem).to receive(:loaded_specs).and_return({})
      allow(install_generator).to receive(:gem_in_lockfile?).with("react_on_rails_pro").and_return(false)
      allow(Bundler).to receive(:with_unbundled_env).and_yield
      allow(Process).to receive(:spawn).and_return(fake_pid)
      allow(install_generator).to receive(:wait_for_bundle_process)
        .with(fake_pid).and_return(nil)
    end

    specify "missing_pro_gem? returns true with timeout message" do
      expect(install_generator.send(:missing_pro_gem?)).to be true
    end
  end

  context "when auto-install raises an error" do
    let(:install_generator) { install_generator_fixture(pro: true) }

    before do
      allow(Gem).to receive(:loaded_specs).and_return({})
      allow(install_generator).to receive(:gem_in_lockfile?).with("react_on_rails_pro").and_return(false)
      allow(Bundler).to receive(:with_unbundled_env).and_raise(Errno::ENOENT, "bundle not found")
    end

    specify "missing_pro_gem? returns true and handles error gracefully" do
      expect(install_generator.send(:missing_pro_gem?)).to be true
    end
  end

  context "when using --pro flag with Pro gem in Gem.loaded_specs" do
    let(:install_generator) { install_generator_fixture(pro: true) }

    specify "missing_pro_gem? returns false" do
      allow(Gem).to receive(:loaded_specs).and_return({ "react_on_rails_pro" => double })

      expect(install_generator.send(:missing_pro_gem?)).to be false
    end
  end

  context "when using --pro flag with Pro gem in Gemfile.lock" do
    let(:install_generator) { install_generator_fixture(pro: true) }

    specify "missing_pro_gem? returns false" do
      allow(Gem).to receive(:loaded_specs).and_return({})
      allow(install_generator).to receive(:gem_in_lockfile?).with("react_on_rails_pro").and_return(true)

      expect(install_generator.send(:missing_pro_gem?)).to be false
    end
  end

  context "when not using --pro or --rsc flags" do
    let(:install_generator) { install_generator_fixture }

    specify "missing_pro_gem? returns false without checking gem" do
      expect(install_generator.send(:missing_pro_gem?)).to be false
    end
  end

  context "when the selected JavaScript package manager is unavailable" do
    let(:install_generator) { install_generator_fixture }

    before do
      allow(GeneratorMessages).to receive(:detect_package_manager_with_source).and_return(["pnpm", :package_json])
      allow(GeneratorMessages).to receive(:package_manager_executable_available?) { |command| command == "npm" }
    end

    specify "missing_package_manager? reports the selected manager and available alternatives" do
      expect(install_generator.send(:missing_package_manager?)).to be true

      error_text = GeneratorMessages.messages.join("\n")
      expect(error_text).to include("package manager 'pnpm' was selected")
      expect(error_text).to include("`packageManager` field in package.json")
      expect(error_text).to include("available package managers: npm")
    end

    specify "missing_package_manager? uses the shared executable check for alternatives" do
      install_generator.send(:missing_package_manager?)

      expect(GeneratorMessages).to have_received(:package_manager_executable_available?).with("pnpm").once
      expect(GeneratorMessages).to have_received(:package_manager_executable_available?).with("npm")
    end
  end

  context "when the detection source picks the missing package manager" do
    let(:install_generator) { install_generator_fixture }

    before do
      allow(GeneratorMessages).to receive(:package_manager_executable_available?) { |command| command == "npm" }
    end

    {
      env: "REACT_ON_RAILS_PACKAGE_MANAGER environment variable",
      package_json: "`packageManager` field in package.json",
      default: "npm default fallback"
    }.each do |source, phrase|
      specify "missing_package_manager? names the #{source} source in the error" do
        allow(GeneratorMessages).to receive(:detect_package_manager_with_source).and_return(["pnpm", source])

        install_generator.send(:missing_package_manager?)

        expect(GeneratorMessages.messages.join("\n")).to include(phrase)
      end
    end

    specify "missing_package_manager? names the actual lockfile filename when a lockfile picks the manager" do
      allow(GeneratorMessages).to receive(:detect_package_manager_with_source).and_return(["pnpm", :lockfile])
      allow(GeneratorMessages).to receive(:lockfile_filename_for).with("pnpm",
                                                                       app_root: anything).and_return("pnpm-lock.yaml")

      install_generator.send(:missing_package_manager?)

      expect(GeneratorMessages.messages.join("\n")).to include("pnpm-lock.yaml lockfile on disk")
    end

    specify "missing_package_manager? omits 'update the source above' when source is :default" do
      allow(GeneratorMessages).to receive(:detect_package_manager_with_source).and_return(["npm", :default])
      allow(GeneratorMessages).to receive(:package_manager_executable_available?) { |command| command == "yarn" }

      install_generator.send(:missing_package_manager?)

      error_text = GeneratorMessages.messages.join("\n")
      expect(error_text).not_to include("update the source above")
      expect(error_text).to include("Install 'npm' or set REACT_ON_RAILS_PACKAGE_MANAGER")
    end

    specify "missing_package_manager? omits 'update the source above' when source is :env" do
      allow(GeneratorMessages).to receive(:detect_package_manager_with_source).and_return(["pnpm", :env])
      allow(GeneratorMessages).to receive(:package_manager_executable_available?) { |command| command == "npm" }

      install_generator.send(:missing_package_manager?)

      error_text = GeneratorMessages.messages.join("\n")
      expect(error_text).not_to include("update the source above")
      expect(error_text).to include("Install 'pnpm' or set REACT_ON_RAILS_PACKAGE_MANAGER")
    end
  end

  context "when no JavaScript package manager is available at all" do
    let(:install_generator) { install_generator_fixture }

    before do
      allow(GeneratorMessages).to receive_messages(
        detect_package_manager_with_source: ["npm", :default],
        package_manager_executable_available?: false
      )
    end

    specify "missing_package_manager? reports that no package manager is installed" do
      expect(install_generator.send(:missing_package_manager?)).to be true

      error_text = GeneratorMessages.messages.join("\n")
      expect(error_text).to include("No JavaScript package manager found")
      expect(error_text).to include("Selected via the npm default fallback")
      expect(error_text).to include("Please install one of the following")
    end
  end

  context "when no JavaScript package manager is available but the user had configured one" do
    let(:install_generator) { install_generator_fixture }

    before do
      allow(GeneratorMessages).to receive_messages(
        detect_package_manager_with_source: ["pnpm", :package_json],
        package_manager_executable_available?: false
      )
    end

    specify "missing_package_manager? names the configured source so the user knows their config is involved" do
      expect(install_generator.send(:missing_package_manager?)).to be true

      error_text = GeneratorMessages.messages.join("\n")
      expect(error_text).to include("No JavaScript package manager found")
      expect(error_text).to include("`packageManager` field in package.json")
    end
  end

  describe "#warn_if_unsupported_env_package_manager" do
    include_context "with clean REACT_ON_RAILS_PACKAGE_MANAGER env"

    let(:install_generator) { install_generator_fixture }

    specify "warns when REACT_ON_RAILS_PACKAGE_MANAGER is set to an unsupported value" do
      ENV["REACT_ON_RAILS_PACKAGE_MANAGER"] = "rush"

      install_generator.send(:warn_if_unsupported_env_package_manager)

      warning_text = GeneratorMessages.messages.join("\n")
      expect(warning_text).to include("REACT_ON_RAILS_PACKAGE_MANAGER='rush' is not a supported package manager")
      expect(warning_text).to include("Supported values: npm, pnpm, yarn, bun")
    end

    specify "does not warn when REACT_ON_RAILS_PACKAGE_MANAGER is supported" do
      ENV["REACT_ON_RAILS_PACKAGE_MANAGER"] = "pnpm"

      install_generator.send(:warn_if_unsupported_env_package_manager)

      expect(GeneratorMessages.messages).to eq([])
    end

    specify "does not warn when REACT_ON_RAILS_PACKAGE_MANAGER is unset" do
      ENV.delete("REACT_ON_RAILS_PACKAGE_MANAGER")

      install_generator.send(:warn_if_unsupported_env_package_manager)

      expect(GeneratorMessages.messages).to eq([])
    end

    specify "does not warn when REACT_ON_RAILS_PACKAGE_MANAGER is empty or whitespace" do
      ENV["REACT_ON_RAILS_PACKAGE_MANAGER"] = "   "

      install_generator.send(:warn_if_unsupported_env_package_manager)

      expect(GeneratorMessages.messages).to eq([])
    end
  end

  context "when force-checking Pro gem without pro-related flags" do
    let(:install_generator) { install_generator_fixture(pro: false, rsc: false) }
    let(:fake_pid) { 12_345 }

    before do
      allow(Gem).to receive(:loaded_specs).and_return({})
      allow(install_generator).to receive(:gem_in_lockfile?).with("react_on_rails_pro").and_return(false)
      allow(Bundler).to receive(:with_unbundled_env).and_yield
      allow(Process).to receive(:spawn).and_return(fake_pid)
      allow(install_generator).to receive(:wait_for_bundle_process)
        .with(fake_pid).and_return(instance_double(Process::Status, success?: false))
    end

    specify "missing_pro_gem?(force: true) uses generic context messaging" do
      expect(install_generator.send(:missing_pro_gem?, force: true)).to be true

      error_text = GeneratorMessages.messages.join("\n")
      expect(error_text).to include("This generator requires the react_on_rails_pro gem.")
      expect(error_text).not_to include("You specified")
    end
  end

  context "when --tailwind is used with an unsupported Shakapacker version" do
    let(:install_generator) { install_generator_fixture(tailwind: true) }

    before do
      allow(ReactOnRails::GitUtils).to receive(:warn_if_uncommitted_changes).and_return(false)
      allow(install_generator).to receive(:cli_exists?).with("git").and_return(true)
      allow(install_generator).to receive_messages(missing_node?: false, missing_package_manager?: false)
      allow(ReactOnRails::PackerUtils).to receive(:shakapacker_version_requirement_met?)
        .with("6.5.6")
        .and_return(false)
      allow(ReactOnRails::PackerUtils).to receive(:shakapacker_version).and_return("6.5.5")
    end

    specify "installation_prerequisites_met? reports the Tailwind-only version gate" do
      expect(install_generator.send(:installation_prerequisites_met?)).to be false

      error_text = GeneratorMessages.messages.join("\n")
      expect(error_text).to include("Tailwind layout wiring requires Shakapacker >= 6.5.6")
      expect(error_text).to include("Installed version: 6.5.5")
      expect(error_text).to include("Upgrade shakapacker or omit --tailwind")
    end
  end

  context "when --pro flag used on a dirty worktree without pro gem" do
    let(:install_generator) { install_generator_fixture(pro: true) }

    before do
      allow(ReactOnRails::GitUtils).to receive(:warn_if_uncommitted_changes).and_return(true)
      allow(install_generator).to receive(:cli_exists?).with("git").and_return(true)
      allow(install_generator).to receive_messages(missing_node?: false, missing_package_manager?: false)
      allow(Gem).to receive(:loaded_specs).and_return({})
      allow(install_generator).to receive(:gem_in_lockfile?).with("react_on_rails_pro").and_return(false)
    end

    specify "installation_prerequisites_met? returns false with clear error" do
      expect(install_generator.send(:installation_prerequisites_met?)).to be false
      error_text = GeneratorMessages.messages.join("\n")
      expect(error_text).to include("react_on_rails_pro")
      expect(error_text).to include("uncommitted changes")
      expect(error_text).to include("--pro")
    end
  end

  context "when --rsc flag used on a dirty worktree without pro gem" do
    let(:install_generator) { install_generator_fixture(rsc: true) }

    before do
      allow(ReactOnRails::GitUtils).to receive(:warn_if_uncommitted_changes).and_return(true)
      allow(install_generator).to receive(:cli_exists?).with("git").and_return(true)
      allow(install_generator).to receive_messages(missing_node?: false, missing_package_manager?: false)
      allow(Gem).to receive(:loaded_specs).and_return({})
      allow(install_generator).to receive(:gem_in_lockfile?).with("react_on_rails_pro").and_return(false)
    end

    specify "installation_prerequisites_met? returns false with clear error" do
      expect(install_generator.send(:installation_prerequisites_met?)).to be false
      error_text = GeneratorMessages.messages.join("\n")
      expect(error_text).to include("react_on_rails_pro")
      expect(error_text).to include("uncommitted changes")
      expect(error_text).to include("--rsc")
    end
  end

  context "when --pro flag used on a dirty worktree with pro gem installed" do
    let(:install_generator) { install_generator_fixture(pro: true) }

    before do
      allow(ReactOnRails::GitUtils).to receive(:warn_if_uncommitted_changes).and_return(true)
      allow(install_generator).to receive(:cli_exists?).with("git").and_return(true)
      allow(install_generator).to receive_messages(missing_node?: false, missing_package_manager?: false)
      allow(Gem).to receive(:loaded_specs).and_return({ "react_on_rails_pro" => double })
    end

    specify "installation_prerequisites_met? returns true (no error)" do
      expect(install_generator.send(:installation_prerequisites_met?)).to be true
      expect(GeneratorMessages.messages.join("\n")).not_to include("react_on_rails_pro")
    end
  end

  # React version detection tests

  context "when package.json has standard React version" do
    let(:install_generator) { install_generator_fixture }

    specify "detect_react_version extracts version" do
      allow(install_generator).to receive(:package_json).and_return({ "dependencies" => { "react" => "19.0.3" } })

      expect(install_generator.send(:detect_react_version)).to eq("19.0.3")
    end
  end

  context "when package.json has React version with caret prefix" do
    let(:install_generator) { install_generator_fixture }

    specify "detect_react_version extracts version without prefix" do
      allow(install_generator).to receive(:package_json).and_return({ "dependencies" => { "react" => "^19.0.3" } })

      expect(install_generator.send(:detect_react_version)).to eq("19.0.3")
    end
  end

  context "when package.json has React as workspace protocol" do
    let(:install_generator) { install_generator_fixture }

    specify "detect_react_version returns nil" do
      allow(install_generator).to receive(:package_json).and_return({ "dependencies" => { "react" => "workspace:*" } })

      expect(install_generator.send(:detect_react_version)).to be_nil
    end
  end

  context "when package.json is not available" do
    let(:install_generator) { install_generator_fixture }

    specify "detect_react_version returns nil" do
      allow(install_generator).to receive(:package_json).and_return(nil)

      expect(install_generator.send(:detect_react_version)).to be_nil
    end
  end

  # RSC React version warning tests

  describe "RSC React warning constants" do
    specify "derive from the RSC dependency manager React range" do
      dependency_manager = ReactOnRails::Generators::JsDependencyManager
      rsc_setup = ReactOnRails::Generators::RscSetup
      minimum_react_version = dependency_manager::RSC_REACT_VERSION_RANGE.sub(/\A[~^]/, "")

      expect(rsc_setup::RSC_REACT_VERSION_RANGE).to eq(dependency_manager::RSC_REACT_VERSION_RANGE)
      expect(rsc_setup::RSC_MINIMUM_REACT_VERSION).to eq(minimum_react_version)
    end
  end

  context "when using --rsc with React 19.2.7" do
    let(:install_generator) { install_generator_fixture(rsc: true) }

    specify "warn_about_react_version_for_rsc does not add warning" do
      allow(install_generator).to receive(:detect_react_version).and_return("19.2.7")

      install_generator.send(:warn_about_react_version_for_rsc)
      expect(GeneratorMessages.messages.join("\n")).not_to include("⚠️")
    end
  end

  context "when using --rsc with React 19.1.0" do
    let(:install_generator) { install_generator_fixture(rsc: true) }

    specify "warn_about_react_version_for_rsc adds version incompatibility warning" do
      allow(install_generator).to receive(:detect_react_version).and_return("19.1.0")

      install_generator.send(:warn_about_react_version_for_rsc)
      warning_text = GeneratorMessages.messages.join("\n")
      expect(warning_text).to include("RSC requires React 19.2.x")
      expect(warning_text).to include("detected: 19.1.0")
    end
  end

  context "when using --rsc with React 18.2.0" do
    let(:install_generator) { install_generator_fixture(rsc: true) }

    specify "warn_about_react_version_for_rsc adds version incompatibility warning" do
      allow(install_generator).to receive(:detect_react_version).and_return("18.2.0")

      install_generator.send(:warn_about_react_version_for_rsc)
      warning_text = GeneratorMessages.messages.join("\n")
      expect(warning_text).to include("RSC requires React 19.2.x")
    end
  end

  context "when using --rsc with React 19.2.0" do
    let(:install_generator) { install_generator_fixture(rsc: true) }

    specify "warn_about_react_version_for_rsc adds minimum version warning" do
      allow(install_generator).to receive(:detect_react_version).and_return("19.2.0")

      install_generator.send(:warn_about_react_version_for_rsc)
      warning_text = GeneratorMessages.messages.join("\n")
      expect(warning_text).to include("below the recommended minimum")
      expect(warning_text).to include("React 19.2.7")
    end
  end

  context "when not using --rsc flag" do
    let(:install_generator) { install_generator_fixture }

    specify "warn_about_react_version_for_rsc does not run" do
      allow(install_generator).to receive(:detect_react_version).and_return("18.2.0")

      install_generator.send(:warn_about_react_version_for_rsc)
      expect(GeneratorMessages.messages.join("\n")).not_to include("RSC")
    end
  end

  describe "#seed_package_manager_in_package_json_from_lockfile!" do
    let(:install_generator) { described_class.new([], {}, destination_root:) }
    let(:success_status) { instance_double(Process::Status, success?: true) }

    before do
      prepare_destination
      simulate_existing_file("package.json", <<~JSON)
        {
          "name": "dummy-app",
          "private": true,
          "dependencies": {}
        }
      JSON
      simulate_existing_file("yarn.lock", "")
    end

    it "adds packageManager when a lockfile exists and packageManager is missing" do
      allow(install_generator).to receive(:cli_exists?).with("yarn").and_return(true)
      allow(Open3).to receive(:capture3).with("yarn", "--version").and_return(["1.22.22\n", "", success_status])

      Dir.chdir(destination_root) do
        install_generator.send(:seed_package_manager_in_package_json_from_lockfile!)
      end

      package_json = JSON.parse(File.read(File.join(destination_root, "package.json")))
      expect(package_json["packageManager"]).to eq("yarn@1.22.22")
    end

    it "does not overwrite an existing packageManager value" do
      simulate_existing_file("package.json", <<~JSON)
        {
          "name": "dummy-app",
          "private": true,
          "packageManager": "pnpm@10.0.0"
        }
      JSON
      allow(Open3).to receive(:capture3)

      Dir.chdir(destination_root) do
        install_generator.send(:seed_package_manager_in_package_json_from_lockfile!)
      end

      package_json = JSON.parse(File.read(File.join(destination_root, "package.json")))
      expect(package_json["packageManager"]).to eq("pnpm@10.0.0")
      expect(Open3).not_to have_received(:capture3)
    end
  end

  describe "#resolve_browserslist_conflict_after_shakapacker_install" do
    let(:install_generator) { described_class.new([], {}, destination_root:) }

    before do
      prepare_destination
      simulate_existing_file(".browserslistrc", "defaults\n")
      simulate_existing_file("package.json", <<~JSON)
        {
          "name": "dummy-app",
          "private": true,
          "browserslist": ["defaults"],
          "packageManager": "yarn@1.22.22"
        }
      JSON
    end

    it "removes browserslist from package.json when .browserslistrc exists" do
      Dir.chdir(destination_root) do
        install_generator.send(:resolve_browserslist_conflict_after_shakapacker_install)
      end

      package_json = JSON.parse(File.read(File.join(destination_root, "package.json")))
      expect(package_json.key?("browserslist")).to be(false)
    end
  end

  describe "#ensure_jsx_in_js_compatibility" do
    let(:install_generator) { described_class.new([], {}, destination_root:) }

    before do
      prepare_destination
      simulate_existing_file("config/shakapacker.yml", <<~YML)
        default: &default
          javascript_transpiler: "swc"
      YML
      simulate_existing_file("app/javascript/src/components/App.js", <<~JS)
        export default function App() {
          return <>Hello</>
        }
      JS
      allow(install_generator).to receive_messages(
        using_swc?: true,
        add_packages: true,
        add_babel_react_dependencies: true
      )
    end

    it "switches to babel and installs babel dependencies when JSX is found in .js files" do
      Dir.chdir(destination_root) do
        install_generator.send(:ensure_jsx_in_js_compatibility)
      end

      shakapacker_yml = File.read(File.join(destination_root, "config/shakapacker.yml"))
      expect(shakapacker_yml).to include('javascript_transpiler: "babel"')
      expect(install_generator).to have_received(:add_packages).with(["babel-loader"], dev: true)
      expect(install_generator).to have_received(:add_babel_react_dependencies)
    end
  end

  describe "#add_bin_scripts" do
    let(:install_generator) { described_class.new([], {}, destination_root:) }

    before do
      prepare_destination
      simulate_existing_file("bin/dev", described_class::STOCK_RAILS_BIN_DEV)
    end

    it "replaces the stock Rails bin/dev without prompting" do
      Dir.chdir(destination_root) do
        install_generator.send(:add_bin_scripts)
      end

      assert_file "bin/dev" do |content|
        expect(content).to include('DEFAULT_ROUTE = "hello_world"')
        expect(content).to include("ReactOnRails::Dev::ServerManager")
      end
    end

    it "detects custom bin/dev files" do
      simulate_existing_file("bin/dev", "#!/usr/bin/env ruby\nputs 'custom'\n")

      Dir.chdir(destination_root) do
        expect(install_generator.send(:stock_rails_bin_dev?)).to be(false)
      end
    end

    it "emits the RSC manifest discovery logic in bin/shakapacker-precompile-hook" do
      # The shipped template hook is a separate implementation from spec/support's standalone copy;
      # pin its load-bearing pieces so an accidental edit/deletion fails here rather than silently in
      # a user's RSC build. The discovery build re-invokes bin/shakapacker, so the recursion guard
      # and the rsc_support_enabled? gate are critical.
      Dir.chdir(destination_root) do
        install_generator.send(:add_bin_scripts)
      end

      shared_hook_content = File.read(File.expand_path("../../support/shakapacker_precompile_hook_shared.rb", __dir__))
      extract_utf8_helper = lambda do |source|
        start_index = source.index("def utf8_subprocess_env")
        end_index = source.index(/\n(?:# Detect which package manager|def clear_stale_rsc_manifest_client_references)/)

        expect(start_index).not_to be_nil
        expect(end_index).not_to be_nil

        source[start_index...end_index]
      end

      assert_file "bin/shakapacker-precompile-hook" do |content|
        expect(content).to include("generate_rsc_manifest_client_references_if_needed")
        expect(content).to include("REACT_ON_RAILS_RSC_REGISTRATION_ENTRY_PATH")
        expect(content).to include("configured_rsc_manifest_registration_entry")
        expect(content).to include("valid_configured_rsc_registration_entry?")
        expect(content).to include("EXPECTED_RSC_REGISTRATION_ENTRY_BASENAME")
        expect(content).to include("File.file?(path)")
        expect(content).to include("EXCLUDED_RSC_REGISTRATION_ENTRY_PATH_COMPONENTS")
        expect(content).to include('ENV["RSC_REFERENCE_DISCOVERY_BUILD"] == "true"')
        expect(content).to include("ReactOnRailsPro::Utils.rsc_support_enabled?")
        expect(content).to include("def utf8_subprocess_env")
        expect(content).to include("def utf8_widened_rubyopt")
        expect(content).to include("def rubyopt_pins_encoding?")
        expect(content).to include('[Encoding::US_ASCII, Encoding::ASCII_8BIT].include?(Encoding.find("locale"))')
        expect(content).to include('"LANG" => "C.UTF-8"')
        expect(content).to include('"LC_ALL" => "C.UTF-8"')
        expect(content).to include('"RUBYOPT" => utf8_widened_rubyopt(subprocess_rubyopt(extra))')
        expect(content).to include('"REACT_ON_RAILS_SKIP_VALIDATION" => "true"')
        expect(content).to include('"RSC_BUNDLE_ONLY" => "true"')
        expect(content).to include('"CLIENT_BUNDLE_ONLY" => nil')
        expect(content).to include('"SERVER_BUNDLE_ONLY" => nil')
        expect(content).to include("Dir.chdir(Rails.root) do")
        expect(content).to include("system(env, shakapacker_bin.to_s, exception: true)")
        expect(extract_utf8_helper.call(content)).to eq(extract_utf8_helper.call(shared_hook_content))
      end
    end

    it "detects the legacy Rails foreman bin/dev template" do
      simulate_existing_file("bin/dev", <<~BASH)
        #!/usr/bin/env bash
        if ! gem list foreman -i --silent; then
          gem install foreman
        fi

        exec foreman start -f Procfile.dev "$@"
      BASH

      Dir.chdir(destination_root) do
        expect(install_generator.send(:stock_rails_bin_dev?)).to be(true)
      end
    end

    it "detects the unquoted legacy Rails foreman bin/dev template" do
      simulate_existing_file("bin/dev", <<~BASH)
        #!/usr/bin/env sh
        if ! gem list foreman -i --silent; then
          gem install foreman
        fi

        exec foreman start -f Procfile.dev $@
      BASH

      Dir.chdir(destination_root) do
        expect(install_generator.send(:stock_rails_bin_dev?)).to be(true)
      end
    end

    it "keeps customized legacy foreman bin/dev files" do
      simulate_existing_file("bin/dev", <<~BASH)
        #!/usr/bin/env bash
        if ! gem list foreman -i --silent; then
          gem install foreman
        fi

        echo "Custom startup logic"
        exec foreman start -f Procfile.dev "$@"
      BASH

      Dir.chdir(destination_root) do
        expect(install_generator.send(:stock_rails_bin_dev?)).to be(false)
      end
    end

    it "keeps stock bin/dev when run with --skip" do
      skip_generator = described_class.new([], { skip: true }, destination_root:)

      Dir.chdir(destination_root) do
        skip_generator.send(:add_bin_scripts)
      end

      assert_file "bin/dev", described_class::STOCK_RAILS_BIN_DEV
    end

    it "keeps custom bin/dev when run with --force" do
      custom_bin_dev = "#!/usr/bin/env ruby\nputs 'custom'\n"
      force_generator = described_class.new([], { force: true }, destination_root:)

      simulate_existing_file("bin/dev", custom_bin_dev)

      Dir.chdir(destination_root) do
        force_generator.send(:add_bin_scripts)
      end

      assert_file "bin/dev", custom_bin_dev
      assert_file "bin/switch-bundler"
      assert_file "bin/shakapacker-precompile-hook" do |content|
        expect(content).to include('stale_manifest = Rails.root.join("ssr-generated", "rsc-client-references.json")')
        expect(content).to include("REACT_ON_RAILS_RSC_REGISTRATION_ENTRY_PATH")
        expect(content).to include("clear_stale_rsc_manifest_client_references")
        expect(content).to include('shakapacker_bin = Rails.root.join("bin", "shakapacker")')
        expect(content).to include("bin/shakapacker is missing; cannot generate RSC manifest client references.")
        expect(content).to include("system(env, shakapacker_bin.to_s, exception: true)")
      end
    end

    it "keeps DEFAULT_ROUTE unchanged in custom bin/dev files for non-RSC installs" do
      custom_bin_dev = <<~RUBY
        #!/usr/bin/env ruby
        DEFAULT_ROUTE = "hello_world"
      RUBY
      simulate_existing_file("bin/dev", custom_bin_dev)

      Dir.chdir(destination_root) do
        install_generator.send(:add_bin_scripts)
      end

      assert_file "bin/dev", custom_bin_dev
    end

    it "warns instead of rewriting custom bin/dev files for --rsc installs" do
      rsc_install_generator = described_class.new([], { rsc: true }, destination_root:)
      custom_bin_dev = <<~RUBY
        #!/usr/bin/env ruby
        DEFAULT_ROUTE = "hello_world"
      RUBY
      simulate_existing_file("bin/dev", custom_bin_dev)

      allow(rsc_install_generator).to receive(:say_status).and_call_original
      expect(rsc_install_generator).to receive(:say_status).with(
        :warn,
        a_string_matching(%r{Custom bin/dev detected: update DEFAULT_ROUTE to "hello_server" manually for --rsc}),
        :yellow
      )

      Dir.chdir(destination_root) do
        rsc_install_generator.send(:add_bin_scripts)
      end

      assert_file "bin/dev", custom_bin_dev
    end
  end
end

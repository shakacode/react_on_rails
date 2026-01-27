# frozen_string_literal: true

require_relative "../support/generator_spec_helper"

describe RscGenerator, type: :generator do
  include GeneratorSpec::TestCase

  destination File.expand_path("../dummy-for-generators", __dir__)

  # Unit tests for prerequisite validation

  context "when Pro is not installed" do
    let(:generator) { described_class.new }

    before do
      allow(generator).to receive(:destination_root).and_return("/fake/path")
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?)
        .with("/fake/path/config/initializers/react_on_rails_pro.rb")
        .and_return(false)
    end

    specify "missing_pro_installation? returns true with helpful error" do
      expect(generator.send(:missing_pro_installation?)).to be true
      error_text = GeneratorMessages.messages.join("\n")
      expect(error_text).to include("React on Rails Pro is not installed")
      expect(error_text).to include("rails g react_on_rails:pro")
    end
  end

  # Integration test for standalone happy path

  context "when Pro is installed" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      # Simulate Pro initializer (must have multi-line block for gsub_file to work)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      # Simulate Procfile.dev exists for appending
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "adds RSC config to Pro initializer" do
      assert_file "config/initializers/react_on_rails_pro.rb" do |content|
        expect(content).to include("enable_rsc_support = true")
        expect(content).to include('rsc_bundle_js_file = "rsc-bundle.js"')
        expect(content).to include('rsc_payload_generation_url_path = "rsc_payload/"')
      end
    end

    it "creates RSC webpack config" do
      assert_file "config/webpack/rscWebpackConfig.js" do |content|
        expect(content).to include("rscConfig")
      end
    end

    it "creates HelloServer component" do
      assert_file "app/javascript/src/HelloServer/ror_components/HelloServer.jsx"
      assert_file "app/javascript/src/HelloServer/components/HelloServer.jsx"
    end

    it "creates HelloServerController" do
      assert_file "app/controllers/hello_server_controller.rb" do |content|
        expect(content).to include("HelloServerController")
      end
    end

    it "creates HelloServer view" do
      assert_file "app/views/hello_server/index.html.erb" do |content|
        expect(content).to include("HelloServer")
      end
    end

    it "adds RSC routes" do
      assert_file "config/routes.rb" do |content|
        expect(content).to include("rsc_payload_route")
        expect(content).to include("hello_server")
      end
    end

    it "adds rsc-bundle to Procfile.dev" do
      assert_file "Procfile.dev" do |content|
        expect(content).to include("rsc-bundle:")
        expect(content).to include("RSC_BUNDLE_ONLY")
      end
    end
  end

  # TypeScript variant

  context "when Pro is installed with --typescript" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")

      Dir.chdir(destination_root) do
        run_generator(["--typescript", "--force"])
      end
    end

    it "creates HelloServer component with tsx extension" do
      assert_file "app/javascript/src/HelloServer/ror_components/HelloServer.tsx"
      assert_file "app/javascript/src/HelloServer/components/HelloServer.tsx"
      assert_no_file "app/javascript/src/HelloServer/ror_components/HelloServer.jsx"
    end
  end
end

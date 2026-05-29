# frozen_string_literal: true

require "ripper"
require_relative "../support/generator_spec_helper"

RSpec.describe ReactOnRails::Generators::BaseGenerator, type: :generator do
  describe "managed webpack template map" do
    it "covers all webpack templates except explicitly handled files" do
      templates_root = described_class.source_root
      discovered_templates = Dir.glob(File.join(templates_root, "**/config/webpack/*.tt"))
                                .map { |path| path.delete_prefix("#{templates_root}/") }
                                .sort

      explicitly_handled_templates = %w[
        base/base/config/webpack/webpack.config.js.tt
        base/base/config/webpack/webpack.config.ts.tt
        base/base/config/webpack/rspack.config.js.tt
        base/base/config/webpack/rspack.config.ts.tt
      ]
      managed_templates = described_class.const_get(:MANAGED_WEBPACK_FILE_TEMPLATES).values.uniq.sort

      expect(discovered_templates - explicitly_handled_templates).to match_array(managed_templates)
    end
  end

  describe "#generate_new_app_home_page?" do
    it "returns false without calling add_root_route when --new-app is disabled" do
      base_generator = described_class.new

      expect(base_generator).not_to receive(:add_root_route)
      expect(base_generator.send(:generate_new_app_home_page?)).to be(false)
    end

    it "returns false without calling add_root_route when root-route state has not been initialized yet" do
      base_generator = described_class.new([], { new_app: true })

      expect(base_generator).not_to receive(:add_root_route)
      expect(base_generator.send(:generate_new_app_home_page?)).to be(false)
    end

    it "returns the initialized root-route state for --new-app" do
      base_generator = described_class.new([], { new_app: true })
      base_generator.instance_variable_set(:@new_app_root_route_added, true)

      expect(base_generator).not_to receive(:add_root_route)
      expect(base_generator.send(:generate_new_app_home_page?)).to be(true)
    end
  end

  describe "#copy_base_files in --pretend mode" do
    let(:base_generator) { described_class.new([], { pretend: true }) }

    it "does not chmod precompile hook script in copy_base_files" do
      allow(base_generator).to receive(:copy_file)
      allow(base_generator).to receive(:template)
      allow(base_generator).to receive_messages(
        use_rsc?: false,
        destination_root: "/fake/path"
      )

      expect(base_generator).to receive(:say_status)
        .with(:pretend, "Skipping chmod on shakapacker-precompile-hook in --pretend mode", :yellow)
      expect(File).not_to receive(:chmod)

      base_generator.copy_base_files
    end
  end

  describe "#add_configure_minitest_to_compile_assets" do
    let(:destination) { File.expand_path("../dummy-for-generators", __dir__) }
    let(:generator) { described_class.new([], {}, { destination_root: destination }) }
    let(:helper_path) { File.join(destination, "test/test_helper.rb") }

    before do
      FileUtils.mkdir_p(File.dirname(helper_path))
    end

    it "appends ensure_assets_compiled when only a commented-out line is present" do
      File.write(helper_path, <<~RUBY)
        require "rails/test_help"

        # ReactOnRails::TestHelper.ensure_assets_compiled
      RUBY

      generator.send(:add_configure_minitest_to_compile_assets, helper_path)

      helper_content = File.read(helper_path)
      expect(helper_content.scan("ReactOnRails::TestHelper.ensure_assets_compiled").size).to eq(2)
      expect(helper_content).to include("ActiveSupport::TestCase.setup do")
    end

    it "does not append a duplicate active ensure_assets_compiled call" do
      File.write(helper_path, <<~RUBY)
        require "rails/test_help"

        ActiveSupport::TestCase.setup do
          ReactOnRails::TestHelper.ensure_assets_compiled
        end
      RUBY

      generator.send(:add_configure_minitest_to_compile_assets, helper_path)

      helper_content = File.read(helper_path)
      expect(helper_content.scan("ReactOnRails::TestHelper.ensure_assets_compiled").size).to eq(1)
    end
  end

  describe "#add_configure_rspec_to_compile_assets" do
    let(:destination) { File.expand_path("../dummy-for-generators", __dir__) }
    let(:generator) { described_class.new([], {}, { destination_root: destination }) }
    let(:helper_path) { File.join(destination, "spec/rails_helper.rb") }

    before do
      FileUtils.mkdir_p(File.dirname(helper_path))
    end

    it "preserves an existing active helper call" do
      File.write(helper_path, <<~RUBY)
        RSpec.configure do |config|
          ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
        end
      RUBY

      generator.send(:add_configure_rspec_to_compile_assets, helper_path)

      helper_content = File.read(helper_path)
      expect(helper_content.scan("ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)").size).to eq(1)
    end

    it "replaces only the first RSpec.configure block when wiring is missing" do
      File.write(helper_path, <<~RUBY)
        RSpec.configure do |config|
          config.before(:suite) { nil }
        end

        RSpec.configure do |config|
          config.example_status_persistence_file_path = "spec/examples.txt"
        end
      RUBY

      generator.send(:add_configure_rspec_to_compile_assets, helper_path)

      helper_content = File.read(helper_path)
      expect(helper_content.scan("ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)").size).to eq(1)
      expect(helper_content.scan("RSpec.configure do |config|").size).to eq(2)
      expect(helper_content).to include('config.example_status_persistence_file_path = "spec/examples.txt"')
      expect(Ripper.sexp(helper_content)).not_to be_nil
    end
  end

  describe "#cleanup_stale_webpack_config_dir_for_rspack messaging" do
    let(:destination) { File.expand_path("../dummy-for-generators", __dir__) }
    let(:generator) { described_class.new([], { rspack: true }, { destination_root: destination }) }
    let(:webpack_dir) { File.join(destination, "config/webpack") }

    before do
      FileUtils.rm_rf(destination)
      FileUtils.mkdir_p(webpack_dir)
    end

    after do
      FileUtils.rm_rf(destination)
    end

    it "logs a skip message when config/webpack exists but is empty" do
      expect(generator).to receive(:say_status).with(:skip, "config/webpack (empty directory, leaving as-is)", :yellow)

      generator.send(:cleanup_stale_webpack_config_dir_for_rspack)

      expect(File.directory?(webpack_dir)).to be(true)
    end

    it "logs a clearer warning when only dotfiles are present" do
      File.write(File.join(webpack_dir, ".gitkeep"), "")
      expect(generator).to receive(:say_status)
        .with(:warning, "Keeping config/webpack; only dotfiles found: .gitkeep", :yellow)

      generator.send(:cleanup_stale_webpack_config_dir_for_rspack)

      expect(File.directory?(webpack_dir)).to be(true)
    end
  end

  describe "#using_rspack? default bundler resolution" do
    let(:destination) { File.expand_path("../dummy-for-generators", __dir__) }

    def base_generator(options = {})
      described_class.new([], options, { destination_root: destination })
    end

    def write_shakapacker_yml(assets_bundler)
      FileUtils.mkdir_p(File.join(destination, "config"))
      File.write(File.join(destination, "config/shakapacker.yml"), <<~YAML)
        default: &default
          source_path: app/javascript
          assets_bundler: #{assets_bundler}
        development:
          <<: *default
      YAML
    end

    before { FileUtils.rm_rf(destination) }
    after { FileUtils.rm_rf(destination) }

    it "declares --rspack without a static default so the fresh-install default applies" do
      # Regression guard (see install_generator_spec for full rationale): a `default:` on the
      # --rspack class_option would make options.key?(:rspack) always true and silently break the
      # fresh-install Rspack default for unflagged CLI runs.
      expect(described_class.class_options[:rspack].default).to be_nil
    end

    it "defaults a fresh install (no flag, no existing config) to Rspack" do
      expect(base_generator.using_rspack?).to be(true)
    end

    it "falls back to Webpack on a fresh install when Rspack is unsupported (Shakapacker < 9.0)" do
      generator = base_generator
      allow(generator).to receive(:shakapacker_version_9_or_higher?).and_return(false)

      expect(generator.using_rspack?).to be(false)
    end

    it "honors an explicit --no-rspack" do
      expect(base_generator(rspack: false).using_rspack?).to be(false)
    end

    it "honors an explicit --rspack" do
      expect(base_generator(rspack: true).using_rspack?).to be(true)
    end

    it "does not flip an existing Webpack app that omits the flag" do
      write_shakapacker_yml("webpack")

      expect(base_generator.using_rspack?).to be(false)
    end

    it "keeps Rspack for an existing Rspack app that omits the flag" do
      write_shakapacker_yml("rspack")

      expect(base_generator.using_rspack?).to be(true)
    end

    it "lets an explicit --no-rspack override an existing Rspack app" do
      write_shakapacker_yml("rspack")

      expect(base_generator(rspack: false).using_rspack?).to be(false)
    end
  end
end

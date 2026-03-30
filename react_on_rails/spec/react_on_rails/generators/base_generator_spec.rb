# frozen_string_literal: true

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
end

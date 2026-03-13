# frozen_string_literal: true

require_relative "../support/generator_spec_helper"

RSpec.describe ReactOnRails::Generators::BaseGenerator, type: :generator do
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
end

# frozen_string_literal: true

require_relative "../spec_helper"

describe ReactOnRails::TestHelper::EnsureAssetsCompiled do
  describe "#ensureAssetsCompiled" do
    let(:compiler) { double_assets_compiler }

    after { described_class.has_been_run = false }

    before do
      allow(ReactOnRails::WebpackerUtils).to receive(:check_manifest_not_cached).and_return(nil)
      double_packs = instance_double(ReactOnRails::PacksGenerator)
      allow(ReactOnRails::PacksGenerator).to receive(:instance).and_return(double_packs)
      allow(double_packs).to receive(:generate_packs_if_stale)
    end

    context "when assets are not up to date" do
      let(:assets_checker) do
        double_assets_checker(stale_generated_webpack_files:
                                                     %w[client-bundle.js server-bundle.js])
      end

      it "compiles the webpack assets" do
        expect(compiler).to receive(:compile_assets).once
        invoke_ensurer_with_doubles
      end
    end

    context "when assets are up to date" do
      let(:assets_checker) { double_assets_checker(stale_generated_webpack_files: []) }

      it "does nothing" do
        expect(compiler).not_to receive(:compile_assets)
        invoke_ensurer_with_doubles
      end
    end

    def invoke_ensurer_with_doubles
      ReactOnRails::TestHelper.ensure_assets_compiled(
        webpack_assets_status_checker: assets_checker,
        webpack_assets_compiler: compiler
      )
    end

    def double_assets_checker(args = {})
      instance_double(ReactOnRails::TestHelper::WebpackAssetsStatusChecker,
                      stale_generated_webpack_files: args.fetch(:stale_generated_webpack_files))
    end

    def double_assets_compiler
      instance_double(ReactOnRails::TestHelper::WebpackAssetsCompiler,
                      :compile_assets)
    end
  end
end

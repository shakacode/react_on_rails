require_relative "../spec_helper"

describe ReactOnRails::TestHelper do
  describe "#ensureAssetsCompiled" do
    let(:compiler) { double_assets_compiler }
    after { ReactOnRails::TestHelper::EnsureAssetsCompiled.has_been_run = false }

    context "when assets are not up to date" do
      let(:assets_checker) do
        double_assets_checker(stale_generated_webpack_files:
                                                     %w( client-bundle.js server-bundle.js ))
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
        webpack_assets_compiler: compiler)
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

require_relative "simplecov_helper"
require_relative "spec_helper"

module ReactOnRails
  describe EnsureAssetsCompiled do
    let(:compiler) { double_assets_compiler }
    after { ReactOnRails::EnsureAssetsCompiled.has_been_run = false }

    context "when assets are not up to date" do
      let(:assets_checker) { double_assets_checker(up_to_date: false) }

      context "and webpack process is running" do
        let(:process_checker) { double_process_checker(running: true) }

        it "sleeps until assets are up to date" do
          expect(compiler).not_to receive(:compile)

          thread = Thread.new { invoke_ensurer }

          sleep 1
          allow(assets_checker).to receive(:up_to_date?).and_return(true)

          thread.join

          expect(ReactOnRails::EnsureAssetsCompiled.has_been_run).to eq(true)
        end
      end

      context "and webpack process is NOT running" do
        let(:process_checker) { double_process_checker(running: false) }

        it "compiles the webpack assets" do
          expect(compiler).to receive(:compile).once
          invoke_ensurer
        end
      end
    end

    context "when assets are up to date" do
      let(:assets_checker) { double_assets_checker(up_to_date: true) }
      let(:process_checker) { double_process_checker(running: false) }

      it "does nothing" do
        expect(compiler).not_to receive(:compile)
        invoke_ensurer
      end
    end

    def invoke_ensurer
      EnsureAssetsCompiled.invoke(
        webpack_assets_checker: assets_checker,
        webpack_assets_compiler: compiler,
        webpack_process_checker: process_checker)
    end

    def double_process_checker(args = {})

      instance_double(WebpackProcessChecker, running?: args.fetch(:running))
    end

    def double_assets_checker(args = {})
      instance_double(WebpackAssetsStatusChecker, up_to_date?: args.fetch(:up_to_date))
    end

    def double_assets_compiler
      instance_double(WebpackAssetsCompiler, :compile)
    end
  end
end

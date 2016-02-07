require_relative "simplecov_helper"
require_relative "spec_helper"

describe ReactOnRails::TestHelper do
  describe "#ensureAssetsCompiled"
  let(:compiler) { double_assets_compiler }
  after { ReactOnRails::TestHelper::EnsureAssetsCompiled.has_been_run = false }

  context "when assets are not up to date" do
    let(:assets_checker) { double_assets_checker(up_to_date: false) }

    context "and webpack process is running" do
      let(:process_checker) { double_process_checker(running: true) }

      it "sleeps until assets are up to date" do
        expect(compiler).not_to receive(:compile)

        thread = Thread.new { invoke_ensurer_with_doubles }

        sleep 0.1
        allow(assets_checker).to receive(:up_to_date?).and_return(true)

        thread.join

        expect(ReactOnRails::TestHelper::EnsureAssetsCompiled.has_been_run).to eq(true)
      end
    end

    context "and webpack process is NOT running" do
      let(:process_checker) { double_process_checker(running: false) }

      it "compiles the webpack assets" do
        expect(compiler).to receive(:compile).once
        invoke_ensurer_with_doubles
      end
    end
  end

  context "when assets are up to date" do
    let(:assets_checker) { double_assets_checker(up_to_date: true) }
    let(:process_checker) { double_process_checker(running: false) }

    it "does nothing" do
      expect(compiler).not_to receive(:compile)
      invoke_ensurer_with_doubles
    end
  end

  def invoke_ensurer_with_doubles
    ReactOnRails::TestHelper.ensure_assets_compiled(
      webpack_assets_status_checker: assets_checker,
      webpack_assets_compiler: compiler,
      webpack_process_checker: process_checker)
  end

  def double_process_checker(args = {})
    instance_double(ReactOnRails::TestHelper::WebpackProcessChecker,
                    running?: args.fetch(:running))
  end

  def double_assets_checker(args = {})
    instance_double(ReactOnRails::TestHelper::WebpackAssetsStatusChecker,
                    up_to_date?: args.fetch(:up_to_date))
  end

  def double_assets_compiler
    instance_double(ReactOnRails::TestHelper::WebpackAssetsCompiler,
                    :compile)
  end
end

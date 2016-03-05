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

      context "and webpack process is running" do
        let(:process_checker) do
          double_process_checker(client_running?: true,
                                 server_running?: true,
                                 hot_running?: false)
        end

        it "sleeps until assets are up to date" do
          expect(compiler).not_to receive(:compile_as_necessary)

          thread = Thread.new { invoke_ensurer_with_doubles }

          sleep 0.1
          allow(assets_checker).to receive(:stale_generated_webpack_files).and_return([])

          thread.join

          expect(ReactOnRails::TestHelper::EnsureAssetsCompiled.has_been_run).to eq(true)
        end
      end

      context "and webpack process is NOT running" do
        let(:process_checker) do
          double_process_checker(client_running?: false,
                                 server_running?: false,
                                 hot_running?: false)
        end

        it "compiles the webpack assets" do
          expect(compiler).to receive(:compile_as_necessary).once
          invoke_ensurer_with_doubles
        end
      end

      context "and hot reloading (only server webpack running)" do
        let(:process_checker) do
          double_process_checker(client_running?: false,
                                 server_running?: true,
                                 hot_running?: true)
        end

        it "compiles the webpack assets" do
          expect(compiler).to receive(:compile_as_necessary).never
          expect(compiler).to receive(:compile_client).once
          thread = Thread.new { invoke_ensurer_with_doubles }

          sleep 0.1
          allow(assets_checker).to receive(:stale_generated_webpack_files).and_return([])

          thread.join

          expect(ReactOnRails::TestHelper::EnsureAssetsCompiled.has_been_run).to eq(true)
        end
      end
    end

    context "when assets are up to date" do
      let(:assets_checker) { double_assets_checker(stale_generated_webpack_files: []) }
      let(:process_checker) do
        double_process_checker(client_running?: true,
                               server_running?: true,
                               hot_running?: false)
      end

      it "does nothing" do
        expect(compiler).not_to receive(:compile_as_necessary)
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
                      client_running?: args.fetch(:client_running?),
                      server_running?: args.fetch(:server_running?),
                      hot_running?: args.fetch(:hot_running?))
    end

    def double_assets_checker(args = {})
      instance_double(ReactOnRails::TestHelper::WebpackAssetsStatusChecker,
                      stale_generated_webpack_files: args.fetch(:stale_generated_webpack_files))
    end

    def double_assets_compiler
      instance_double(ReactOnRails::TestHelper::WebpackAssetsCompiler,
                      :compile_as_necessary)
    end
  end
end

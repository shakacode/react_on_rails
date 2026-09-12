# frozen_string_literal: true

require_relative "spec_helper"
require_relative "support/version_test_helpers"

class FakeLogger
  attr_accessor :message

  def error(message)
    self.message = message
  end
end

module ReactOnRails # rubocop:disable Metrics/ModuleLength
  describe VersionChecker do
    describe "#validate_version_and_package_compatibility!" do
      let(:logger) { FakeLogger.new }

      before do
        # Stub ReactOnRails::Utils.react_on_rails_pro? to return false by default
        allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(false)
      end

      context "when both react-on-rails and react-on-rails-pro packages are installed" do
        let(:node_package_version) do
          instance_double(VersionChecker::NodePackageVersion,
                          react_on_rails_package?: true,
                          react_on_rails_pro_package?: true,
                          raw: "16.1.1",
                          local_path_or_url?: false,
                          package_json: "/fake/path/package.json")
        end

        it "raises an error" do
          expect { check_version_and_raise(node_package_version) }
            .to raise_error(ReactOnRails::Error,
                            /Both 'react-on-rails' and 'react-on-rails-pro' packages are installed/)
        end
      end

      context "when neither react-on-rails nor react-on-rails-pro packages are installed" do
        let(:node_package_version) do
          instance_double(VersionChecker::NodePackageVersion,
                          react_on_rails_package?: false,
                          react_on_rails_pro_package?: false,
                          raw: nil,
                          local_path_or_url?: false,
                          package_json: "/fake/path/package.json")
        end

        before do
          stub_gem_version("16.1.1")
        end

        it "raises an error" do
          expect { check_version_and_raise(node_package_version) }
            .to raise_error(ReactOnRails::Error,
                            /No React on Rails npm package is installed/)
        end
      end

      context "when Pro gem is installed but using base package" do
        let(:node_package_version) do
          instance_double(VersionChecker::NodePackageVersion,
                          react_on_rails_package?: true,
                          react_on_rails_pro_package?: false,
                          raw: "16.1.1",
                          local_path_or_url?: false,
                          semver_wildcard?: false,
                          parts: %w[16 1 1],
                          package_json: "/fake/path/package.json")
        end

        before do
          allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(true)
          stub_gem_version("16.1.1")
        end

        it "raises an error" do
          expect { check_version_and_raise(node_package_version) }
            .to raise_error(ReactOnRails::Error,
                            /You have the Pro gem installed but are using the base 'react-on-rails' package/)
        end
      end

      context "when Pro package is installed but Pro gem is not" do
        let(:node_package_version) do
          instance_double(VersionChecker::NodePackageVersion,
                          react_on_rails_package?: false,
                          react_on_rails_pro_package?: true,
                          raw: "16.1.1",
                          local_path_or_url?: false,
                          semver_wildcard?: false,
                          parts: %w[16 1 1],
                          package_name: "react-on-rails-pro",
                          package_json: "/fake/path/package.json")
        end

        before do
          allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(false)
          stub_gem_version("16.1.1")
        end

        it "raises an error" do
          expect { check_version_and_raise(node_package_version) }
            .to raise_error(ReactOnRails::Error,
                            /You have the 'react-on-rails-pro' package installed but the Pro gem is not installed/)
        end
      end

      describe "lockfile robustness" do
        # Runs the real NodePackageVersion against a fixtures/lockfiles/<dir> directory so the
        # actual fixture lockfiles are read (no File stubbing).
        def validate_fixture!(fixture_dir)
          package_json = File.expand_path("fixtures/lockfiles/#{fixture_dir}/package.json", __dir__)
          allow(Rails).to receive(:root).and_return(Pathname.new(File.dirname(package_json)))
          allow(ReactOnRails).to receive_message_chain(:configuration, :node_modules_location).and_return("")
          node_package_version = VersionChecker::NodePackageVersion.new(package_json)
          VersionChecker.new(node_package_version).validate_version_and_package_compatibility!
        end

        # A lockfile the parsers cannot use must behave exactly like a missing one: resolution
        # falls back to the package.json version (an exact pin in these fixtures), and boot
        # succeeds — a bad lockfile must never crash the Rails initializer.
        %w[pnpm_corrupt pnpm_wrong_shape pnpm_yaml_alias pnpm_invalid_encoding
           bun_invalid_encoding].each do |fixture|
          context "when the lockfile is unusable (#{fixture})" do
            it "falls back to package.json and boots" do
              stub_gem_version("16.6.0")
              expect { validate_fixture!(fixture) }.not_to raise_error
            end
          end
        end

        context "when only the binary bun.lockb exists" do
          it "is not parsed; package.json is used and boot succeeds with an exact pin" do
            stub_gem_version("16.6.0")
            expect { validate_fixture!("bun_lockb") }.not_to raise_error
          end
        end
      end

      context "when package version is not exact (has semver wildcard)" do
        let(:node_package_version) do
          instance_double(VersionChecker::NodePackageVersion,
                          react_on_rails_package?: true,
                          react_on_rails_pro_package?: false,
                          raw: "^16.1.1",
                          local_path_or_url?: false,
                          workspace_protocol?: false,
                          semver_wildcard?: true,
                          package_name: "react-on-rails",
                          package_json: "/fake/path/package.json")
        end

        before { stub_gem_version("16.1.1") }

        it "raises an error" do
          expect { check_version_and_raise(node_package_version) }
            .to raise_error(ReactOnRails::Error, /The 'react-on-rails' package version is not an exact version/)
        end
      end

      context "when package version does not match gem version" do
        let(:node_package_version) do
          instance_double(VersionChecker::NodePackageVersion,
                          react_on_rails_package?: true,
                          react_on_rails_pro_package?: false,
                          raw: "16.1.2",
                          local_path_or_url?: false,
                          workspace_protocol?: false,
                          semver_wildcard?: false,
                          parts: %w[16 1 2],
                          package_name: "react-on-rails",
                          package_json: "/fake/path/package.json")
        end

        before { stub_gem_version("16.1.1") }

        it "raises an error" do
          expect { check_version_and_raise(node_package_version) }
            .to raise_error(ReactOnRails::Error, /The 'react-on-rails' package version does not match the gem version/)
        end
      end

      context "when versions match exactly" do
        let(:node_package_version) do
          instance_double(VersionChecker::NodePackageVersion,
                          react_on_rails_package?: true,
                          react_on_rails_pro_package?: false,
                          raw: "16.1.1",
                          local_path_or_url?: false,
                          workspace_protocol?: false,
                          semver_wildcard?: false,
                          parts: %w[16 1 1],
                          package_json: "/fake/path/package.json")
        end

        before { stub_gem_version("16.1.1") }

        it "does not raise an error" do
          expect { check_version_and_raise(node_package_version) }.not_to raise_error
        end
      end

      context "when using local path" do
        let(:node_package_version) do
          instance_double(VersionChecker::NodePackageVersion,
                          react_on_rails_package?: true,
                          react_on_rails_pro_package?: false,
                          raw: "file:../react-on-rails",
                          local_path_or_url?: true,
                          workspace_protocol?: false,
                          semver_wildcard?: false,
                          package_json: "/fake/path/package.json")
        end

        before { stub_gem_version("16.1.1") }

        it "does not raise an error" do
          expect { check_version_and_raise(node_package_version) }.not_to raise_error
        end
      end

      context "when using pnpm workspace protocol" do
        let(:node_package_version) do
          instance_double(VersionChecker::NodePackageVersion,
                          react_on_rails_package?: true,
                          react_on_rails_pro_package?: false,
                          raw: "workspace:*",
                          local_path_or_url?: false,
                          workspace_protocol?: true,
                          semver_wildcard?: false,
                          package_json: "/fake/path/package.json")
        end

        before { stub_gem_version("16.1.1") }

        it "does not raise an error" do
          expect { check_version_and_raise(node_package_version) }.not_to raise_error
        end
      end

      context "when Pro gem and Pro package are both installed with matching versions" do
        let(:node_package_version) do
          instance_double(VersionChecker::NodePackageVersion,
                          react_on_rails_package?: false,
                          react_on_rails_pro_package?: true,
                          raw: "16.1.1",
                          local_path_or_url?: false,
                          workspace_protocol?: false,
                          semver_wildcard?: false,
                          parts: %w[16 1 1],
                          package_json: "/fake/path/package.json")
        end

        before do
          allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(true)
          stub_gem_version("16.1.1")
        end

        it "does not raise an error" do
          expect { check_version_and_raise(node_package_version) }.not_to raise_error
        end
      end

      context "when React Server Components are enabled with Rspack" do
        def write_rsc_rspack_project(root, assets_bundler:, rspack_core_version:, rsc_enabled:)
          write_rsc_rspack_project_files(root, assets_bundler:, rspack_core_version:)
          stub_rsc_rspack_project(root, rsc_enabled:)
        end

        def write_rsc_rspack_project_files(
          root,
          assets_bundler:,
          rspack_core_version:,
          dependency_field: "devDependencies",
          rspack_package_versions: {},
          installed_rspack_core_version: nil,
          package_manager: nil
        )
          FileUtils.mkdir_p(File.join(root, "config"))
          File.write(File.join(root, "config/shakapacker.yml"), <<~YAML)
            default:
              assets_bundler: #{assets_bundler}
          YAML

          package_json = {
            "dependencies" => { "react-on-rails-pro" => "17.0.0" },
            "devDependencies" => {}
          }
          package_json["packageManager"] = package_manager if package_manager
          if rspack_core_version
            package_json[dependency_field] ||= {}
            package_json[dependency_field]["@rspack/core"] = rspack_core_version
          end
          rspack_package_versions.each do |package_name, package_version|
            package_json[dependency_field] ||= {}
            package_json[dependency_field][package_name] = package_version
          end
          File.write(
            File.join(root, "package.json"),
            JSON.generate(package_json)
          )

          return unless installed_rspack_core_version

          FileUtils.mkdir_p(File.join(root, "node_modules/@rspack/core"))
          File.write(
            File.join(root, "node_modules/@rspack/core/package.json"),
            JSON.generate("name" => "@rspack/core", "version" => installed_rspack_core_version)
          )
        end

        def stub_rsc_rspack_project(root, rsc_enabled:, configuration_error: nil, node_modules_location: "")
          allow(Rails).to receive(:root).and_return(Pathname.new(root))
          allow(ReactOnRails).to receive_message_chain(:configuration, :node_modules_location)
            .and_return(node_modules_location)
          allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(true)
          stub_gem_version("17.0.0")

          stub_const("ReactOnRailsPro", Module.new)
          stub_const("ReactOnRailsPro::Configuration", Class.new)
          if configuration_error
            ReactOnRailsPro.define_singleton_method(:configuration) { raise configuration_error }
            return
          end

          pro_config = instance_double(ReactOnRailsPro::Configuration, enable_rsc_support: rsc_enabled)
          ReactOnRailsPro.define_singleton_method(:configuration) { pro_config }
        end

        def validate_rsc_rspack_project(
          assets_bundler:,
          rspack_core_version:,
          rsc_enabled: true,
          dependency_field: "devDependencies",
          rspack_package_versions: {},
          installed_rspack_core_version: nil,
          package_manager: nil,
          configuration_error: nil,
          env_assets_bundler: nil,
          package_json_read_error_after_version_cache: false
        )
          previous_bundler = ENV.fetch("SHAKAPACKER_ASSETS_BUNDLER", nil)
          if env_assets_bundler.nil?
            ENV.delete("SHAKAPACKER_ASSETS_BUNDLER")
          else
            ENV["SHAKAPACKER_ASSETS_BUNDLER"] = env_assets_bundler
          end

          Dir.mktmpdir do |root|
            write_rsc_rspack_project_files(
              root,
              assets_bundler:,
              rspack_core_version:,
              dependency_field:,
              rspack_package_versions:,
              installed_rspack_core_version:,
              package_manager:
            )
            stub_rsc_rspack_project(root, rsc_enabled:, configuration_error:)
            package_json = File.join(root, "package.json")
            node_package_version = VersionChecker::NodePackageVersion.new(package_json)
            if package_json_read_error_after_version_cache
              node_package_version.raw
              allow(File).to receive(:read).and_call_original
              allow(File).to receive(:read).with(package_json).and_raise(Errno::EACCES)
            end
            VersionChecker.new(node_package_version).validate_version_and_package_compatibility!
          end
        ensure
          if previous_bundler.nil?
            ENV.delete("SHAKAPACKER_ASSETS_BUNDLER")
          else
            ENV["SHAKAPACKER_ASSETS_BUNDLER"] = previous_bundler
          end
        end

        def stub_failed_node_package_resolution
          status = instance_double(Process::Status, success?: false)
          allow(Open3).to receive(:capture3).and_return(["", "Cannot find module", status])
        end

        def expect_rsc_rspack_boot_warning(detected_version)
          allow(Rails.logger).to receive(:warn)

          yield

          expect(Rails.logger).to have_received(:warn).with(
            a_string_including(
              "[React on Rails] Could not verify @rspack/core >= v2 for RSC",
              "(detected: #{detected_version})",
              "react_on_rails:doctor"
            )
          )
        end

        it "raises before boot when active Rspack is v1" do
          expect { validate_rsc_rspack_project(assets_bundler: "rspack", rspack_core_version: "^1.6.0") }
            .to raise_error(ReactOnRails::Error, /RSC with Rspack requires Rspack v2 or newer/)
        end

        it "normalizes simple declared ranges in Rspack v2 errors" do
          expect { validate_rsc_rspack_project(assets_bundler: "rspack", rspack_core_version: "^1.6.0") }
            .to raise_error(ReactOnRails::Error, %r{Detected @rspack/core: 1\.6\.0})
        end

        it "rejects upper-bound declared Rspack ranges" do
          stub_failed_node_package_resolution

          expect { validate_rsc_rspack_project(assets_bundler: "rspack", rspack_core_version: "<2.0.0") }
            .to raise_error(ReactOnRails::Error, %r{Detected @rspack/core: <2\.0\.0})
        end

        it "rejects spaced upper-bound declared Rspack ranges" do
          stub_failed_node_package_resolution

          expect { validate_rsc_rspack_project(assets_bundler: "rspack", rspack_core_version: "< 2.0.0") }
            .to raise_error(ReactOnRails::Error, %r{Detected @rspack/core: < 2\.0\.0})
        end

        it "rejects declared Rspack OR ranges whose alternatives are all below v2" do
          stub_failed_node_package_resolution

          expect { validate_rsc_rspack_project(assets_bundler: "rspack", rspack_core_version: "^1.0.0 || ~1.6.0") }
            .to raise_error(ReactOnRails::Error, %r{Detected @rspack/core: \^1\.0\.0 \|\| ~1\.6\.0})
        end

        it "warns and allows boot for declared Rspack OR ranges that can select v2" do
          stub_failed_node_package_resolution

          expect_rsc_rspack_boot_warning("^1.0.0 || ^2.0.0") do
            expect do
              validate_rsc_rspack_project(
                assets_bundler: "rspack",
                rspack_core_version: "^1.0.0 || ^2.0.0"
              )
            end.not_to raise_error
          end
        end

        it "rejects aliased declared Rspack ranges below v2" do
          stub_failed_node_package_resolution

          expect { validate_rsc_rspack_project(assets_bundler: "rspack", rspack_core_version: "npm:@rspack/core@^1") }
            .to raise_error(ReactOnRails::Error, %r{Detected @rspack/core: npm:@rspack/core@\^1})
        end

        it "rejects declared Rspack hyphen ranges below v2" do
          stub_failed_node_package_resolution

          expect { validate_rsc_rspack_project(assets_bundler: "rspack", rspack_core_version: "1.0.0 - 1.9.9") }
            .to raise_error(ReactOnRails::Error, %r{Detected @rspack/core: 1\.0\.0 - 1\.9\.9})
        end

        it "rejects declared compound Rspack ranges with static v1 clauses" do
          stub_failed_node_package_resolution

          aggregate_failures do
            ["^1.0.0 <3.0.0", "~1.6.0 <3.0.0", "1.x <3.0.0"].each do |rspack_core_version|
              expect { validate_rsc_rspack_project(assets_bundler: "rspack", rspack_core_version:) }
                .to raise_error(ReactOnRails::Error, %r{Detected @rspack/core: #{Regexp.escape(rspack_core_version)}})
            end
          end
        end

        it "rejects exact declared Rspack versions below v1" do
          stub_failed_node_package_resolution

          expect { validate_rsc_rspack_project(assets_bundler: "rspack", rspack_core_version: "0.7.0") }
            .to raise_error(ReactOnRails::Error, %r{Detected @rspack/core: 0\.7\.0})
        end

        it "rejects upper-bound declared Rspack ranges below v2" do
          stub_failed_node_package_resolution

          expect { validate_rsc_rspack_project(assets_bundler: "rspack", rspack_core_version: "<1.6.0") }
            .to raise_error(ReactOnRails::Error, %r{Detected @rspack/core: <1\.6\.0})
        end

        it "allows Node-resolved Rspack v2 for open lower-bound ranges below v2" do
          Dir.mktmpdir do |root|
            write_rsc_rspack_project_files(root, assets_bundler: "rspack", rspack_core_version: ">=1.6.0")
            resolved_package_json = File.join(root, "resolved-packages/@rspack/core/package.json")
            FileUtils.mkdir_p(File.dirname(resolved_package_json))
            File.write(
              resolved_package_json,
              JSON.generate("name" => "@rspack/core", "version" => "2.1.0")
            )
            stub_rsc_rspack_project(root, rsc_enabled: true)
            node_package_version = VersionChecker::NodePackageVersion.new(File.join(root, "package.json"))
            status = instance_double(Process::Status, success?: true)
            allow(Open3).to receive(:capture3)
              .and_return(["#{resolved_package_json}\n", "", status])

            expect { described_class.new(node_package_version).validate_version_and_package_compatibility! }
              .not_to raise_error
            expect(Open3).to have_received(:capture3).with(
              "node",
              "-e",
              ReactOnRails::RscRspackSupport::NODE_PACKAGE_RESOLUTION_SCRIPT,
              "@rspack/core",
              File.join(root, "node_modules"),
              chdir: root
            )
          end
        end

        it "uses Node resolution before a stale flat node_modules package" do
          Dir.mktmpdir do |root|
            write_rsc_rspack_project_files(
              root,
              assets_bundler: "rspack",
              rspack_core_version: "latest",
              installed_rspack_core_version: "2.1.0"
            )
            resolved_package_json = File.join(root, "resolved-packages/@rspack/core/package.json")
            FileUtils.mkdir_p(File.dirname(resolved_package_json))
            File.write(
              resolved_package_json,
              JSON.generate("name" => "@rspack/core", "version" => "1.6.0")
            )
            stub_rsc_rspack_project(root, rsc_enabled: true)
            node_package_version = VersionChecker::NodePackageVersion.new(File.join(root, "package.json"))
            status = instance_double(Process::Status, success?: true)
            allow(Open3).to receive(:capture3)
              .and_return(["#{resolved_package_json}\n", "", status])

            expect { described_class.new(node_package_version).validate_version_and_package_compatibility! }
              .to raise_error(ReactOnRails::Error, %r{Detected @rspack/core: 1\.6\.0})
          end
        end

        it "rejects incompatible declarations before stale flat node_modules packages" do
          stub_failed_node_package_resolution

          expect do
            validate_rsc_rspack_project(
              assets_bundler: "rspack",
              rspack_core_version: "^1.6.0",
              installed_rspack_core_version: "2.1.0"
            )
          end.to raise_error(ReactOnRails::Error, %r{Detected @rspack/core: 1\.6\.0})
        end

        it "rejects shorthand declared Rspack v1 ranges" do
          stub_failed_node_package_resolution

          aggregate_failures do
            %w[^1 ~1 1 =1].each do |rspack_core_version|
              expect { validate_rsc_rspack_project(assets_bundler: "rspack", rspack_core_version:) }
                .to raise_error(ReactOnRails::Error, %r{Detected @rspack/core: #{Regexp.escape(rspack_core_version)}})
            end
          end
        end

        it "allows compatible shorthand declared Rspack ranges without Node resolution" do
          allow(Open3).to receive(:capture3)

          aggregate_failures do
            %w[^2 ~2 2 2.x =2].each do |rspack_core_version|
              expect { validate_rsc_rspack_project(assets_bundler: "rspack", rspack_core_version:) }
                .not_to raise_error
            end
          end

          expect(Open3).not_to have_received(:capture3)
        end

        it "allows compatible aliased shorthand Rspack ranges without Node resolution" do
          allow(Open3).to receive(:capture3)

          expect do
            validate_rsc_rspack_project(
              assets_bundler: "rspack",
              rspack_core_version: "npm:@rspack/core@^2"
            )
          end.not_to raise_error

          expect(Open3).not_to have_received(:capture3)
        end

        it "warns and allows boot when the RSC Rspack version is undeterminable" do
          allow(Open3).to receive(:capture3).and_raise(Errno::ENOENT)

          expect_rsc_rspack_boot_warning("latest") do
            expect { validate_rsc_rspack_project(assets_bundler: "rspack", rspack_core_version: "latest") }
              .not_to raise_error
          end
        end

        it "warns and allows boot for unsupported npm ranges when the installed package cannot be resolved" do
          stub_failed_node_package_resolution

          expect_rsc_rspack_boot_warning(">=2.0.0 <3.0.0") do
            expect do
              validate_rsc_rspack_project(
                assets_bundler: "rspack",
                rspack_core_version: ">=2.0.0 <3.0.0"
              )
            end.not_to raise_error
          end
        end

        it "uses the detected package manager in Rspack v2 fix instructions" do
          expect do
            validate_rsc_rspack_project(
              assets_bundler: "rspack",
              rspack_core_version: "^1.6.0",
              package_manager: "npm@10.0.0"
            )
          end.to raise_error(ReactOnRails::Error, %r{npm install --save-dev @rspack/core@\^2})
        end

        it "does not add undeclared Rspack companion packages to fix instructions" do
          expect do
            validate_rsc_rspack_project(
              assets_bundler: "rspack",
              rspack_core_version: "^1.6.0",
              package_manager: "npm@10.0.0"
            )
          end.to raise_error(ReactOnRails::Error) { |error|
            aggregate_failures do
              expect(error.message).to include("npm install --save-dev @rspack/core@^2")
              expect(error.message).not_to include("@rspack/cli")
            end
          }
        end

        it "warns and allows boot when only a companion Rspack package is declared" do
          stub_failed_node_package_resolution

          expect_rsc_rspack_boot_warning("not found") do
            expect do
              validate_rsc_rspack_project(
                assets_bundler: "rspack",
                rspack_core_version: nil,
                rspack_package_versions: { "@rspack/cli" => "^1.6.0" },
                package_manager: "npm@10.0.0"
              )
            end.not_to raise_error
          end
        end

        it "falls back to yarn instructions when package manager detection fails" do
          allow(ReactOnRails::Utils).to receive(:detect_package_manager).and_raise(RuntimeError, "unavailable")

          expect { validate_rsc_rspack_project(assets_bundler: "rspack", rspack_core_version: "^1.6.0") }
            .to raise_error(ReactOnRails::Error, %r{yarn add --dev @rspack/core@\^2})
        end

        it "warns and allows boot when active Rspack is missing @rspack/core" do
          expect_rsc_rspack_boot_warning("not found") do
            expect { validate_rsc_rspack_project(assets_bundler: "rspack", rspack_core_version: nil) }
              .not_to raise_error
          end
        end

        it "warns and allows boot when package.json cannot be reread for the RSC Rspack version" do
          expect_rsc_rspack_boot_warning("not found") do
            expect do
              validate_rsc_rspack_project(
                assets_bundler: "rspack",
                rspack_core_version: "^1.6.0",
                package_json_read_error_after_version_cache: true
              )
            end.not_to raise_error
          end
        end

        it "allows active Rspack v2" do
          expect { validate_rsc_rspack_project(assets_bundler: "rspack", rspack_core_version: "^2.0.0") }
            .not_to raise_error
        end

        it "does not shell out to Node when package.json statically proves active Rspack v2" do
          expect(Open3).not_to receive(:capture3)

          expect { validate_rsc_rspack_project(assets_bundler: "rspack", rspack_core_version: "^2.0.0") }
            .not_to raise_error
        end

        it "allows installed Rspack v2 when package.json does not declare @rspack/core" do
          expect do
            validate_rsc_rspack_project(
              assets_bundler: "rspack",
              rspack_core_version: nil,
              installed_rspack_core_version: "2.1.0"
            )
          end.not_to raise_error
        end

        it "allows Node-resolved Rspack v2 when the flat node_modules fallback is absent" do
          Dir.mktmpdir do |root|
            write_rsc_rspack_project_files(root, assets_bundler: "rspack", rspack_core_version: nil)
            resolved_package_json = File.join(root, "resolved-packages/@rspack/core/package.json")
            FileUtils.mkdir_p(File.dirname(resolved_package_json))
            File.write(
              resolved_package_json,
              JSON.generate("name" => "@rspack/core", "version" => "2.1.0")
            )
            stub_rsc_rspack_project(root, rsc_enabled: true)
            node_package_version = VersionChecker::NodePackageVersion.new(File.join(root, "package.json"))
            status = instance_double(Process::Status, success?: true)
            allow(Open3).to receive(:capture3)
              .and_return(["#{resolved_package_json}\n", "", status])

            expect { described_class.new(node_package_version).validate_version_and_package_compatibility! }
              .not_to raise_error
            expect(Open3).to have_received(:capture3).with(
              "node",
              "-e",
              ReactOnRails::RscRspackSupport::NODE_PACKAGE_RESOLUTION_SCRIPT,
              "@rspack/core",
              File.join(root, "node_modules"),
              chdir: root
            )
          end
        end

        it "uses the configured client package root to resolve installed Rspack" do
          Dir.mktmpdir do |root|
            write_rsc_rspack_project_files(root, assets_bundler: "rspack", rspack_core_version: "latest")
            client_rspack_package_json = File.join(root, "client/node_modules/@rspack/core/package.json")
            FileUtils.mkdir_p(File.dirname(client_rspack_package_json))
            File.write(
              client_rspack_package_json,
              JSON.generate("name" => "@rspack/core", "version" => "2.0.8")
            )
            stub_rsc_rspack_project(root, rsc_enabled: true, node_modules_location: "client")
            node_package_version = VersionChecker::NodePackageVersion.new(File.join(root, "package.json"))
            allow(Rails.logger).to receive(:warn)

            expect { described_class.new(node_package_version).validate_version_and_package_compatibility! }
              .not_to raise_error
            expect(Rails.logger).not_to have_received(:warn).with(
              a_string_including("Could not verify @rspack/core")
            )
          end
        end

        it "raises when installed Rspack is v1 even if package.json declares v2" do
          expect do
            validate_rsc_rspack_project(
              assets_bundler: "rspack",
              rspack_core_version: "^2.0.0",
              installed_rspack_core_version: "1.6.0"
            )
          end.to raise_error(ReactOnRails::Error, %r{Detected @rspack/core: 1\.6\.0})
        end

        it "allows @rspack/core v2 from optional dependencies" do
          expect do
            validate_rsc_rspack_project(
              assets_bundler: "rspack",
              rspack_core_version: "^2.0.0",
              dependency_field: "optionalDependencies"
            )
          end.not_to raise_error
        end

        it "allows @rspack/core v2 from a scoped npm alias" do
          expect do
            validate_rsc_rspack_project(
              assets_bundler: "rspack",
              rspack_core_version: "npm:@rspack/core@^2.0.0"
            )
          end.not_to raise_error
        end

        it "allows generated Rspack v2 prerelease lower-bound specs" do
          stub_failed_node_package_resolution

          expect do
            validate_rsc_rspack_project(
              assets_bundler: "rspack",
              rspack_core_version: "^2.0.0-0"
            )
          end.not_to raise_error
        end

        it "warns and allows boot for path protocol specs even when the path contains a v2-looking version" do
          expect_rsc_rspack_boot_warning("file:../rspack-2.0.0") do
            expect do
              validate_rsc_rspack_project(
                assets_bundler: "rspack",
                rspack_core_version: "file:../rspack-2.0.0"
              )
            end.not_to raise_error
          end
        end

        it "warns and allows boot for workspace protocol specs even when they contain a v2-looking version" do
          stub_failed_node_package_resolution

          expect_rsc_rspack_boot_warning("workspace:^2.0.0") do
            expect do
              validate_rsc_rspack_project(
                assets_bundler: "rspack",
                rspack_core_version: "workspace:^2.0.0"
              )
            end.not_to raise_error
          end
        end

        it "warns and allows boot when @rspack/core is only declared as a peer dependency" do
          expect_rsc_rspack_boot_warning("not found") do
            expect do
              validate_rsc_rspack_project(
                assets_bundler: "rspack",
                rspack_core_version: "^2.0.0",
                dependency_field: "peerDependencies"
              )
            end.not_to raise_error
          end
        end

        it "allows Rspack v1 when RSC is disabled" do
          expect do
            validate_rsc_rspack_project(assets_bundler: "rspack", rspack_core_version: "^1.6.0",
                                        rsc_enabled: false)
          end.not_to raise_error
        end

        it "allows Rspack v1 when webpack is active" do
          expect { validate_rsc_rspack_project(assets_bundler: "webpack", rspack_core_version: "^1.6.0") }
            .not_to raise_error
        end

        it "raises when Rspack is selected through SHAKAPACKER_ASSETS_BUNDLER" do
          expect do
            validate_rsc_rspack_project(
              assets_bundler: "webpack",
              rspack_core_version: "^1.6.0",
              env_assets_bundler: "rspack"
            )
          end.to raise_error(ReactOnRails::Error, /RSC with Rspack requires Rspack v2 or newer/)
        end

        it "does not read RSC support when webpack is active" do
          expect do
            validate_rsc_rspack_project(
              assets_bundler: "webpack",
              rspack_core_version: "^1.6.0",
              configuration_error: RuntimeError.new("Pro config unavailable")
            )
          end.not_to raise_error
        end

        it "fails clearly when active Rspack cannot read Pro RSC configuration" do
          expect do
            validate_rsc_rspack_project(
              assets_bundler: "rspack",
              rspack_core_version: "^1.6.0",
              configuration_error: RuntimeError.new("Pro config unavailable")
            )
          end.to raise_error(
            ReactOnRails::Error,
            /could not determine whether React Server Components are enabled/
          )
        end
      end

      context "when package.json file does not exist" do
        let(:node_package_version) do
          instance_double(VersionChecker::NodePackageVersion,
                          package_json: "/path/to/nonexistent/package.json")
        end

        it "raises an error" do
          # Mock Rails.root properly
          fake_root = File.dirname(node_package_version.package_json)
          fake_root_pathname = Pathname.new(fake_root)
          allow(Rails).to receive(:root).and_return(fake_root_pathname)

          # Override File.exist? to return false for all paths (including package.json)
          allow(File).to receive(:exist?).and_return(false)
          # Mock yarn.lock to exist so package manager detection works
          allow(File).to receive(:exist?).with(File.join(fake_root, "yarn.lock")).and_return(true)

          allow(ReactOnRails).to receive_message_chain(:configuration, :node_modules_location).and_return("")

          version_checker = described_class.new(node_package_version)
          expect { version_checker.validate_version_and_package_compatibility! }
            .to raise_error(ReactOnRails::Error, /package\.json file not found/)
        end
      end
    end

    def double_package_version(raw: nil, semver_wildcard: false,
                               parts: nil, local_path_or_url: false)
      instance_double(VersionChecker::NodePackageVersion,
                      raw:,
                      semver_wildcard?: semver_wildcard,
                      parts:,
                      local_path_or_url?: local_path_or_url,
                      package_json: "/fake/path/package.json")
    end

    # rubocop:disable Metrics/AbcSize
    def check_version_and_raise(node_package_version)
      # Mock Rails.root to return a proper path string
      fake_root = File.dirname(node_package_version.package_json)
      fake_root_pathname = Pathname.new(fake_root)
      allow(Rails).to receive(:root).and_return(fake_root_pathname)

      # Stub File.exist? for the package.json and lock files
      # We mock specific paths and return false for everything else
      allow(File).to receive(:exist?).and_return(false)
      allow(File).to receive(:exist?).with(node_package_version.package_json).and_return(true)
      # Mock lock files - use yarn.lock so package manager detection returns :yarn
      allow(File).to receive(:exist?).with(File.join(fake_root, "yarn.lock")).and_return(true)

      # Stub ReactOnRails.configuration.node_modules_location
      allow(ReactOnRails).to receive_message_chain(:configuration, :node_modules_location).and_return("")
      version_checker = VersionChecker.new(node_package_version)
      version_checker.validate_version_and_package_compatibility!
    end
    # rubocop:enable Metrics/AbcSize

    describe VersionChecker::NodePackageVersion do
      subject(:node_package_version) { described_class.new(package_json) }

      describe "#build" do
        it "initializes NodePackageVersion with ReactOnRails.configuration.node_modules_location" do
          allow(ReactOnRails).to receive_message_chain(:configuration, :node_modules_location).and_return("spec/dummy")
          # Use a fixture that has dependencies but not react-on-rails packages
          test_package_json = File.expand_path("fixtures/beta_package.json", __dir__)
          allow(Rails).to receive_message_chain(:root, :join).and_return(test_package_json)

          # beta_package.json has react-on-rails, so it should not warn
          allow(Rails.logger).to receive(:warn)
          result = described_class.build.raw
          expect(result).to eq("^14.0.0.beta-2")
        end
      end

      describe "#semver_wildcard?" do
        context "when package json lists an exact version of '0.0.2'" do
          let(:package_json) { File.expand_path("fixtures/normal_package.json", __dir__) }

          specify { expect(node_package_version.semver_wildcard?).to be false }
        end

        context "when package json lists a semver caret version of '^1.2.3'" do
          let(:package_json) { File.expand_path("fixtures/semver_caret_package.json", __dir__) }

          specify { expect(node_package_version.semver_wildcard?).to be true }
        end

        context "when package json lists a semver tilde version of '~1.2.3'" do
          let(:package_json) { File.expand_path("fixtures/semver_tilde_package.json", __dir__) }

          specify { expect(node_package_version.semver_wildcard?).to be true }
        end

        context "when package json lists a version range of '>=1.2.3 <2.0.0'" do
          let(:package_json) { File.expand_path("fixtures/semver_range_package.json", __dir__) }

          specify { expect(node_package_version.semver_wildcard?).to be true }
        end
      end

      context "when package json lists a version of '0.0.2'" do
        let(:package_json) { File.expand_path("fixtures/normal_package.json", __dir__) }

        describe "#raw" do
          specify { expect(node_package_version.raw).to eq("0.0.2") }
        end

        describe "#local_path_or_url?" do
          specify { expect(node_package_version.local_path_or_url?).to be false }
        end

        describe "#parts" do
          specify { expect(node_package_version.parts).to eq(%w[0 0 2]) }
        end
      end

      context "when package json lists a version of '^14.0.0.beta-2'" do
        let(:package_json) { File.expand_path("fixtures/beta_package.json", __dir__) }

        describe "#raw" do
          specify { expect(node_package_version.raw).to eq("^14.0.0.beta-2") }
        end

        describe "#local_path_or_url?" do
          specify { expect(node_package_version.local_path_or_url?).to be false }
        end

        describe "#parts" do
          specify { expect(node_package_version.parts).to eq(%w[14 0 0 beta-2]) }
        end
      end

      context "with node version of '../../..'" do
        let(:package_json) { File.expand_path("fixtures/relative_path_package.json", __dir__) }

        describe "#raw" do
          specify { expect(node_package_version.raw).to eq("../../..") }
        end

        describe "#local_path_or_url?" do
          specify { expect(node_package_version.local_path_or_url?).to be true }
        end

        describe "#parts" do
          specify { expect(node_package_version.parts).to be_nil }
        end
      end

      context "with node version of 'file:///Users/justin/shakacode/react_on_rails'" do
        let(:package_json) { File.expand_path("fixtures/absolute_path_package.json", __dir__) }

        describe "#raw" do
          specify { expect(node_package_version.raw).to eq("file:///Users/justin/shakacode/react_on_rails") }
        end

        describe "#local_path_or_url?" do
          specify { expect(node_package_version.local_path_or_url?).to be true }
        end

        describe "#parts" do
          specify { expect(node_package_version.parts).to be_nil }
        end
      end

      context "with node version of 'file:.yalc/react-on-rails'" do
        let(:package_json) { File.expand_path("fixtures/yalc_package.json", __dir__) }

        describe "#raw" do
          specify { expect(node_package_version.raw).to eq("file:.yalc/react-on-rails") }
        end

        describe "#local_path_or_url?" do
          specify { expect(node_package_version.local_path_or_url?).to be true }
        end

        describe "#parts" do
          specify { expect(node_package_version.parts).to be_nil }
        end
      end

      context "with node version of `git:` URL" do
        let(:package_json) { File.expand_path("fixtures/git_package.json", __dir__) }

        describe "#raw" do
          specify { expect(node_package_version.raw).to eq("git://github.com/shakacode/react-on-rails.git") }
        end

        describe "#local_path_or_url?" do
          specify { expect(node_package_version.local_path_or_url?).to be true }
        end

        describe "#parts" do
          specify { expect(node_package_version.parts).to be_nil }
        end
      end

      context "with pnpm workspace protocol 'workspace:*'" do
        let(:package_json) { File.expand_path("fixtures/workspace_protocol_package.json", __dir__) }

        describe "#raw" do
          specify { expect(node_package_version.raw).to eq("workspace:*") }
        end

        describe "#local_path_or_url?" do
          specify { expect(node_package_version.local_path_or_url?).to be false }
        end

        describe "#workspace_protocol?" do
          specify { expect(node_package_version.workspace_protocol?).to be true }
        end

        describe "#parts" do
          specify { expect(node_package_version.parts).to be_nil }
        end
      end

      context "with pnpm workspace protocol 'workspace:^'" do
        let(:package_json) { File.expand_path("fixtures/workspace_caret_package.json", __dir__) }

        describe "#raw" do
          specify { expect(node_package_version.raw).to eq("workspace:^") }
        end

        describe "#local_path_or_url?" do
          specify { expect(node_package_version.local_path_or_url?).to be false }
        end

        describe "#workspace_protocol?" do
          specify { expect(node_package_version.workspace_protocol?).to be true }
        end

        describe "#parts" do
          specify { expect(node_package_version.parts).to be_nil }
        end
      end

      context "with package.json without react-on-rails dependency" do
        let(:package_json) { File.expand_path("../../package.json", __dir__) }

        describe "#raw" do
          it "returns nil" do
            root_package_json_path = File.expand_path("fixtures/nonexistent_package.json", __dir__)
            allow(Rails).to receive_message_chain(:root, :join).and_return(root_package_json_path)
            expect(node_package_version.raw).to be_nil
          end
        end
      end

      context "with non-existing package.json" do
        let(:package_json) { File.expand_path("fixtures/nonexistent_package.json", __dir__) }

        describe "#raw" do
          it "returns nil" do
            root_package_json_path = File.expand_path("fixtures/nonexistent_package.json", __dir__)
            allow(Rails).to receive_message_chain(:root, :join).and_return(root_package_json_path)
            expect(node_package_version.raw).to be_nil
          end
        end
      end

      describe "Lockfile version resolution" do
        # Each fixtures/lockfiles/<dir> holds a package.json plus lockfiles under their real
        # filenames; yarn.lock/package-lock.json paths are injected as the checker does itself.
        def node_package_version_in(fixture_dir)
          base = File.expand_path("fixtures/lockfiles/#{fixture_dir}", __dir__)
          described_class.new(File.join(base, "package.json"),
                              File.join(base, "yarn.lock"),
                              File.join(base, "package-lock.json"))
        end

        context "with similar package names in yarn.lock" do
          it "returns the version for react-on-rails-pro, not react-on-rails" do
            expect(node_package_version_in("yarn_classic_similar_packages").raw).to eq("16.1.1")
          end
        end

        context "with the pro package's caret spec and a yarn.lock" do
          it "returns the exact version from yarn.lock" do
            expect(node_package_version_in("yarn_classic_pro").raw).to eq("16.1.1")
          end
        end

        context "with the pro package's caret spec and a package-lock.json" do
          it "returns the exact version from package-lock.json" do
            expect(node_package_version_in("npm_pro").raw).to eq("16.1.1")
          end
        end

        context "with an exact version in package.json and a matching yarn.lock" do
          it "returns the exact version from yarn.lock" do
            expect(node_package_version_in("yarn_classic_exact").raw).to eq("16.1.1")
          end
        end

        context "with a semver caret but no lockfile at all" do
          it "falls back to the package.json version" do
            expect(node_package_version_in("no_lockfile").raw).to eq("^1.2.3")
          end
        end

        context "with a malformed yarn.lock" do
          it "falls back to the package.json version" do
            expect(node_package_version_in("yarn_classic_malformed").raw).to eq("^1.2.3")
          end
        end

        context "with a malformed package-lock.json" do
          it "falls back to the package.json version" do
            expect(node_package_version_in("npm_malformed").raw).to eq("^1.2.3")
          end
        end
      end

      describe "Lockfile version resolution across package managers" do
        # Fixture directories under fixtures/lockfiles/ hold REAL lockfiles generated by the
        # actual package managers against react-on-rails@^16.1.1 (resolved: 16.6.0), using real
        # filenames. yarn.lock/package-lock.json go through the long-standing injected-path
        # parsers; pnpm-lock.yaml and bun.lock are found next to package.json.
        def node_package_version_for(fixture_dir)
          base = File.expand_path("fixtures/lockfiles/#{fixture_dir}", __dir__)
          described_class.new(File.join(base, "package.json"),
                              File.join(base, "yarn.lock"),
                              File.join(base, "package-lock.json"))
        end

        {
          "yarn_classic" => "Yarn classic yarn.lock",
          "yarn_berry_v4" => "Yarn Berry yarn.lock (__metadata version 4, yarn 2)",
          "yarn_berry_v8" => "Yarn Berry yarn.lock (__metadata version 8, yarn 4)",
          "npm_v1" => "package-lock.json lockfileVersion 1 (npm 5-6)",
          "npm_v2" => "package-lock.json lockfileVersion 2 (npm 7-8)",
          "npm_v3" => "package-lock.json lockfileVersion 3 (npm 9+)",
          "pnpm_v5" => "pnpm-lock.yaml lockfileVersion 5.4 (pnpm 7)",
          "pnpm_v6" => "pnpm-lock.yaml lockfileVersion 6.0 (pnpm 8)",
          "pnpm_v9" => "pnpm-lock.yaml lockfileVersion 9.0 (pnpm 9/10)",
          "pnpm_v11_multidoc" => "pnpm 11 multi-document pnpm-lock.yaml",
          "pnpm_v9_time_field" => "pnpm-lock.yaml with unquoted time: timestamps",
          "bun_v1" => "bun.lock text lockfile (lockfileVersion 1, JSONC)",
          "bun_v2_real" => "real bun 1.4 bun.lock (lockfileVersion 2)"
        }.each do |fixture, description|
          context "with a #{description} and a caret spec" do
            it "returns the installed version from the lockfile" do
              expect(node_package_version_for(fixture).raw).to eq("16.6.0")
            end
          end
        end

        # The relaxed rule from #1898: the INSTALLED version is what gets checked, so a lockfile
        # entry still resolves by package name even after package.json's range was edited.
        %w[yarn_classic_stale_selector yarn_berry_v8_stale_selector pnpm_v9_stale_selector].each do |fixture|
          context "when package.json's range changed after install (#{fixture})" do
            it "still resolves the installed version recorded in the lockfile" do
              expect(node_package_version_for(fixture).raw).to eq("16.6.0")
            end
          end
        end

        context "when lockfiles from several package managers exist" do
          it "prefers yarn.lock, matching the long-standing precedence" do
            expect(node_package_version_for("ambiguous_yarn_npm").raw).to eq("16.5.0")
          end
        end

        context "with a Yarn Berry workspace: protocol dependency" do
          it "keeps the workspace spec so the version validators exempt it" do
            expect(node_package_version_for("yarn_berry_workspace").raw).to eq("workspace:^")
          end
        end

        context "with the same caret spec across every package manager" do
          it "resolves the identical installed version from every lockfile format" do
            versions = %w[yarn_classic yarn_berry_v4 yarn_berry_v8 npm_v1 npm_v2 npm_v3
                          pnpm_v5 pnpm_v6 pnpm_v9 pnpm_v11_multidoc bun_v1 bun_v2_real].to_h do |fixture|
              [fixture, node_package_version_for(fixture).raw]
            end
            expect(versions.values).to all(eq("16.6.0")), versions.inspect
          end
        end

        describe "bun JSONC sanitizing" do
          it "strips comments and trailing commas without ever altering string contents" do
            content = <<~JSONC
              {
                // line comment
                "tricky": ["x,]", "y, }", "// not a comment", "a /* not */ comment"],
                "packages": {
                  "p": ["p@1.0.0", "", {}, "sha512-abc"],
                },
              }
            JSONC
            sanitized = VersionChecker::LockfileResolution::BunLockfile.jsonc_to_json(content)
            parsed = JSON.parse(sanitized)
            expect(parsed["tricky"]).to eq(["x,]", "y, }", "// not a comment", "a /* not */ comment"])
            expect(parsed["packages"]["p"].first).to eq("p@1.0.0")
          end
        end
      end

      describe "Pro package detection" do
        context "with react-on-rails package" do
          let(:package_json) { File.expand_path("fixtures/normal_package.json", __dir__) }

          describe "#react_on_rails_package?" do
            specify { expect(node_package_version.react_on_rails_package?).to be true }
          end

          describe "#react_on_rails_pro_package?" do
            specify { expect(node_package_version.react_on_rails_pro_package?).to be false }
          end

          describe "#package_name" do
            specify { expect(node_package_version.package_name).to eq("react-on-rails") }
          end

          describe "#raw" do
            specify { expect(node_package_version.raw).to eq("0.0.2") }
          end
        end

        context "with react-on-rails-pro package" do
          let(:package_json) { File.expand_path("fixtures/pro_package.json", __dir__) }

          describe "#react_on_rails_package?" do
            specify { expect(node_package_version.react_on_rails_package?).to be false }
          end

          describe "#react_on_rails_pro_package?" do
            specify { expect(node_package_version.react_on_rails_pro_package?).to be true }
          end

          describe "#package_name" do
            specify { expect(node_package_version.package_name).to eq("react-on-rails-pro") }
          end

          describe "#raw" do
            specify { expect(node_package_version.raw).to eq("16.1.1") }
          end
        end

        context "with both packages" do
          let(:package_json) { File.expand_path("fixtures/both_packages.json", __dir__) }

          describe "#react_on_rails_package?" do
            specify { expect(node_package_version.react_on_rails_package?).to be true }
          end

          describe "#react_on_rails_pro_package?" do
            specify { expect(node_package_version.react_on_rails_pro_package?).to be true }
          end

          describe "#package_name" do
            it "prefers Pro package name" do
              expect(node_package_version.package_name).to eq("react-on-rails-pro")
            end
          end

          describe "#raw" do
            it "returns Pro package version (takes precedence)" do
              expect(node_package_version.raw).to eq("16.1.1")
            end
          end
        end

        context "with Pro package using semver caret" do
          let(:package_json) { File.expand_path("fixtures/pro_semver_caret_package.json", __dir__) }

          describe "#react_on_rails_pro_package?" do
            specify { expect(node_package_version.react_on_rails_pro_package?).to be true }
          end

          describe "#package_name" do
            specify { expect(node_package_version.package_name).to eq("react-on-rails-pro") }
          end

          describe "#raw" do
            specify { expect(node_package_version.raw).to eq("^16.1.1") }
          end

          describe "#semver_wildcard?" do
            specify { expect(node_package_version.semver_wildcard?).to be true }
          end
        end

        context "with package.json without any react-on-rails packages" do
          let(:package_json) { File.expand_path("../../package.json", __dir__) }

          describe "#react_on_rails_package?" do
            specify { expect(node_package_version.react_on_rails_package?).to be false }
          end

          describe "#react_on_rails_pro_package?" do
            specify { expect(node_package_version.react_on_rails_pro_package?).to be false }
          end

          describe "#package_name" do
            it "defaults to react-on-rails" do
              expect(node_package_version.package_name).to eq("react-on-rails")
            end
          end
        end
      end
    end
  end
end

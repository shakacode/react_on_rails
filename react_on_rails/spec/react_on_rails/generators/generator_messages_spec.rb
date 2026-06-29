# frozen_string_literal: true

require "tmpdir"

require_relative "../support/generator_spec_helper"

describe GeneratorMessages do
  it "has an empty messages array" do
    expect(described_class.messages).to be_empty
  end

  it "has a method that can add errors" do
    described_class.add_error "Test error"
    expect(described_class.messages)
      .to contain_exactly(described_class.format_error("Test error"))
  end

  it "has a method that can add warnings" do
    described_class.add_warning "Test warning"
    expect(described_class.messages)
      .to contain_exactly(described_class.format_warning("Test warning"))
  end

  it "has a method that can add info messages" do
    described_class.add_info "Test info message"
    expect(described_class.messages)
      .to contain_exactly(described_class.format_info("Test info message"))
  end

  it "shows stream_react_component in RSC install message" do
    message = described_class.helpful_message_after_installation(
      component_name: "HelloServer",
      route: "hello_server",
      rsc: true
    )

    expect(message).to include("stream_react_component")
    expect(message).to include('stream_react_component("HelloServer", props: @hello_server_props)')
    expect(message).not_to include("prerender: true")
    expect(message).not_to include('react_component("HelloServer", props: @hello_server_props, prerender: true)')
  end

  it "shows react_component in non-RSC install message" do
    message = described_class.helpful_message_after_installation(
      component_name: "HelloWorld",
      route: "hello_world",
      rsc: false
    )

    expect(message).to include("bin/rails db:prepare")
    expect(message).to include('react_component("HelloWorld", props: @hello_world_props, prerender: true)')
  end

  it "shows layout-owned Tailwind pack tags in Tailwind install messages" do
    message = described_class.helpful_message_after_installation(
      component_name: "HelloWorld",
      route: "hello_world",
      tailwind: true
    )

    expect(message).to include('prepend_javascript_pack_tag "react_on_rails_tailwind"')
    expect(message).to include('stylesheet_pack_tag "react_on_rails_tailwind", media: "all"')
    expect(message).to include("<%= javascript_pack_tag %>")
  end

  it "keeps empty pack tag guidance for non-Tailwind install messages" do
    message = described_class.helpful_message_after_installation(
      component_name: "HelloWorld",
      route: "hello_world"
    )

    expect(message).to include("Your layout only needs")
    expect(message).to include("<%= javascript_pack_tag %>")
    expect(message).to include("<%= stylesheet_pack_tag %>")
    expect(message).not_to include("react_on_rails_tailwind")
  end

  it "points fresh-app installs at the landing page" do
    message = described_class.helpful_message_after_installation(
      component_name: "HelloWorld",
      route: "hello_world",
      landing_page: true
    )

    expect(message).to include("http://localhost:3000")
    expect(message).not_to include("http://localhost:3000/hello_world")
    expect(message).to include("Home page includes links to the generated example pages.")
  end

  it "shows Pro upgrade hint for standard (non-Pro) install" do
    message = described_class.helpful_message_after_installation(
      component_name: "HelloWorld",
      route: "hello_world",
      pro: false,
      rsc: false
    )

    expect(message).to include("React on Rails Pro")
    expect(message).to include("https://reactonrails.com/docs/pro/upgrading-to-pro/")
  end

  it "does not show Pro upgrade hint when --pro is used" do
    message = described_class.helpful_message_after_installation(
      component_name: "HelloWorld",
      route: "hello_world",
      pro: true,
      rsc: false
    )

    expect(message).not_to include("React on Rails Pro")
  end

  it "does not show Pro upgrade hint when --rsc is used" do
    message = described_class.helpful_message_after_installation(
      component_name: "HelloServer",
      route: "hello_server",
      pro: false,
      rsc: true
    )

    expect(message).not_to include("React on Rails Pro")
  end

  it "does not re-read a missing package.json when building the CI section" do
    Dir.mktmpdir do |app_root|
      expect(described_class).to receive(:read_package_json).with(app_root).once.and_call_original

      # Calls the private build_ci_section directly to isolate the read-once invariant;
      # going through the public `helpful_message_after_installation` path would mix in
      # other helpers' reads and obscure which call site reopens package.json.
      message = described_class.send(:build_ci_section, app_root:, ci_workflow_generated: true)

      expect(message).to include("CI / BUILD ORDERING")
    end
  end

  it "uses the generated Shakapacker precompile hook in the manual CI build command" do
    Dir.mktmpdir do |app_root|
      FileUtils.mkdir_p(File.join(app_root, "config"))
      File.write(File.join(app_root, "config/shakapacker.yml"), <<~YAML)
        default: &default
          precompile_hook: 'bin/shakapacker-precompile-hook'

        test:
          <<: *default
      YAML

      message = described_class.send(:build_ci_section, app_root:, ci_workflow_generated: true)

      expect(message).to include(
        "RAILS_ENV=test NODE_ENV=test bin/shakapacker-precompile-hook && " \
        "SHAKAPACKER_SKIP_PRECOMPILE_HOOK=true RAILS_ENV=test NODE_ENV=test bin/shakapacker"
      )
    end
  end

  it "leaves custom Shakapacker precompile hooks under Shakapacker control" do
    Dir.mktmpdir do |app_root|
      FileUtils.mkdir_p(File.join(app_root, "config"))
      File.write(File.join(app_root, "config/shakapacker.yml"), <<~YAML)
        default: &default
          precompile_hook: 'bundle exec rake react_on_rails:locale'

        test:
          <<: *default
          precompile_hook: 'bundle exec rake react_on_rails:test_locale'
      YAML

      message = described_class.send(:build_ci_section, app_root:, ci_workflow_generated: true)

      expect(message).to include("RAILS_ENV=test NODE_ENV=test bin/shakapacker")
      expect(message).not_to include("react_on_rails:test_locale")
      expect(message).not_to include("SHAKAPACKER_SKIP_PRECOMPILE_HOOK")
    end
  end

  it "does not inherit default precompile_hook when the Shakapacker environment does not merge it" do
    Dir.mktmpdir do |app_root|
      FileUtils.mkdir_p(File.join(app_root, "config"))
      File.write(File.join(app_root, "config/shakapacker.yml"), <<~YAML)
        default: &default
          precompile_hook: 'bin/shakapacker-precompile-hook'

        test:
          compile: true
      YAML

      message = described_class.send(:build_ci_section, app_root:, ci_workflow_generated: true)

      expect(message).to include("RAILS_ENV=test NODE_ENV=test bin/shakapacker")
      expect(message).not_to include("bin/shakapacker-precompile-hook")
      expect(message).not_to include("SHAKAPACKER_SKIP_PRECOMPILE_HOOK")
    end
  end

  it "does not assume a commented generated hook placeholder applies to test when test does not merge defaults" do
    Dir.mktmpdir do |app_root|
      FileUtils.mkdir_p(File.join(app_root, "config"))
      File.write(File.join(app_root, "config/shakapacker.yml"), <<~YAML)
        default: &default
          # precompile_hook: ~

        test:
          compile: true
      YAML

      message = described_class.send(:build_ci_section, app_root:, ci_workflow_generated: true)

      expect(message).to include("RAILS_ENV=test NODE_ENV=test bin/shakapacker")
      expect(message).not_to include("bin/shakapacker-precompile-hook")
      expect(message).not_to include("SHAKAPACKER_SKIP_PRECOMPILE_HOOK")
    end
  end

  it "uses the generated hook placeholder in the manual CI build command when test merges defaults" do
    Dir.mktmpdir do |app_root|
      FileUtils.mkdir_p(File.join(app_root, "config"))
      File.write(File.join(app_root, "config/shakapacker.yml"), <<~YAML)
        default: &default
          # precompile_hook: ~

        test:
          <<: *default
          compile: true
      YAML

      message = described_class.send(:build_ci_section, app_root:, ci_workflow_generated: true)

      expect(message).to include(
        "RAILS_ENV=test NODE_ENV=test bin/shakapacker-precompile-hook && " \
        "SHAKAPACKER_SKIP_PRECOMPILE_HOOK=true RAILS_ENV=test NODE_ENV=test bin/shakapacker"
      )
    end
  end

  describe ".detect_package_manager" do
    include_context "with clean REACT_ON_RAILS_PACKAGE_MANAGER env"

    it "returns bun when bun.lock exists" do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "package.json")).and_return(false)
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "yarn.lock")).and_return(false)
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "pnpm-lock.yaml")).and_return(false)
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "bun.lock")).and_return(true)

      expect(described_class.detect_package_manager).to eq("bun")
    end

    it "prefers the packageManager field in package.json over lockfile fallback" do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "package.json")).and_return(true)
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(File.join(Dir.pwd, "package.json"))
                                   .and_return('{"packageManager": "pnpm@8.0.0"}')

      expect(described_class.detect_package_manager).to eq("pnpm")
    end

    it "picks packageManager field when no lockfile is present (first-run state)" do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "package.json")).and_return(true)
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "yarn.lock")).and_return(false)
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "pnpm-lock.yaml")).and_return(false)
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "bun.lock")).and_return(false)
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "bun.lockb")).and_return(false)
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "package-lock.json")).and_return(false)
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(File.join(Dir.pwd, "package.json"))
                                   .and_return('{"packageManager": "yarn@3.6.0"}')

      expect(described_class.detect_package_manager).to eq("yarn")
    end

    it "detects a bare packageManager name even when it has no Corepack version" do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "package.json")).and_return(true)
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "yarn.lock")).and_return(false)
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "pnpm-lock.yaml")).and_return(false)
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "bun.lock")).and_return(false)
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "bun.lockb")).and_return(false)
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "package-lock.json")).and_return(false)
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(File.join(Dir.pwd, "package.json"))
                                   .and_return('{"packageManager": "pnpm"}')

      expect(described_class.detect_package_manager).to eq("pnpm")
    end

    it "ignores an unsupported packageManager value and falls through to lockfiles" do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "package.json")).and_return(true)
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "yarn.lock")).and_return(true)
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(File.join(Dir.pwd, "package.json"))
                                   .and_return('{"packageManager": "unknown@1.0.0"}')

      expect(described_class.detect_package_manager).to eq("yarn")
    end

    it "treats package_json: nil as a cached missing package.json and falls through to lockfiles" do
      expect(described_class).not_to receive(:read_package_json)
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "package.json")).and_return(true)
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "yarn.lock")).and_return(true)

      expect(described_class.detect_package_manager(package_json: nil)).to eq("yarn")
    end

    it "returns nil from detect_package_manager_from_package_json for malformed JSON" do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "package.json")).and_return(true)
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(File.join(Dir.pwd, "package.json"))
                                   .and_return("not-json")

      expect(described_class.send(:detect_package_manager_from_package_json)).to be_nil
    end

    it "returns bun when bun.lockb exists" do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "package.json")).and_return(false)
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "yarn.lock")).and_return(false)
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "pnpm-lock.yaml")).and_return(false)
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "bun.lock")).and_return(false)
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "bun.lockb")).and_return(true)

      expect(described_class.detect_package_manager).to eq("bun")
    end

    it "returns npm when package-lock.json exists" do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "package.json")).and_return(false)
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "yarn.lock")).and_return(false)
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "pnpm-lock.yaml")).and_return(false)
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "bun.lock")).and_return(false)
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "bun.lockb")).and_return(false)
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "package-lock.json")).and_return(true)

      expect(described_class.detect_package_manager).to eq("npm")
    end
  end

  describe ".detect_package_manager_with_source" do
    include_context "with clean REACT_ON_RAILS_PACKAGE_MANAGER env"

    it "returns :env when REACT_ON_RAILS_PACKAGE_MANAGER is set to a supported value" do
      ENV["REACT_ON_RAILS_PACKAGE_MANAGER"] = "pnpm"
      expect(described_class.detect_package_manager_with_source).to eq(["pnpm", :env])
    end

    it "falls through to lockfile detection when REACT_ON_RAILS_PACKAGE_MANAGER is unsupported" do
      ENV["REACT_ON_RAILS_PACKAGE_MANAGER"] = "unknown"
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "package.json")).and_return(false)
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "yarn.lock")).and_return(true)

      expect(described_class.detect_package_manager_with_source).to eq(["yarn", :lockfile])
    end

    it "returns :package_json when packageManager field is present and env is not set" do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "package.json")).and_return(true)
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(File.join(Dir.pwd, "package.json"))
                                   .and_return('{"packageManager": "yarn@3.6.0"}')

      expect(described_class.detect_package_manager_with_source).to eq(["yarn", :package_json])
    end

    it "returns :lockfile when only a lockfile picks the manager" do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "package.json")).and_return(false)
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "yarn.lock")).and_return(false)
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "pnpm-lock.yaml")).and_return(true)

      expect(described_class.detect_package_manager_with_source).to eq(["pnpm", :lockfile])
    end

    it "returns :default when nothing else picks a manager" do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "package.json")).and_return(false)
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "yarn.lock")).and_return(false)
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "pnpm-lock.yaml")).and_return(false)
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "bun.lock")).and_return(false)
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "bun.lockb")).and_return(false)
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "package-lock.json")).and_return(false)

      expect(described_class.detect_package_manager_with_source).to eq(["npm", :default])
    end
  end

  describe ".supported_package_manager?" do
    it "returns true for supported managers and false otherwise" do
      expect(described_class.supported_package_manager?("npm")).to be(true)
      expect(described_class.supported_package_manager?("yarn")).to be(true)
      expect(described_class.supported_package_manager?("pnpm")).to be(true)
      expect(described_class.supported_package_manager?("bun")).to be(true)
      expect(described_class.supported_package_manager?("foo")).to be(false)
    end
  end

  describe ".package_manager_executable_available?" do
    it "returns false for unsupported package managers without checking PATH" do
      expect(ReactOnRails::Utils).not_to receive(:command_available?)

      expect(described_class.package_manager_executable_available?("foo")).to be(false)
    end

    it "delegates to ReactOnRails::Utils.command_available? for supported package managers" do
      allow(ReactOnRails::Utils).to receive(:command_available?).with("pnpm").and_return(true)

      expect(described_class.package_manager_executable_available?("pnpm")).to be(true)
    end
  end

  describe ".lockfile_filename_for" do
    let(:app_root) { Dir.mktmpdir }

    after { FileUtils.rm_rf(app_root) }

    it "returns the lockfile filename when the file exists" do
      {
        "yarn" => "yarn.lock",
        "pnpm" => "pnpm-lock.yaml",
        "npm" => "package-lock.json"
      }.each do |pm, lockfile|
        FileUtils.touch(File.join(app_root, lockfile))
        expect(described_class.lockfile_filename_for(pm, app_root:)).to eq(lockfile)
        File.delete(File.join(app_root, lockfile))
      end
    end

    it "returns nil when the lockfile is not on disk for yarn/pnpm/npm" do
      %w[yarn pnpm npm].each do |pm|
        expect(described_class.lockfile_filename_for(pm, app_root:)).to be_nil
      end
    end

    it "resolves bun.lock when only bun.lock exists" do
      FileUtils.touch(File.join(app_root, "bun.lock"))
      expect(described_class.lockfile_filename_for("bun", app_root:)).to eq("bun.lock")
    end

    it "resolves bun.lockb when only bun.lockb exists" do
      FileUtils.touch(File.join(app_root, "bun.lockb"))
      expect(described_class.lockfile_filename_for("bun", app_root:)).to eq("bun.lockb")
    end

    it "returns nil for bun when neither bun.lock nor bun.lockb is on disk" do
      expect(described_class.lockfile_filename_for("bun", app_root:)).to be_nil
    end

    it "returns nil for an unsupported package manager" do
      expect(described_class.lockfile_filename_for("foo", app_root:)).to be_nil
    end
  end

  describe ".lockfile_for_manager?" do
    # Scopes "has a lockfile" to the detected package manager so the CI scaffold
    # doesn't emit `cache: "pnpm"` with only yarn.lock on disk (cursor[bot] #3104333056)
    # and picks the right non-frozen install flag when the declared manager lacks its
    # lockfile on first CI run (codex[bot] #3104330951).
    let(:app_root) { Dir.pwd }

    before { allow(File).to receive(:exist?).and_call_original }

    it "returns true only when yarn.lock exists for yarn" do
      allow(File).to receive(:exist?).with(File.join(app_root, "yarn.lock")).and_return(true)
      expect(described_class.lockfile_for_manager?("yarn")).to be(true)

      allow(File).to receive(:exist?).with(File.join(app_root, "yarn.lock")).and_return(false)
      expect(described_class.lockfile_for_manager?("yarn")).to be(false)
    end

    it "returns true only when pnpm-lock.yaml exists for pnpm" do
      allow(File).to receive(:exist?).with(File.join(app_root, "pnpm-lock.yaml")).and_return(true)
      expect(described_class.lockfile_for_manager?("pnpm")).to be(true)

      allow(File).to receive(:exist?).with(File.join(app_root, "pnpm-lock.yaml")).and_return(false)
      expect(described_class.lockfile_for_manager?("pnpm")).to be(false)
    end

    it "accepts either bun.lock or bun.lockb for bun" do
      allow(File).to receive(:exist?).with(File.join(app_root, "bun.lock")).and_return(false)
      allow(File).to receive(:exist?).with(File.join(app_root, "bun.lockb")).and_return(true)
      expect(described_class.lockfile_for_manager?("bun")).to be(true)

      allow(File).to receive(:exist?).with(File.join(app_root, "bun.lockb")).and_return(false)
      allow(File).to receive(:exist?).with(File.join(app_root, "bun.lock")).and_return(true)
      expect(described_class.lockfile_for_manager?("bun")).to be(true)
    end

    it "returns false when the declared manager's lockfile is missing even if another exists" do
      # packageManager: "pnpm" but only yarn.lock on disk → pnpm lockfile is still absent.
      allow(File).to receive(:exist?).with(File.join(app_root, "yarn.lock")).and_return(true)
      allow(File).to receive(:exist?).with(File.join(app_root, "pnpm-lock.yaml")).and_return(false)
      expect(described_class.lockfile_for_manager?("pnpm")).to be(false)
    end

    it "returns false for unknown package managers" do
      expect(described_class.lockfile_for_manager?("unknown")).to be(false)
      expect(described_class.lockfile_for_manager?(nil)).to be(false)
    end
  end

  describe ".package_manager_declared?" do
    # Drives the "pin pnpm version in CI scaffold" fix (#3172): the template
    # only injects `with: version:` when the field is missing and the pnpm
    # action would otherwise fail on setup.
    let(:app_root) { Dir.pwd }
    let(:package_json_path) { File.join(app_root, "package.json") }

    before { allow(File).to receive(:exist?).and_call_original }

    it "requires callers to specify which package manager they need declared" do
      expect { described_class.package_manager_declared? }.to raise_error(ArgumentError, /manager/)
    end

    it "returns true when package.json declares the requested packageManager" do
      allow(File).to receive(:exist?).with(package_json_path).and_return(true)
      allow(File).to receive(:read).with(package_json_path)
                                   .and_return('{"packageManager":"pnpm@9.0.0"}')
      expect(described_class.package_manager_declared?(manager: "pnpm")).to be(true)
    end

    it "returns true when packageManager includes a Corepack hash annotation" do
      allow(File).to receive(:exist?).with(package_json_path).and_return(true)
      allow(File).to receive(:read).with(package_json_path)
                                   .and_return('{"packageManager":"pnpm@9.0.0+sha256.abc123"}')
      expect(described_class.package_manager_declared?(manager: "pnpm")).to be(true)
    end

    it "returns true when packageManager includes a SemVer prerelease" do
      expect(
        described_class.package_manager_declared?(
          manager: "pnpm",
          package_json: { "packageManager" => "pnpm@11.0.0-alpha.1" }
        )
      ).to be(true)
    end

    it "returns false when packageManager is absent" do
      allow(File).to receive(:exist?).with(package_json_path).and_return(true)
      allow(File).to receive(:read).with(package_json_path).and_return('{"name":"app"}')
      expect(described_class.package_manager_declared?(manager: "pnpm")).to be(false)
    end

    it "returns false when package.json is missing" do
      allow(File).to receive(:exist?).with(package_json_path).and_return(false)
      expect(described_class.package_manager_declared?(manager: "pnpm")).to be(false)
    end

    it "treats package_json: nil as a cached missing package.json" do
      expect(File).not_to receive(:read)

      expect(described_class.package_manager_declared?(manager: "pnpm", package_json: nil)).to be(false)
    end

    it "returns false when packageManager declares an unsupported tool" do
      allow(File).to receive(:exist?).with(package_json_path).and_return(true)
      allow(File).to receive(:read).with(package_json_path)
                                   .and_return('{"packageManager":"deno@1.0.0"}')
      expect(described_class.package_manager_declared?(manager: "pnpm")).to be(false)
    end

    # Corepack rejects a bare manager name with no @version, and `pnpm/action-setup`
    # has nothing to resolve from such a field — so the CI scaffold must still pin
    # the fallback version when packageManager is malformed this way.
    it "returns false when packageManager omits the version (no @ separator)" do
      allow(File).to receive(:exist?).with(package_json_path).and_return(true)
      allow(File).to receive(:read).with(package_json_path)
                                   .and_return('{"packageManager":"pnpm"}')
      expect(described_class.package_manager_declared?(manager: "pnpm")).to be(false)
    end

    it "returns false when packageManager has an empty version after the separator" do
      allow(File).to receive(:exist?).with(package_json_path).and_return(true)
      allow(File).to receive(:read).with(package_json_path)
                                   .and_return('{"packageManager":"pnpm@"}')
      expect(described_class.package_manager_declared?(manager: "pnpm")).to be(false)
    end

    it "returns false when packageManager has text after the version" do
      allow(File).to receive(:exist?).with(package_json_path).and_return(true)
      allow(File).to receive(:read).with(package_json_path)
                                   .and_return('{"packageManager":"pnpm@9.0.0 extra text"}')
      expect(described_class.package_manager_declared?(manager: "pnpm")).to be(false)
    end

    it "returns true when packageManager uses npm-style version specs" do
      %w[pnpm@10 pnpm@10.x pnpm@^10.0.0 pnpm@latest pnpm@*].each do |package_manager|
        expect(
          described_class.package_manager_declared?(
            manager: "pnpm",
            package_json: { "packageManager" => package_manager }
          )
        ).to be(true), "expected #{package_manager.inspect} to count as an explicit packageManager declaration"
      end
    end

    it "uses a provided package_json without reading package.json again" do
      expect(File).not_to receive(:read)

      expect(
        described_class.package_manager_declared?(
          manager: "pnpm",
          package_json: { "packageManager" => "pnpm@9.0.0" }
        )
      ).to be(true)
    end

    # Prevents a false negative in the CI scaffold: if pnpm is selected via
    # REACT_ON_RAILS_PACKAGE_MANAGER or pnpm-lock.yaml while package.json declares
    # a different manager, `pnpm/action-setup` still needs the explicit version pin.
    it "returns false when packageManager declares a different manager" do
      allow(File).to receive(:exist?).with(package_json_path).and_return(true)
      allow(File).to receive(:read).with(package_json_path)
                                   .and_return('{"packageManager":"yarn@1.22.0"}')
      expect(described_class.package_manager_declared?(manager: "pnpm")).to be(false)
    end

    it "does not treat devEngines.packageManager as declared for pnpm/action-setup v4" do
      expect(
        described_class.package_manager_declared?(
          manager: "pnpm",
          package_json: { "devEngines" => { "packageManager" => "pnpm@9.14.2" } }
        )
      ).to be(false)
    end
  end
end

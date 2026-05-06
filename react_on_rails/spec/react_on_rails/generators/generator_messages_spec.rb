# frozen_string_literal: true

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

  describe ".detect_package_manager" do
    let(:original_package_manager_env) { ENV.fetch("REACT_ON_RAILS_PACKAGE_MANAGER", nil) }

    around do |example|
      ENV.delete("REACT_ON_RAILS_PACKAGE_MANAGER")
      example.run

      if original_package_manager_env
        ENV["REACT_ON_RAILS_PACKAGE_MANAGER"] = original_package_manager_env
      else
        ENV.delete("REACT_ON_RAILS_PACKAGE_MANAGER")
      end
    end

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

    it "ignores an unsupported packageManager value and falls through to lockfiles" do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "package.json")).and_return(true)
      allow(File).to receive(:exist?).with(File.join(Dir.pwd, "yarn.lock")).and_return(true)
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(File.join(Dir.pwd, "package.json"))
                                   .and_return('{"packageManager": "unknown@1.0.0"}')

      expect(described_class.detect_package_manager).to eq("yarn")
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
end

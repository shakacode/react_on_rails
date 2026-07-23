# frozen_string_literal: true

require "ripper"
require_relative "../support/generator_spec_helper"

describe ProGenerator, type: :generator do
  include GeneratorSpec::TestCase

  destination File.expand_path("../dummy-for-generators", __dir__)

  def expect_parseable_ruby(source)
    expect(Ripper.sexp(source)).not_to be_nil
  end

  # Unit tests for prerequisite validation

  context "when base React on Rails is not installed" do
    let(:generator) { described_class.new }

    before do
      allow(generator).to receive(:destination_root).and_return("/fake/path")
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?)
        .with("/fake/path/config/initializers/react_on_rails.rb")
        .and_return(false)
    end

    specify "missing_base_installation? returns true with helpful error" do
      expect(generator.send(:missing_base_installation?)).to be true
      error_text = GeneratorMessages.messages.join("\n")
      expect(error_text).to include("React on Rails is not installed")
      expect(error_text).to include("rails g react_on_rails:install")
    end
  end

  context "when Pro gem is not installed" do
    let(:generator) { described_class.new }
    let(:fake_pid) { 12_345 }

    before do
      allow(Gem).to receive(:loaded_specs).and_return({})
      allow(generator).to receive(:gem_in_lockfile?).with("react_on_rails_pro").and_return(false)
      allow(Bundler).to receive(:with_unbundled_env).and_yield
      allow(Process).to receive(:spawn).and_return(fake_pid)
      allow(generator).to receive(:wait_for_bundle_process)
        .with(fake_pid).and_return(instance_double(Process::Status, success?: false))
    end

    specify "missing_pro_gem? returns true with standalone error message" do
      expect(generator.send(:missing_pro_gem?, force: true)).to be true
      expect(Bundler).to have_received(:with_unbundled_env)
      expect(Process).to have_received(:spawn)
        .with("bundle add react_on_rails_pro --version='#{generator.send(:pro_gem_version_requirement)}' --strict",
              out: anything, err: anything)
      error_text = GeneratorMessages.messages.join("\n")
      # Standalone message should NOT mention --pro flag
      expect(error_text).to include("This generator requires the react_on_rails_pro gem")
      expect(error_text).not_to include("You specified")
      expect(error_text).to include("react_on_rails_pro")
    end
  end

  context "when Pro gem is not installed but base react_on_rails is in the Gemfile" do
    let(:generator) { described_class.new }
    let(:gemfile_path) { File.join(destination_root, "Gemfile") }

    before do
      prepare_destination
      allow(generator).to receive(:destination_root).and_return(destination_root)
      allow(Gem).to receive(:loaded_specs).and_return({})
      allow(generator).to receive(:gem_in_lockfile?).with("react_on_rails_pro").and_return(false)
      allow(Bundler).to receive(:with_unbundled_env).and_yield
      allow(Process).to receive(:spawn)

      File.write(gemfile_path, <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails", "~> 16.0"
      RUBY
    end

    specify "missing_pro_gem? returns false and bypasses bundle add to let swap handle the Gemfile" do
      expect(generator.send(:missing_pro_gem?, force: true)).to be false
      expect(Process).not_to have_received(:spawn)
      expect(generator.send(:pro_gem_install_deferred?)).to be true
      expect(generator.send(:pro_gem_installed?)).to be false
    end

    specify "missing_pro_gem? also defers for parenthesized declarations with leading comments" do
      File.write(gemfile_path, <<~RUBY)
        source "https://rubygems.org"
        gem(
          # pinned for compatibility
          "react_on_rails",
          "~> 16.0",
          require: false
        )
      RUBY

      expect(generator.send(:missing_pro_gem?, force: true)).to be false
      expect(Process).not_to have_received(:spawn)
      expect(generator.send(:pro_gem_install_deferred?)).to be true
      expect(generator.send(:pro_gem_installed?)).to be false
    end
  end

  describe "#run_generator" do
    let(:generator) { described_class.new }
    let(:gemfile_path) { File.join(destination_root, "Gemfile") }

    before do
      prepare_destination
      allow(generator).to receive(:destination_root).and_return(destination_root)
      allow(generator).to receive(:print_generator_messages)
    end

    context "when invoked by the install generator" do
      let(:generator) { described_class.new([], { invoked_by_install: true }) }

      it "runs Pro setup without adding dependencies again" do
        expect(generator).to receive(:setup_pro).once
        expect(generator).not_to receive(:add_pro_npm_dependencies)

        generator.run_generator
      end
    end

    context "when invoked standalone" do
      before do
        allow(generator).to receive_messages(
          prerequisites_met?: true,
          swap_base_gem_for_pro_in_gemfile: true,
          update_imports_to_pro_package: nil,
          print_success_message: nil
        )
      end

      it "runs Pro setup and adds dependencies once" do
        expect(generator).to receive(:setup_pro).once
        expect(generator).to receive(:add_pro_npm_dependencies).once

        generator.run_generator
      end
    end

    it "stops before setup when the Gemfile swap fails" do
      allow(generator).to receive_messages(prerequisites_met?: true, swap_base_gem_for_pro_in_gemfile: false)
      allow(generator).to receive(:setup_pro)
      allow(generator).to receive(:add_pro_npm_dependencies)
      allow(generator).to receive(:update_imports_to_pro_package)
      allow(generator).to receive(:print_success_message)

      generator.run_generator

      expect(generator).not_to have_received(:setup_pro)
      expect(generator).not_to have_received(:add_pro_npm_dependencies)
      expect(generator).not_to have_received(:update_imports_to_pro_package)
      expect(generator).not_to have_received(:print_success_message)
    end

    it "passes the pre-prerequisite Gemfile snapshot into rollback handling" do
      original_gemfile = <<~RUBY
        source "https://rubygems.org"
        gem "react_on_rails", "~> 16.0"
      RUBY
      simulate_existing_file("Gemfile", original_gemfile)

      allow(generator).to receive(:base_react_on_rails_installed?).and_return(true)
      allow(generator).to receive(:attempt_pro_gem_auto_install) do
        File.write(gemfile_path, <<~RUBY)
          source "https://rubygems.org"
          gem "react_on_rails", "~> 16.0"
          gem "react_on_rails_pro", "~> 16.0"
        RUBY
        true
      end
      allow(generator).to receive(:setup_pro)
      allow(generator).to receive(:add_pro_npm_dependencies)
      allow(generator).to receive(:update_imports_to_pro_package)
      allow(generator).to receive(:print_success_message)

      captured_original_gemfile_content = nil
      allow(generator).to receive(:bundle_install_after_gem_swap) do |gemfile_path:, original_gemfile_content:|
        captured_original_gemfile_content = original_gemfile_content
        generator.send(
          :rollback_gemfile_after_failed_bundle_install,
          gemfile_path:,
          original_gemfile_content:
        )
        false
      end

      generator.run_generator

      expect(captured_original_gemfile_content).to eq(original_gemfile)
      expect(File.read(gemfile_path)).to eq(original_gemfile)
      expect(generator).not_to have_received(:setup_pro)
      expect(generator).not_to have_received(:add_pro_npm_dependencies)
      expect(generator).not_to have_received(:update_imports_to_pro_package)
      expect(generator).not_to have_received(:print_success_message)
    end
  end

  describe "#swap_base_gem_for_pro_in_gemfile" do
    let(:generator) { described_class.new }
    let(:gemfile_path) { File.join(destination_root, "Gemfile") }

    before do
      prepare_destination
      allow(generator).to receive(:destination_root).and_return(destination_root)
    end

    it "replaces react_on_rails with react_on_rails_pro and preserves the user's version pin" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails", "~> 16.0"
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expect(gemfile_content).to include('gem "react_on_rails_pro", "~> 16.0"')
      expect(gemfile_content).not_to match(/gem\s+["']react_on_rails["']/)
      expect(generator).to have_received(:bundle_install_after_gem_swap)
    end

    it "preserves trailing Gemfile guards and options on replaced entries" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails", "~> 16.0", require: false, if: ENV["ENABLE_ROR"]
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expect(gemfile_content).to include('gem "react_on_rails_pro", "~> 16.0", require: false')
      expect(gemfile_content).to include("if: ENV[\"ENABLE_ROR\"]")
      expect(gemfile_content).not_to include("gem \"react_on_rails\",")
    end

    it "preserves multi-constraint version declarations" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails", ">= 15.0", "< 16.0", require: false
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expect(gemfile_content).to include('gem "react_on_rails_pro", ">= 15.0", "< 16.0", require: false')
      expect(gemfile_content).not_to match(/gem\s+["']react_on_rails["']/)
    end

    it "preserves indentation when replacing a grouped Gemfile entry" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"

        group :default do
          gem "react_on_rails", "~> 16.0"
        end
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expect(gemfile_content).to include('  gem "react_on_rails_pro", "~> 16.0"')
      expect(generator).to have_received(:bundle_install_after_gem_swap)
    end

    it "preserves the user's multiline non-parenthesized declaration verbatim" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails",
          "~> 16.0"
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expect(gemfile_content).to include("gem \"react_on_rails_pro\",\n  \"~> 16.0\"")
      expect(gemfile_content).not_to match(/gem\s+["']react_on_rails["']/)
      expect(generator).to have_received(:bundle_install_after_gem_swap)
    end

    it "preserves non-version options in non-parenthesized multiline declarations" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails",
          "~> 16.0",
          require: false
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expect(gemfile_content).to include('gem "react_on_rails_pro",')
      expect(gemfile_content).to include('"~> 16.0",')
      expect(gemfile_content).to include("require: false")
      expect(gemfile_content).not_to match(/gem\s+["']react_on_rails["']/)
    end

    it "does not leave a trailing comma when replacing multiline declarations before another gem" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails",
          "~> 16.0"
        gem "rails"
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expect(gemfile_content).to include("gem \"react_on_rails_pro\",\n  \"~> 16.0\"")
      expect(gemfile_content).to include('gem "rails"')
      expect(gemfile_content).not_to match(/react_on_rails_pro".*,\s*\n\s*gem "rails"/)
    end

    it "preserves a multiline declaration whose comma is followed by an inline comment" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails", # pinned for compatibility
          "~> 16.0"
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expect(gemfile_content).to include('gem "react_on_rails_pro", # pinned for compatibility')
      expect(gemfile_content).to include('  "~> 16.0"')
      expect(gemfile_content).not_to match(/gem\s+["']react_on_rails["']/)
    end

    it "preserves a multiline declaration whose comma is followed by a tight inline comment" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails",#pinned for compatibility
          "~> 16.0"
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expect(gemfile_content).to include('gem "react_on_rails_pro",#pinned for compatibility')
      expect(gemfile_content).to include('  "~> 16.0"')
      expect(gemfile_content).not_to match(/gem\s+["']react_on_rails["']/)
    end

    it "consumes multiline declarations when comment-only lines appear before continuation lines" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails",
          # pinned for compatibility
          "~> 16.0"
        gem "rails"
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expect(gemfile_content).to include('gem "react_on_rails_pro",')
      expect(gemfile_content).to include('"~> 16.0"')
      expect(gemfile_content).to include("gem \"rails\"")
      expect(gemfile_content).not_to match(/gem\s+["']react_on_rails["']/)
    end

    it "consumes multiline declarations when blank lines appear before continuation lines" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails",

          "~> 16.0"
        gem "rails"
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expect(gemfile_content).to include('gem "react_on_rails_pro",')
      expect(gemfile_content).to include('"~> 16.0"')
      expect(gemfile_content).to include("gem \"rails\"")
      expect(gemfile_content).not_to match(/gem\s+["']react_on_rails["']/)
    end

    it "does not consume the next gem line when base declaration ends with a trailing comma" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails",
        gem "rails"
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expected_version = generator.send(:pro_gem_version_requirement)
      expect(gemfile_content).to include("gem \"react_on_rails_pro\", \"#{expected_version}\"")
      expect(gemfile_content).to include("gem \"rails\"")
    end

    it "preserves single quote style when replacing single-quoted Gemfile entries" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem 'react_on_rails', '~> 16.0'
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expect(gemfile_content).to include("gem 'react_on_rails_pro', '~> 16.0'")
      expect(generator).to have_received(:bundle_install_after_gem_swap)
    end

    it "replaces parenthesized Gemfile declarations" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem("react_on_rails", "~> 16.0")
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expect(gemfile_content).to include('gem "react_on_rails_pro", "~> 16.0"')
      expect(gemfile_content).not_to include('"~> 16.0")')
      expect(gemfile_content).not_to include('gem("react_on_rails"')
      expect(generator).to have_received(:bundle_install_after_gem_swap)
    end

    it "replaces parenthesized Gemfile declarations without leaving trailing parentheses" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem("react_on_rails", "~> 16.0", require: false, if: ENV.fetch("ENABLE_ROR", false))
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expect(gemfile_content).to include('gem "react_on_rails_pro", "~> 16.0", require: false')
      expect(gemfile_content).to include('if: ENV.fetch("ENABLE_ROR", false)')
      expect(gemfile_content).not_to include("false))")
    end

    it "replaces parenthesized Gemfile declarations with postfix if guards without leaving trailing parentheses" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem("react_on_rails", "~> 16.0") if ENV["ENABLE_ROR"]
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expect(gemfile_content).to eq(<<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails_pro", "~> 16.0" if ENV["ENABLE_ROR"]
      RUBY
      expect_parseable_ruby(gemfile_content)
      expect(generator).to have_received(:bundle_install_after_gem_swap)
    end

    it "replaces multiline parenthesized Gemfile declarations with postfix unless guards" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem(
          "react_on_rails",
          "~> 16.0",
          require: false
        ) unless ENV["SKIP_ROR"]
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expect(gemfile_content).to eq(<<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails_pro",
          "~> 16.0",
          require: false unless ENV["SKIP_ROR"]
      RUBY
      expect_parseable_ruby(gemfile_content)
      expect(generator).to have_received(:bundle_install_after_gem_swap)
    end

    it "replaces multiline parenthesized Gemfile declarations" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem(
          "react_on_rails",
          "~> 16.0"
        )
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expect(gemfile_content).to include('gem "react_on_rails_pro",')
      expect(gemfile_content).to include('"~> 16.0"')
      expect(gemfile_content).not_to include('"react_on_rails"')
      expect(generator).to have_received(:bundle_install_after_gem_swap)
    end

    it "does not introduce a blank line after a multiline parenthesized declaration" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem(
          "react_on_rails",
          "~> 16.0"
        )
        gem "rails", "~> 7.1"
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expect(gemfile_content).to eq(<<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails_pro",
          "~> 16.0"
        gem "rails", "~> 7.1"
      RUBY
      expect_parseable_ruby(gemfile_content)
      expect(generator).to have_received(:bundle_install_after_gem_swap)
    end

    it "replaces parenthesized declarations that start on the gem line and continue across lines" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem("react_on_rails",
          "~> 16.0",
          require: false
        )
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expect(gemfile_content).to include('gem "react_on_rails_pro",')
      expect(gemfile_content).to include('"~> 16.0",')
      expect(gemfile_content).to include("require: false")
      expect(gemfile_content).not_to include('gem("react_on_rails"')
      expect(gemfile_content.lines.any? { |line| line.strip == ")" }).to be false
    end

    it "preserves options and guards in multiline parenthesized Gemfile declarations" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem(
          "react_on_rails",
          "~> 16.0",
          require: false,
          if: ENV["ENABLE_ROR"]
        )
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expect(gemfile_content).to include('gem "react_on_rails_pro",')
      expect(gemfile_content).to include('"~> 16.0",')
      expect(gemfile_content).to include("require: false,")
      expect(gemfile_content).to include('if: ENV["ENABLE_ROR"]')
      expect(gemfile_content).not_to include('"react_on_rails"')
    end

    it "handles comments containing closing parentheses inside multiline parenthesized declarations" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem(
          "react_on_rails",
          # pinned :)
          "~> 16.0"
        )
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expect(gemfile_content).to include('gem "react_on_rails_pro",')
      expect(gemfile_content).to include('"~> 16.0"')
      expect(gemfile_content).not_to include("gem(")
    end

    it "handles inline Ruby comments containing parentheses in multiline parenthesized declarations" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem(
          "react_on_rails",
          "~> 16.0", # pinned :)
          require: false
        )
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      expect { generator.send(:swap_base_gem_for_pro_in_gemfile) }.not_to raise_error

      gemfile_content = File.read(gemfile_path)
      expect(gemfile_content).to include('gem "react_on_rails_pro",')
      expect(gemfile_content).to include('"~> 16.0",')
      expect(gemfile_content).to include("require: false")
      expect(gemfile_content).not_to include("gem(")
    end

    it "handles nested parentheses in multiline parenthesized Gemfile options" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem(
          "react_on_rails",
          "~> 16.0",
          if: ENV.fetch("ENABLE_ROR") { true }
        )
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expect(gemfile_content).to include('gem "react_on_rails_pro",')
      expect(gemfile_content).to include('"~> 16.0",')
      expect(gemfile_content).to include('if: ENV.fetch("ENABLE_ROR") { true }')
      expect(gemfile_content).not_to include('"react_on_rails"')
      expect(gemfile_content).not_to include("gem(")
    end

    it "removes the stale base gem entry and runs bundle install when react_on_rails_pro already exists" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails", "~> 16.0"
        gem "react_on_rails_pro", "~> 16.0"
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)
      allow(generator).to receive(:say)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expect(gemfile_content).to eq(<<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails_pro", "~> 16.0"
      RUBY
      expect_parseable_ruby(gemfile_content)
      expect(generator).to have_received(:say)
        .with(
          "ℹ️  Existing react_on_rails_pro Gemfile entry detected; " \
          "removed the now-stale react_on_rails entries",
          :yellow
        )
      expect(generator).to have_received(:bundle_install_after_gem_swap)
    end

    it "removes the stale base gem and bundles when a parenthesized pro declaration has comment lines" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails", "~> 16.0"
        gem(
          # pinned for compatibility
          "react_on_rails_pro",
          "~> 16.0"
        )
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)
      allow(generator).to receive(:say)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expect(gemfile_content).to eq(<<~RUBY)
        source "https://rubygems.org"
        gem(
          # pinned for compatibility
          "react_on_rails_pro",
          "~> 16.0"
        )
      RUBY
      expect_parseable_ruby(gemfile_content)
      expect(generator).to have_received(:say)
        .with(
          "ℹ️  Existing react_on_rails_pro Gemfile entry detected; " \
          "removed the now-stale react_on_rails entries",
          :yellow
        )
      expect(generator).to have_received(:bundle_install_after_gem_swap)
    end

    it "replaces duplicate base gem declarations without dropping grouped declarations" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails", "~> 16.0"
        group :test do
          gem "react_on_rails", "~> 16.0", require: false
        end
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expect(gemfile_content).to eq(<<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails_pro", "~> 16.0"
        group :test do
          gem "react_on_rails_pro", "~> 16.0", require: false
        end
      RUBY
      expect_parseable_ruby(gemfile_content)
      expect(gemfile_content).not_to match(/gem\s+["']react_on_rails["']/)
      expect(generator).to have_received(:bundle_install_after_gem_swap)
    end

    it "replaces base gem declarations in both conditional branches" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        if ENV["ROR_EDGE"]
          gem "react_on_rails", github: "shakacode/react_on_rails", branch: "master"
        else
          gem "react_on_rails", "~> 16.0"
        end
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expected_version = generator.send(:pro_gem_version_requirement)
      expect(gemfile_content).to eq(<<~RUBY)
        source "https://rubygems.org"
        if ENV["ROR_EDGE"]
          gem "react_on_rails_pro", "#{expected_version}", github: "shakacode/react_on_rails", branch: "master"
        else
          gem "react_on_rails_pro", "~> 16.0"
        end
      RUBY
      expect_parseable_ruby(gemfile_content)
      expect(gemfile_content).not_to match(/gem\s+["']react_on_rails["']/)
      expect(generator).to have_received(:bundle_install_after_gem_swap)
    end

    it "replaces duplicate base gem declarations with platform-specific options" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails", "~> 16.0"
        gem "react_on_rails", "~> 16.0", platforms: :jruby
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expect(gemfile_content).to eq(<<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails_pro", "~> 16.0"
        gem "react_on_rails_pro", "~> 16.0", platforms: :jruby
      RUBY
      expect_parseable_ruby(gemfile_content)
      expect(gemfile_content).not_to match(/gem\s+["']react_on_rails["']/)
      expect(generator).to have_received(:bundle_install_after_gem_swap)
    end

    it "does nothing when Gemfile has no react_on_rails entry" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "rails"
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      original_content = File.read(gemfile_path)
      generator.send(:swap_base_gem_for_pro_in_gemfile)

      expect(File.read(gemfile_path)).to eq(original_content)
      expect(generator).not_to have_received(:bundle_install_after_gem_swap)
    end

    it "does not replace other parenthesized gem declarations that reference react_on_rails in options" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem("other_gem", require: "react_on_rails")
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      original_content = File.read(gemfile_path)
      result = generator.send(:swap_base_gem_for_pro_in_gemfile)

      expect(result).to be(false)
      expect(File.read(gemfile_path)).to eq(original_content)
      expect(generator).not_to have_received(:bundle_install_after_gem_swap)
    end

    it "warns when Gemfile is missing" do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(gemfile_path).and_return(false)
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      warning_text = GeneratorMessages.messages.join("\n")
      expect(warning_text).to include("Could not find Gemfile")
      expect(warning_text).to include("non-standard Gemfile path")
      expect(generator).not_to have_received(:bundle_install_after_gem_swap)
    end

    it "warns and skips bundle install when Gemfile cannot be written" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails", "~> 16.0"
      RUBY
      allow(generator).to receive(:atomic_write_file).and_raise(Errno::EACCES)
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      warning_text = GeneratorMessages.messages.join("\n")
      expect(warning_text).to include("Could not update Gemfile")
      expect(warning_text).to include("Please update your Gemfile manually")
      expect(generator).not_to have_received(:bundle_install_after_gem_swap)
    end

    it "replaces base gem entries that include inline comments" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails" # pinned for compatibility
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expected_version = generator.send(:pro_gem_version_requirement)
      expect(gemfile_content).to include("gem \"react_on_rails_pro\", \"#{expected_version}\"")
      expect(gemfile_content).not_to include("gem \"react_on_rails\" # pinned for compatibility")
      expect(generator).to have_received(:bundle_install_after_gem_swap)
    end

    it "does not modify Gemfile in --pretend mode" do
      pretend_generator = described_class.new([], { pretend: true })
      allow(pretend_generator).to receive(:destination_root).and_return(destination_root)
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails", "~> 16.0"
      RUBY

      original_content = File.read(gemfile_path)
      expect(pretend_generator).not_to receive(:bundle_install_after_gem_swap)

      pretend_generator.send(:swap_base_gem_for_pro_in_gemfile)

      expect(File.read(gemfile_path)).to eq(original_content)
    end

    it "returns false and warns when neither base nor pro gem entries are present" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "rails"
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      result = generator.send(:swap_base_gem_for_pro_in_gemfile)

      expect(result).to be(false)
      expect(File.read(gemfile_path)).to include('gem "rails"')
      expect(generator).not_to have_received(:bundle_install_after_gem_swap)
      expect(GeneratorMessages.messages.join("\n"))
        .to include("Could not find react_on_rails or react_on_rails_pro in Gemfile")
    end

    it "returns false when only an auto-installed Pro gem entry is present" do
      original_gemfile_content = <<~RUBY
        source "https://rubygems.org"
        gem "rails"
      RUBY
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "rails"
        gem "react_on_rails_pro", "~> 16.0"
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      result = generator.send(
        :swap_base_gem_for_pro_in_gemfile,
        original_gemfile_content_for_rollback: original_gemfile_content
      )

      expect(result).to be(false)
      expect(File.read(gemfile_path)).to eq(original_gemfile_content)
      expect(generator).not_to have_received(:bundle_install_after_gem_swap)
      expect(GeneratorMessages.messages.join("\n"))
        .to include("Could not find react_on_rails or react_on_rails_pro in Gemfile")
    end

    it "preserves Gemfile file mode when writing updates" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails", "~> 16.0"
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)
      File.chmod(0o644, gemfile_path)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      expect(File.stat(gemfile_path).mode & 0o777).to eq(0o644)
    end

    it "preserves a path: argument alongside the version pin" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails", "~> 16.0", path: "../react_on_rails"
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expect(gemfile_content).to include('gem "react_on_rails_pro", "~> 16.0", path: "../react_on_rails"')
    end

    it "preserves a git: argument alongside the version pin" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails", "~> 16.0", git: "https://example.invalid/repo.git"
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expect(gemfile_content).to include('gem "react_on_rails_pro", "~> 16.0", git: "https://example.invalid/repo.git"')
    end

    it "adds the default version when the user has no version pin" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails", path: "../react_on_rails"
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expected_version = generator.send(:pro_gem_version_requirement)
      expect(gemfile_content).to include(
        "gem \"react_on_rails_pro\", \"#{expected_version}\", path: \"../react_on_rails\""
      )
    end

    it "adds the default version when the user has only a git: argument" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails", git: "https://example.invalid/repo.git"
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expected_version = generator.send(:pro_gem_version_requirement)
      expect(gemfile_content).to include(
        "gem \"react_on_rails_pro\", \"#{expected_version}\", git: \"https://example.invalid/repo.git\""
      )
    end

    it "adds the default version when the user has only the bare gem name" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails"
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expected_version = generator.send(:pro_gem_version_requirement)
      expect(gemfile_content).to include("gem \"react_on_rails_pro\", \"#{expected_version}\"")
      expect(gemfile_content).not_to match(/gem\s+["']react_on_rails["']/)
    end
  end

  describe "#bundle_install_after_gem_swap" do
    let(:generator) { described_class.new }
    let(:fake_pid) { 23_456 }
    let(:gemfile_path) { File.join(destination_root, "Gemfile") }

    before do
      prepare_destination
      allow(generator).to receive(:destination_root).and_return(destination_root)
      GeneratorMessages.clear
      allow(Bundler).to receive(:with_unbundled_env).and_yield
      allow(Process).to receive(:spawn).and_return(fake_pid)
    end

    it "returns without warnings when bundle install succeeds" do
      allow(generator).to receive(:wait_for_bundle_process)
        .with(fake_pid).and_return(instance_double(Process::Status, success?: true))

      generator.send(:bundle_install_after_gem_swap)

      expect(GeneratorMessages.messages).to eq([])
    end

    it "skips bundle install in --pretend mode" do
      pretend_generator = described_class.new([], { pretend: true })
      allow(pretend_generator).to receive(:destination_root).and_return(destination_root)

      expect(Bundler).not_to receive(:with_unbundled_env)
      pretend_generator.send(:bundle_install_after_gem_swap)
    end

    it "uses bounded process waiting and warns on timeout" do
      allow(generator).to receive(:wait_for_bundle_process).with(fake_pid).and_return(nil)

      generator.send(:bundle_install_after_gem_swap)

      expect(Process).to have_received(:spawn).with(
        { "BUNDLE_GEMFILE" => File.join(destination_root, "Gemfile") },
        "bundle",
        "install",
        out: $stdout,
        err: $stderr,
        chdir: destination_root
      )
      expect(generator).to have_received(:wait_for_bundle_process).with(fake_pid)
      warning_text = GeneratorMessages.messages.join("\n")
      expect(warning_text).to include("timed out")
      expect(warning_text).to include("bundle install")
    end

    it "reverts Gemfile when bundle install fails after a swap" do
      original_content = <<~RUBY
        source "https://rubygems.org"
        gem "react_on_rails", "~> 16.0"
      RUBY
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails_pro", "~> 16.0"
      RUBY
      allow(generator).to receive(:wait_for_bundle_process)
        .with(fake_pid).and_return(instance_double(Process::Status, success?: false))

      generator.send(
        :bundle_install_after_gem_swap,
        gemfile_path:,
        original_gemfile_content: original_content
      )

      expect(File.read(gemfile_path)).to eq(original_content)
      warning_text = GeneratorMessages.messages.join("\n")
      expect(warning_text).to include("failed after swapping Gemfile entries")
      expect(warning_text).to include("Gemfile has been reverted to its previous react_on_rails entry")
    end
  end

  describe "#update_imports_to_pro_package" do
    let(:generator) { described_class.new }
    let(:application_js_path) { File.join(destination_root, "app/javascript/packs/application.js") }
    let(:server_js_path) { File.join(destination_root, "client/server.js") }
    let(:frontend_js_path) { File.join(destination_root, "app/frontend/entrypoints/client.ts") }
    let(:vue_component_path) { File.join(destination_root, "app/frontend/components/RorWidget.vue") }
    let(:svelte_component_path) { File.join(destination_root, "frontend/components/RorWidget.svelte") }

    before do
      prepare_destination
      allow(generator).to receive(:destination_root).and_return(destination_root)
      simulate_existing_file("app/javascript/packs/application.js", <<~JS)
        import ReactOnRails from "react-on-rails";
        const ror = require("react-on-rails");
        const commentedRequire = require(/* webpackIgnore: true */ "react-on-rails");
        const lazyRor = import(/* webpackChunkName: "ror" */ "react-on-rails");
        const lazyRorMultiline = import(
          /* webpackMode: "lazy" */
          "react-on-rails/client"
        );
        const lazyRorRequire = require(
          "react-on-rails/server"
        );
        /* short comment */ import InlineReactOnRails from "react-on-rails";
        /* eslint-disable import/no-unassigned-import */ import "react-on-rails";
        const keepRor = require("react-on-rails"); // /* not a block comment start
        const commentLikeString = "/* not a JS comment";
        import ReactOnRailsServer from "react-on-rails/server";
        import ReactOnRailsClient from "react-on-rails/client";
        import "react-on-rails";
        export { default as ReactOnRailsExport } from "react-on-rails";
        import CustomPackage from "react-on-rails-utils";
        const scoped = "@scope/react-on-rails";
        const url = "https://cdn.example.com/react-on-rails/client.js";
        const importTemplate = 'import("react-on-rails")';
        const fromTemplate = "import Example from \\"react-on-rails\\"";
        // import "react-on-rails";
        /*
         * import ReactOnRails from "react-on-rails";
         */
      JS
      simulate_existing_file("client/server.js", "import ReactOnRails from \"react-on-rails-pro\";\n")
      simulate_existing_file("app/frontend/entrypoints/client.ts", "import ReactOnRails from \"react-on-rails\";\n")
      simulate_existing_file("app/frontend/components/RorWidget.vue", <<~VUE)
        <script>
        import ReactOnRails from "react-on-rails";
        const ror = require("react-on-rails");
        </script>
      VUE
      simulate_existing_file("frontend/components/RorWidget.svelte", <<~SVELTE)
        <script>
          import ReactOnRails from "react-on-rails";
        </script>
      SVELTE
    end

    it "updates react-on-rails imports and requires to react-on-rails-pro" do
      generator.send(:update_imports_to_pro_package)

      expect(File.read(application_js_path)).to include('import ReactOnRails from "react-on-rails-pro";')
      expect(File.read(application_js_path)).to include('require("react-on-rails-pro")')
      expect(File.read(application_js_path)).to include('require(/* webpackIgnore: true */ "react-on-rails-pro")')
      expect(File.read(application_js_path)).to include('import(/* webpackChunkName: "ror" */ "react-on-rails-pro")')
      expect(File.read(application_js_path)).to include('"react-on-rails-pro/client"')
      expect(File.read(application_js_path)).to include('"react-on-rails-pro/server"')
      expect(File.read(application_js_path)).to include(
        '/* short comment */ import InlineReactOnRails from "react-on-rails-pro";'
      )
      expect(File.read(application_js_path)).to include(
        '/* eslint-disable import/no-unassigned-import */ import "react-on-rails-pro";'
      )
      expect(File.read(application_js_path)).to include('import ReactOnRailsServer from "react-on-rails-pro/server";')
      expect(File.read(application_js_path)).to include('import ReactOnRailsClient from "react-on-rails-pro/client";')
      expect(File.read(application_js_path)).to include('import "react-on-rails-pro";')
      expect(File.read(application_js_path)).to include(
        'export { default as ReactOnRailsExport } from "react-on-rails-pro";'
      )
      expect(File.read(application_js_path)).to include('import CustomPackage from "react-on-rails-utils";')
      expect(File.read(application_js_path)).to include('const scoped = "@scope/react-on-rails";')
      expect(File.read(application_js_path)).to include('const url = "https://cdn.example.com/react-on-rails/client.js";')
      expect(File.read(application_js_path)).to include('const importTemplate = \'import("react-on-rails")\';')
      expect(File.read(application_js_path)).to include(
        'const fromTemplate = "import Example from \\"react-on-rails\\"";'
      )
      expect(File.read(application_js_path)).to include('// import "react-on-rails";')
      expect(File.read(application_js_path)).to include('* import ReactOnRails from "react-on-rails";')
      expect(File.read(server_js_path)).to include('import ReactOnRails from "react-on-rails-pro";')
      expect(File.read(frontend_js_path)).to include('import ReactOnRails from "react-on-rails-pro";')
      expect(File.read(vue_component_path)).to include('import ReactOnRails from "react-on-rails-pro";')
      expect(File.read(vue_component_path)).to include('require("react-on-rails-pro")')
      expect(File.read(svelte_component_path)).to include('import ReactOnRails from "react-on-rails-pro";')
    end

    it "does not write files in --pretend mode" do
      pretend_generator = described_class.new([], { pretend: true })
      allow(pretend_generator).to receive(:destination_root).and_return(destination_root)
      original_content = File.read(application_js_path)

      pretend_generator.send(:update_imports_to_pro_package)

      expect(File.read(application_js_path)).to eq(original_content)
    end

    it "uses atomic writes for rewritten import files" do
      allow(generator).to receive(:atomic_write_file).and_call_original

      generator.send(:update_imports_to_pro_package)

      expect(generator).to have_received(:atomic_write_file).at_least(:once)
    end

    it "keeps multiline dynamic import tracking active when comments contain unrelated closing parentheses" do
      source = <<~JS
        const lazyRor = import(
          /* webpackMode: "lazy" */ // some(comment)
          "react-on-rails/client"
        );
      JS

      rewritten = generator.send(:rewrite_react_on_rails_module_specifiers, source)

      expect(rewritten).to include('"react-on-rails-pro/client"')
    end

    it "keeps multiline module-call tracking active when wrapper parens close later" do
      source = <<~JS
        const wrappedLazyRor = someWrapper(import(
          "react-on-rails"
        ));
      JS

      rewritten = generator.send(:rewrite_react_on_rails_module_specifiers, source)

      expect(rewritten).to include('"react-on-rails-pro"')
    end

    it "rewrites imports that appear after a block comment closes on the same line" do
      source = <<~JS
        /*
         * explanatory comment
         */ import ReactOnRails from "react-on-rails";
      JS

      rewritten = generator.send(:rewrite_react_on_rails_module_specifiers, source)

      expect(rewritten).to include('*/ import ReactOnRails from "react-on-rails-pro";')
    end

    it "rewrites multiline static imports when from and module specifier are on separate lines" do
      source = <<~JS
        import {
          ReactOnRailsComponent
        } from
          "react-on-rails";
      JS

      rewritten = generator.send(:rewrite_react_on_rails_module_specifiers, source)

      expect(rewritten).to include('"react-on-rails-pro";')
    end

    it "rewrites re-export statements from react-on-rails" do
      source = <<~JS
        export { default as ReactOnRailsExport } from "react-on-rails";
        export type {
          ReactOnRailsComponent
        } from
          "react-on-rails";
      JS

      rewritten = generator.send(:rewrite_react_on_rails_module_specifiers, source)

      expect(rewritten).to include('export { default as ReactOnRailsExport } from "react-on-rails-pro";')
      expect(rewritten).to include('"react-on-rails-pro";')
      expect(rewritten.scan("react-on-rails-pro").size).to eq(2)
    end

    it "does not rewrite imports inside multiline template literals" do
      source = <<~JS
        const importTemplate = `
          import ReactOnRails from "react-on-rails";
          const packageName = "react-on-rails/client";
        `;
        import ReactOnRails from "react-on-rails";
      JS

      rewritten = generator.send(:rewrite_react_on_rails_module_specifiers, source)

      expect(rewritten).to include('import ReactOnRails from "react-on-rails";')
      expect(rewritten).to include('const packageName = "react-on-rails/client";')
      expect(rewritten).to include("import ReactOnRails from \"react-on-rails-pro\";")
      expect(rewritten.scan("react-on-rails-pro").size).to eq(1)
    end

    it "rewrites imports that appear after a multiline template literal closes on the same line" do
      source = <<~JS
        const importTemplate = `
          import ReactOnRails from "react-on-rails";
        `; const ror = require("react-on-rails");
      JS

      rewritten = generator.send(:rewrite_react_on_rails_module_specifiers, source)

      expect(rewritten).to include('import ReactOnRails from "react-on-rails";')
      expect(rewritten).to include('`; const ror = require("react-on-rails-pro");')
      expect(rewritten.scan("react-on-rails-pro").size).to eq(1)
    end

    it "rewrites imports that appear before a multiline template literal opens on the same line" do
      source = <<~JS
        const ror = require("react-on-rails"); const importTemplate = `
          import ReactOnRails from "react-on-rails";
        `;
      JS

      rewritten = generator.send(:rewrite_react_on_rails_module_specifiers, source)

      expect(rewritten).to include('const ror = require("react-on-rails-pro");')
      expect(rewritten).to include('import ReactOnRails from "react-on-rails";')
      expect(rewritten.scan("react-on-rails-pro").size).to eq(1)
    end

    it "does not rewrite module specifiers inside single-line template literals" do
      source = <<~JS
        const inlineTemplate = `require("react-on-rails") and import("react-on-rails/client")`;
      JS

      rewritten = generator.send(:rewrite_react_on_rails_module_specifiers, source)

      expect(rewritten).to include('`require("react-on-rails") and import("react-on-rails/client")`')
      expect(rewritten).not_to include("react-on-rails-pro")
    end

    it "rewrites module specifiers outside single-line template literals on the same line" do
      source = <<~JS
        const inlineTemplate = `require("react-on-rails")`; const ror = require("react-on-rails");
      JS

      rewritten = generator.send(:rewrite_react_on_rails_module_specifiers, source)

      expect(rewritten).to include('`require("react-on-rails")`')
      expect(rewritten).to include('const ror = require("react-on-rails-pro");')
      expect(rewritten.scan("react-on-rails-pro").size).to eq(1)
    end

    it "preserves escaped sequences when restoring inline template literal placeholders" do
      source = <<~'JS'
        const inlineTemplate = `\\n and \\1`;
        const ror = require("react-on-rails");
      JS

      rewritten = generator.send(:rewrite_react_on_rails_module_specifiers, source)

      expect(rewritten).to include('const inlineTemplate = `\\\\n and \\\\1`;')
      expect(rewritten).to include('const ror = require("react-on-rails-pro");')
    end

    it "rewrites imports between a closed inline template literal and a multiline template literal start" do
      source = <<~JS
        `done`; import("react-on-rails"); `multiline-start
      JS

      rewritten = generator.send(:rewrite_react_on_rails_module_specifiers, source)

      expect(rewritten).to include('`done`; import("react-on-rails-pro"); `multiline-start')
    end

    it "rewrites imports after a block comment closes before a multiline template literal start" do
      source = <<~JS
        /*
         odd backtick ` still comment */ import("react-on-rails"); `multiline-start
      JS

      rewritten = generator.send(:rewrite_react_on_rails_module_specifiers, source)

      expect(rewritten).to include('odd backtick ` still comment */ import("react-on-rails-pro"); `multiline-start')
    end

    it "rewrites imports after a block-comment-to-template-literal transition closes" do
      source = <<~JS
        /*
         odd backtick ` still comment */ import("react-on-rails"); `multiline-start
        content
        `; import("react-on-rails");
      JS

      rewritten = generator.send(:rewrite_react_on_rails_module_specifiers, source)

      expect(rewritten).to include('import("react-on-rails-pro"); `multiline-start')
      expect(rewritten).to include('`; import("react-on-rails-pro");')
    end

    it "finds the closing backtick when template literal content contains /* on the same line" do
      source = <<~JS
        const x = `multiline-start
        content /* with embedded `; import("react-on-rails");
      JS

      rewritten = generator.send(:rewrite_react_on_rails_module_specifiers, source)

      expect(rewritten).to include('`; import("react-on-rails-pro");')
    end

    it "rewrites all matching specifiers on a pending continuation line" do
      source = <<~JS
        import {
          ReactOnRailsComponent
        } from
          "react-on-rails"; import ReactOnRails from "react-on-rails";
      JS

      rewritten = generator.send(:rewrite_react_on_rails_module_specifiers, source)

      expect(rewritten.scan("react-on-rails-pro").size).to eq(2)
      expect(rewritten).to include(
        '"react-on-rails-pro"; import ReactOnRails from "react-on-rails-pro";'
      )
    end

    it "does not treat quoted backticks as multiline template delimiters" do
      source = <<~JS
        const marker = "`"; // should not toggle template-literal tracking
        import ReactOnRails from "react-on-rails";
      JS

      rewritten = generator.send(:rewrite_react_on_rails_module_specifiers, source)

      expect(rewritten).to include('const marker = "`";')
      expect(rewritten).to include('import ReactOnRails from "react-on-rails-pro";')
    end

    it "tracks multiline template literal state when quoted backticks and template delimiters share a line" do
      source = <<~JS
        const marker = "`"; const templateStart = `template header
          import ReactOnRails from "react-on-rails";
        `;
        import ReactOnRails from "react-on-rails";
      JS

      rewritten = generator.send(:rewrite_react_on_rails_module_specifiers, source)

      expect(rewritten).to include('import ReactOnRails from "react-on-rails";')
      expect(rewritten).to include('import ReactOnRails from "react-on-rails-pro";')
      expect(rewritten.scan("react-on-rails-pro").size).to eq(1)
    end

    it "ignores backticks that only appear inside multiline block comments" do
      source = <<~JS
        /* docs start
         docs use `code
        end */
        import ReactOnRails from "react-on-rails";
      JS

      rewritten = generator.send(:rewrite_react_on_rails_module_specifiers, source)

      expect(rewritten).to include("docs use `code")
      expect(rewritten).to include('import ReactOnRails from "react-on-rails-pro";')
    end

    it "detects unclosed block comments when multiple block markers appear on one line" do
      source_line = "/* closed */ const keep = true; /* unclosed"

      expect(generator.send(:unclosed_block_comment_starts?, source_line)).to be true
    end

    it "rewrites jest.mock calls targeting the base package" do
      source = <<~JS
        jest.mock('react-on-rails', () => ({ authenticityHeaders: jest.fn() }));
        jest.mock("react-on-rails/client", () => ({}));
      JS

      rewritten = generator.send(:rewrite_react_on_rails_module_specifiers, source)

      expect(rewritten).to include("jest.mock('react-on-rails-pro',")
      expect(rewritten).to include('jest.mock("react-on-rails-pro/client",')
    end

    it "rewrites vi.mock and vi.importActual calls targeting the base package" do
      source = <<~JS
        vi.mock('react-on-rails', () => ({}));
        const mod = await vi.importActual('react-on-rails/client');
      JS

      rewritten = generator.send(:rewrite_react_on_rails_module_specifiers, source)

      expect(rewritten).to include("vi.mock('react-on-rails-pro',")
      expect(rewritten).to include("vi.importActual('react-on-rails-pro/client')")
    end

    it "rewrites the full set of Jest mock helpers" do
      source = <<~JS
        jest.createMockFromModule('react-on-rails');
        jest.unmock('react-on-rails');
        jest.deepUnmock('react-on-rails');
        jest.doMock('react-on-rails/client');
        vi.doUnmock('react-on-rails');
        jest.dontMock('react-on-rails');
        jest.setMock('react-on-rails', {});
        jest.unstable_mockModule('react-on-rails', () => ({}));
        jest.unstable_unmockModule('react-on-rails');
        const a = jest.requireActual('react-on-rails');
        const b = jest.requireMock('react-on-rails/client');
        vi.importMock('react-on-rails');
      JS

      rewritten = generator.send(:rewrite_react_on_rails_module_specifiers, source)

      expect(rewritten.scan("react-on-rails-pro").size).to eq(12)
      expect(rewritten).not_to match(/['"]react-on-rails['"]/)
    end

    it "rewrites multiline Jest and Vitest mock helper calls" do
      source = <<~JS
        jest.mock(
          'react-on-rails',
          () => ({ authenticityHeaders: jest.fn() })
        );
        const actual = await vi.importActual(
          'react-on-rails/client'
        );
      JS

      rewritten = generator.send(:rewrite_react_on_rails_module_specifiers, source)

      expect(rewritten).to include("'react-on-rails-pro',")
      expect(rewritten).to include("'react-on-rails-pro/client'")
      expect(rewritten).not_to match(/['"]react-on-rails['"]/)
    end

    it "does not rewrite non-specifier strings inside multiline mock factories" do
      source = <<~JS
        jest.mock(
          'react-on-rails',
          () => ({ packageName: 'react-on-rails' })
        );
      JS

      rewritten = generator.send(:rewrite_react_on_rails_module_specifiers, source)

      expect(rewritten).to include("'react-on-rails-pro',")
      expect(rewritten).to include("packageName: 'react-on-rails'")
    end

    it "rewrites typed Jest mock helper module specifiers" do
      source = "jest.mock<typeof import('react-on-rails')>('react-on-rails', () => ({}));\n"

      rewritten = generator.send(:rewrite_react_on_rails_module_specifiers, source)

      expect(rewritten).to eq(
        "jest.mock<typeof import('react-on-rails-pro')>('react-on-rails-pro', () => ({}));\n"
      )
    end

    it "does not rewrite bare or non-jest/vi importActual/importMock calls" do
      # importActual/importMock are only `vi.importActual` / `vi.importMock` in Vitest;
      # there is no `import { importActual } from 'vitest'`. A bare or alien-receiver
      # call is therefore not a module specifier and must not be mutated.
      source = <<~JS
        const real = await importActual('react-on-rails');
        const fake = importMock('react-on-rails/client');
        const srv = server.importActual('react-on-rails');
      JS

      rewritten = generator.send(:rewrite_react_on_rails_module_specifiers, source)

      expect(rewritten).to eq(source)
    end

    it "does not rewrite mock helpers on alien receivers" do
      source = <<~JS
        myJest.mock('react-on-rails', factory);
        server.mock('react-on-rails', factory);
        vitest.mock('react-on-rails');
        mock('react-on-rails', factory);
      JS

      rewritten = generator.send(:rewrite_react_on_rails_module_specifiers, source)

      expect(rewritten).to eq(source)
    end

    it "does not rewrite mock helpers already targeting the Pro package" do
      source = <<~JS
        jest.mock('react-on-rails-pro', () => ({}));
        vi.mock('react-on-rails-pro/client', () => ({}));
        const m = vi.importActual('react-on-rails-pro');
      JS

      rewritten = generator.send(:rewrite_react_on_rails_module_specifiers, source)

      expect(rewritten).to eq(source)
    end

    it "rewrites TypeScript declare module declarations targeting the base package" do
      source = <<~TS
        declare module 'react-on-rails' {
          export function register(c: Record<string, unknown>): void;
        }

        declare module 'react-on-rails/client' {
          export * from 'react-on-rails-pro';
        }
      TS

      rewritten = generator.send(:rewrite_react_on_rails_module_specifiers, source)

      expect(rewritten).to include("declare module 'react-on-rails-pro' {")
      expect(rewritten).to include("declare module 'react-on-rails-pro/client' {")
      expect(rewritten).not_to match(/declare module ['"]react-on-rails['"]/)
    end

    it "rewrites export-prefixed declare module declarations" do
      source = <<~TS
        export declare module 'react-on-rails' {
          export function register(c: Record<string, unknown>): void;
        }
      TS

      rewritten = generator.send(:rewrite_react_on_rails_module_specifiers, source)

      expect(rewritten).to include("export declare module 'react-on-rails-pro' {")
    end

    it "rewrites indented declare module declarations and nested base-package exports together" do
      source = <<~TS
        declare module 'react-on-rails/client' {
          export * from 'react-on-rails';
          export { default as ReactOnRails } from 'react-on-rails';
        }
      TS

      rewritten = generator.send(:rewrite_react_on_rails_module_specifiers, source)

      expect(rewritten).to include("declare module 'react-on-rails-pro/client' {")
      expect(rewritten).to include("export * from 'react-on-rails-pro';")
      expect(rewritten).to include("export { default as ReactOnRails } from 'react-on-rails-pro';")
      expect(rewritten).not_to match(/['"]react-on-rails['"]/)
    end

    it "does not rewrite declare module declarations already targeting the Pro package" do
      source = <<~TS
        declare module 'react-on-rails-pro' { }
        declare module 'react-on-rails-pro/client' { }
      TS

      rewritten = generator.send(:rewrite_react_on_rails_module_specifiers, source)

      expect(rewritten).to eq(source)
    end
  end

  describe "#pro_flag_specified_for_context?" do
    let(:generator) { described_class.new }

    it "delegates to use_pro? for consistent Pro/RSC flag semantics" do
      allow(generator).to receive(:use_pro?).and_return(true)

      expect(generator.send(:pro_flag_specified_for_context?)).to be(true)
      expect(generator).to have_received(:use_pro?)
    end
  end

  # Integration test for standalone happy path
  # Uses before (not before(:all)) to allow mocking the Pro gem check

  context "when prerequisites are met" do
    before do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails_pro"
      RUBY
      simulate_npm_files(package_json: true)
      # Simulate base React on Rails installed
      simulate_existing_file("config/initializers/react_on_rails.rb", "ReactOnRails.configure {}")
      # Simulate generated bin/dev Procfiles exist for appending
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_existing_file("Procfile.dev-static-assets", "web: bin/rails server\njs: bin/shakapacker-watch --watch\n")
      simulate_existing_file("Procfile.dev-prod-assets", "rails: bundle exec rails s\n")
      # Simulate base webpack configs (what base install generates without --pro)
      simulate_base_webpack_files
      # Mock Pro gem as installed
      allow(Gem).to receive(:loaded_specs).and_return({ "react_on_rails_pro" => double })

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    include_examples "pro_common_files"

    it "Pro initializer does not include RSC config (RSC generator adds it)" do
      assert_file "config/initializers/react_on_rails_pro.rb" do |content|
        expect(content).not_to include("enable_rsc_support")
        expect(content).not_to include("rsc_bundle_js_file")
      end
    end

    describe "webpack config transforms" do
      it "adds extractLoader function" do
        assert_file "config/webpack/serverWebpackConfig.js" do |content|
          expect(content).to include("function extractLoader(rule, loaderName)")
        end
      end

      it "enables libraryTarget commonjs2" do
        assert_file "config/webpack/serverWebpackConfig.js" do |content|
          expect(content).to include("libraryTarget: 'commonjs2',")
          expect(content).not_to include("// libraryTarget: 'commonjs2',")
        end
      end

      it "sets target to node with clean comments" do
        assert_file "config/webpack/serverWebpackConfig.js" do |content|
          expect(content).to include("serverWebpackConfig.target = 'node';")
          expect(content).not_to include("// serverWebpackConfig.target = 'node'")
        end
      end

      it "disables node polyfills" do
        assert_file "config/webpack/serverWebpackConfig.js" do |content|
          expect(content).to include("serverWebpackConfig.node = false;")
        end
      end

      it "adds Babel SSR caller setup" do
        assert_file "config/webpack/serverWebpackConfig.js" do |content|
          expect(content).to include("babelLoader.options.caller = { ssr: true };")
        end
      end

      it "changes module.exports to object style" do
        assert_file "config/webpack/serverWebpackConfig.js" do |content|
          expect(content).to include("module.exports = {")
          expect(content).to include("default: configureServer,")
          expect(content).to include("extractLoader,")
        end
      end

      it "updates ServerClientOrBoth.js to destructured import" do
        assert_file "config/webpack/ServerClientOrBoth.js" do |content|
          expect(content).to include("{ default: serverWebpackConfig }")
          expect(content).not_to match(/^const serverWebpackConfig = require/)
        end
      end
    end
  end

  context "when prerequisites are met and a legacy client/node-renderer.js exists" do
    let(:legacy_renderer_content) { "// customized legacy renderer\n" }

    before do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails_pro"
      RUBY
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails.rb", "ReactOnRails.configure {}")
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_base_webpack_files
      simulate_existing_file("client/node-renderer.js", legacy_renderer_content)
      allow(Gem).to receive(:loaded_specs).and_return({ "react_on_rails_pro" => double })

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "does not create renderer/node-renderer.js" do
      expect(File.exist?(File.join(destination_root, "renderer/node-renderer.js"))).to be false
    end

    it "preserves the legacy client/node-renderer.js" do
      expect(File.read(File.join(destination_root, "client/node-renderer.js"))).to eq(legacy_renderer_content)
    end

    it "does not add a node-renderer entry to Procfile.dev" do
      expect(File.read(File.join(destination_root, "Procfile.dev"))).not_to include("node-renderer:")
    end
  end

  context "when creating the Node Renderer migration hint for a legacy renderer" do
    let(:generator) { described_class.new }

    before do
      prepare_destination
      allow(generator).to receive(:destination_root).and_return(destination_root)
      allow(generator).to receive(:say)
      simulate_existing_file("client/node-renderer.js", "// customized legacy renderer\n")
      allow(ReactOnRails::NodeRendererProcfile).to receive(:command_for)
        .with("Procfile.dev")
        .and_return("node-renderer: CUSTOM_SHARED_COMMAND")
    end

    it "uses the shared default Procfile command" do
      generator.send(:create_node_renderer)

      expect(generator).to have_received(:say).with("      node-renderer: CUSTOM_SHARED_COMMAND", :yellow)
    end
  end

  context "when renderer/node-renderer.js already exists but Procfile.dev lacks node-renderer entry" do
    let(:existing_renderer_content) { "// existing renderer\n" }

    before do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails_pro"
      RUBY
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails.rb", "ReactOnRails.configure {}")
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_base_webpack_files
      simulate_existing_file("renderer/node-renderer.js", existing_renderer_content)
      allow(Gem).to receive(:loaded_specs).and_return({ "react_on_rails_pro" => double })

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "preserves the existing renderer/node-renderer.js" do
      expect(File.read(File.join(destination_root, "renderer/node-renderer.js"))).to eq(existing_renderer_content)
    end

    it "adds the node-renderer entry to Procfile.dev" do
      expect(File.read(File.join(destination_root, "Procfile.dev")))
        .to include(
          "node-renderer: RENDERER_LOG_LEVEL=${RENDERER_LOG_LEVEL:-debug} " \
          "RENDERER_PORT=${RENDERER_PORT:-3800} node renderer/node-renderer.js"
        )
    end
  end

  context "when renderer/node-renderer.js exists and Procfile.dev has a stale legacy node-renderer entry" do
    let(:existing_renderer_content) { "// existing renderer\n" }
    let(:stale_procfile) do
      "rails: bin/rails s\n" \
        "node-renderer: RENDERER_LOG_LEVEL=debug RENDERER_PORT=3800 node client/node-renderer.js\n"
    end

    before do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails_pro"
      RUBY
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails.rb", "ReactOnRails.configure {}")
      simulate_existing_file("Procfile.dev", stale_procfile)
      simulate_base_webpack_files
      simulate_existing_file("renderer/node-renderer.js", existing_renderer_content)
      allow(Gem).to receive(:loaded_specs).and_return({ "react_on_rails_pro" => double })

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "does not append a second node-renderer entry to Procfile.dev" do
      expect(File.read(File.join(destination_root, "Procfile.dev")).scan(/^node-renderer:/).size).to eq(1)
    end

    it "leaves the stale legacy entry untouched" do
      expect(File.read(File.join(destination_root, "Procfile.dev")))
        .to include("node-renderer: RENDERER_LOG_LEVEL=debug RENDERER_PORT=3800 node client/node-renderer.js")
    end
  end

  context "when Procfile.dev already contains the new renderer/node-renderer.js entry" do
    let(:existing_renderer_content) { "// existing renderer\n" }
    let(:current_procfile) do
      "rails: bin/rails s\n" \
        "node-renderer: RENDERER_LOG_LEVEL=debug RENDERER_PORT=3800 node renderer/node-renderer.js\n"
    end

    before do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails_pro"
      RUBY
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails.rb", "ReactOnRails.configure {}")
      simulate_existing_file("Procfile.dev", current_procfile)
      simulate_base_webpack_files
      simulate_existing_file("renderer/node-renderer.js", existing_renderer_content)
      allow(Gem).to receive(:loaded_specs).and_return({ "react_on_rails_pro" => double })

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "leaves Procfile.dev unchanged" do
      expect(File.read(File.join(destination_root, "Procfile.dev"))).to eq(current_procfile)
    end
  end

  context "when Procfile.dev uses a ./ prefix on the renderer command" do
    let(:existing_renderer_content) { "// existing renderer\n" }
    let(:current_procfile) do
      "rails: bin/rails s\n" \
        "node-renderer: RENDERER_LOG_LEVEL=debug RENDERER_PORT=3800 node ./renderer/node-renderer.js\n"
    end

    before do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails_pro"
      RUBY
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails.rb", "ReactOnRails.configure {}")
      simulate_existing_file("Procfile.dev", current_procfile)
      simulate_base_webpack_files
      simulate_existing_file("renderer/node-renderer.js", existing_renderer_content)
      allow(Gem).to receive(:loaded_specs).and_return({ "react_on_rails_pro" => double })

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "treats the ./-prefixed command as already present and leaves Procfile.dev unchanged" do
      expect(File.read(File.join(destination_root, "Procfile.dev"))).to eq(current_procfile)
    end
  end

  context "when Procfile.dev has only a commented-out renderer entry" do
    let(:existing_renderer_content) { "// existing renderer\n" }
    let(:commented_procfile) do
      "rails: bin/rails s\n" \
        "# node-renderer: RENDERER_LOG_LEVEL=debug RENDERER_PORT=3800 node renderer/node-renderer.js\n"
    end

    before do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails_pro"
      RUBY
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails.rb", "ReactOnRails.configure {}")
      simulate_existing_file("Procfile.dev", commented_procfile)
      simulate_base_webpack_files
      simulate_existing_file("renderer/node-renderer.js", existing_renderer_content)
      allow(Gem).to receive(:loaded_specs).and_return({ "react_on_rails_pro" => double })

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "adds a live node-renderer entry instead of treating the comment as configured" do
      procfile = File.read(File.join(destination_root, "Procfile.dev"))
      expect(procfile.scan(/^[ \t]*node-renderer:/).size).to eq(1)
      expect(procfile)
        .to include(
          "node-renderer: RENDERER_LOG_LEVEL=${RENDERER_LOG_LEVEL:-debug} " \
          "RENDERER_PORT=${RENDERER_PORT:-3800} node renderer/node-renderer.js"
        )
    end
  end

  context "when legacy client/node-renderer.js exists and Procfile.dev still launches it" do
    let(:legacy_renderer_content) { "// customized legacy renderer\n" }
    let(:stale_procfile) do
      "rails: bin/rails s\n" \
        "node-renderer: RENDERER_LOG_LEVEL=debug RENDERER_PORT=3800 node client/node-renderer.js\n"
    end

    before do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails_pro"
      RUBY
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails.rb", "ReactOnRails.configure {}")
      simulate_existing_file("Procfile.dev", stale_procfile)
      simulate_base_webpack_files
      simulate_existing_file("client/node-renderer.js", legacy_renderer_content)
      allow(Gem).to receive(:loaded_specs).and_return({ "react_on_rails_pro" => double })

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "surfaces a pointed warning about the stale legacy Procfile line" do
      expect(GeneratorMessages.messages.join("\n"))
        .to include("Procfile.dev still launches the legacy client/node-renderer.js")
    end

    it "leaves the stale legacy Procfile entry untouched" do
      expect(File.read(File.join(destination_root, "Procfile.dev"))).to eq(stale_procfile)
    end
  end

  context "when legacy client/node-renderer.js exists and every Procfile variant still launches it" do
    let(:legacy_renderer_content) { "// customized legacy renderer\n" }
    let(:stale_line) do
      "node-renderer: RENDERER_LOG_LEVEL=debug RENDERER_PORT=3800 node client/node-renderer.js\n"
    end
    let(:stale_dev_procfile) { "rails: bin/rails s\n#{stale_line}" }
    let(:stale_static_procfile) { "web: bin/rails s\n#{stale_line}" }
    let(:stale_prod_procfile) { "rails: bin/rails s\n#{stale_line}" }

    before do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails_pro"
      RUBY
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails.rb", "ReactOnRails.configure {}")
      simulate_existing_file("Procfile.dev", stale_dev_procfile)
      simulate_existing_file("Procfile.dev-static-assets", stale_static_procfile)
      simulate_existing_file("Procfile.dev-prod-assets", stale_prod_procfile)
      simulate_base_webpack_files
      simulate_existing_file("client/node-renderer.js", legacy_renderer_content)
      allow(Gem).to receive(:loaded_specs).and_return({ "react_on_rails_pro" => double })

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "warns per stale Procfile variant so users see each line that needs updating" do
      joined = GeneratorMessages.messages.join("\n")
      expect(joined).to include("Procfile.dev still launches the legacy client/node-renderer.js")
      expect(joined).to include("Procfile.dev-static-assets still launches the legacy client/node-renderer.js")
      expect(joined).to include("Procfile.dev-prod-assets still launches the legacy client/node-renderer.js")
    end

    it "leaves every stale legacy Procfile entry untouched" do
      expect(File.read(File.join(destination_root, "Procfile.dev"))).to eq(stale_dev_procfile)
      expect(File.read(File.join(destination_root, "Procfile.dev-static-assets"))).to eq(stale_static_procfile)
      expect(File.read(File.join(destination_root, "Procfile.dev-prod-assets"))).to eq(stale_prod_procfile)
    end
  end

  context "when legacy client/node-renderer.js exists and Procfile.dev only comments the legacy command" do
    let(:legacy_renderer_content) { "// customized legacy renderer\n" }
    let(:commented_legacy_procfile) do
      "rails: bin/rails s\n" \
        "# node-renderer: RENDERER_LOG_LEVEL=debug RENDERER_PORT=3800 node client/node-renderer.js\n"
    end

    before do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails_pro"
      RUBY
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails.rb", "ReactOnRails.configure {}")
      simulate_existing_file("Procfile.dev", commented_legacy_procfile)
      simulate_base_webpack_files
      simulate_existing_file("client/node-renderer.js", legacy_renderer_content)
      allow(Gem).to receive(:loaded_specs).and_return({ "react_on_rails_pro" => double })

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "does not report a stale legacy entry warning for commented lines" do
      expect(GeneratorMessages.messages.join("\n"))
        .not_to include("Procfile.dev still launches the legacy client/node-renderer.js")
    end
  end

  context "when both renderer/node-renderer.js and legacy client/node-renderer.js exist" do
    let(:existing_renderer_content) { "// existing renderer\n" }
    let(:legacy_renderer_content) { "// customized legacy renderer\n" }

    before do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails_pro"
      RUBY
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails.rb", "ReactOnRails.configure {}")
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_base_webpack_files
      simulate_existing_file("renderer/node-renderer.js", existing_renderer_content)
      simulate_existing_file("client/node-renderer.js", legacy_renderer_content)
      allow(Gem).to receive(:loaded_specs).and_return({ "react_on_rails_pro" => double })

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "preserves the existing renderer/node-renderer.js" do
      expect(File.read(File.join(destination_root, "renderer/node-renderer.js"))).to eq(existing_renderer_content)
    end

    it "preserves the legacy client/node-renderer.js" do
      expect(File.read(File.join(destination_root, "client/node-renderer.js"))).to eq(legacy_renderer_content)
    end

    it "adds exactly one renderer/ node-renderer entry to Procfile.dev" do
      procfile = File.read(File.join(destination_root, "Procfile.dev"))
      expect(procfile)
        .to include(
          "node-renderer: RENDERER_LOG_LEVEL=${RENDERER_LOG_LEVEL:-debug} " \
          "RENDERER_PORT=${RENDERER_PORT:-3800} node renderer/node-renderer.js"
        )
      expect(procfile.scan(/^node-renderer:/).size).to eq(1)
    end
  end

  context "when server webpack has only libraryTarget uncommented" do
    before do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails_pro"
      RUBY
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails.rb", "ReactOnRails.configure {}")
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_base_webpack_files
      allow(Gem).to receive(:loaded_specs).and_return({ "react_on_rails_pro" => double })

      server_webpack_path = File.join(destination_root, "config/webpack/serverWebpackConfig.js")
      partially_updated_content = File.read(server_webpack_path)
                                      .sub("// libraryTarget: 'commonjs2',", "libraryTarget: 'commonjs2',")
      File.write(server_webpack_path, partially_updated_content)

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "applies remaining Pro transforms instead of skipping as fully configured" do
      assert_file "config/webpack/serverWebpackConfig.js" do |content|
        expect(content).to include("function extractLoader")
        expect(content).to include("babelLoader.options.caller = { ssr: true };")
        expect(content).to include("serverWebpackConfig.target = 'node';")
        expect(content).to include("serverWebpackConfig.node = false;")
        expect(content).to include("module.exports = {")
      end

      assert_file "config/webpack/ServerClientOrBoth.js" do |content|
        expect(content).to include("{ default: serverWebpackConfig }")
      end
    end
  end

  # Rspack variant — verifies that standalone Pro generator writes to config/rspack/
  # when it detects an existing rspack project via config/shakapacker.yml.
  # ProGenerator has no --rspack option; detection is via rspack_configured_in_project?.
  # Uses before (not before(:all)) to allow mocking the Pro gem check.

  # Unit tests for using_rspack? on ProGenerator specifically.
  # ProGenerator does not declare --rspack, so options[:rspack] is always nil and
  # rspack_configured_in_project? (YAML detection) is the only real code path.
  # Integration tests above exercise this end-to-end; these unit tests make the
  # detection logic explicit on the class that actually uses it.

  describe "#using_rspack?" do
    context "when shakapacker.yml has assets_bundler: rspack" do
      let(:generator) { described_class.new }

      before do
        prepare_destination
        simulate_rspack_shakapacker_yml
        allow(generator).to receive(:destination_root).and_return(destination_root)
        allow(Gem).to receive(:loaded_specs).and_return({ "react_on_rails_pro" => double })
      end

      it "returns true via YAML fallback (no --rspack option available on ProGenerator)" do
        expect(generator.send(:using_rspack?)).to be true
      end
    end

    context "when no shakapacker.yml exists" do
      let(:generator) { described_class.new }

      before do
        prepare_destination
        allow(generator).to receive(:destination_root).and_return(destination_root)
        allow(Gem).to receive(:loaded_specs).and_return({ "react_on_rails_pro" => double })
      end

      it "returns false" do
        expect(generator.send(:using_rspack?)).to be false
      end
    end
  end

  context "when prerequisites are met on an existing rspack project" do
    before do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails_pro"
      RUBY
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails.rb", "ReactOnRails.configure {}")
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      # simulate_rspack_base_webpack_files also creates the rspack shakapacker.yml
      # so rspack_configured_in_project? returns true (no --rspack flag available)
      simulate_rspack_base_webpack_files
      allow(Gem).to receive(:loaded_specs).and_return({ "react_on_rails_pro" => double })

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    describe "Pro webpack config transforms in config/rspack/" do
      it "applies Pro transforms to serverWebpackConfig in config/rspack/" do
        assert_file "config/rspack/serverWebpackConfig.js" do |content|
          expect(content).to include("libraryTarget: 'commonjs2',")
          expect(content).to include("function extractLoader")
          expect(content).to include("serverWebpackConfig.target = 'node';")
          expect(content).to include("module.exports = {")
        end
      end

      it "updates ServerClientOrBoth.js to destructured import in config/rspack/" do
        assert_file "config/rspack/ServerClientOrBoth.js" do |content|
          expect(content).to include("{ default: serverWebpackConfig }")
        end
      end
    end
  end
end

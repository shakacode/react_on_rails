# frozen_string_literal: true

require_relative "../support/generator_spec_helper"

RSpec.describe GeneratorHelper, type: :generator do
  include described_class

  # The module is exercised in isolation here (without Thor::Shell),
  # so provide minimal shell methods used by generator helpers.
  def say(message = "", color = nil, force_new_line = nil)
    say_calls << { message:, color:, force_new_line: }
  end

  def say_calls
    @say_calls ||= []
  end

  def say_status(status, message, log_status = nil)
    say_status_calls << { status:, message:, log_status: }
  end

  def say_status_calls
    @say_status_calls ||= []
  end

  def shell
    @shell ||= Thor::Shell::Color.new
  end

  # GeneratorHelper methods expect an options hash as provided by Thor generators.
  def options
    @options ||= {}
  end

  def reset_shakapacker_memoization!
    %i[@shakapacker_source_path @shakapacker_source_entry_path].each do |ivar|
      remove_instance_variable(ivar) if instance_variable_defined?(ivar)
    end
  end

  let(:destination_root) { File.expand_path("../dummy-for-generators", __dir__) }

  describe "#print_generator_messages" do
    before do
      GeneratorMessages.clear
      say_calls.clear
      say_status_calls.clear
    end

    after do
      GeneratorMessages.clear
      say_calls.clear
      say_status_calls.clear
    end

    it "strips ANSI escape sequences when no_color is enabled" do
      allow(self).to receive(:shell).and_return(Thor::Shell::Basic.new)
      GeneratorMessages.add_warning("Needs attention")

      print_generator_messages

      expect(say_calls.first[:message]).to eq("WARNING: Needs attention")
      expect(say_calls.first[:message]).not_to match(/\e\[/)
    end

    it "keeps ANSI escape sequences when no_color is disabled" do
      allow(self).to receive(:shell).and_return(Thor::Shell::Color.new)
      GeneratorMessages.add_warning("Needs attention")
      raw_message = GeneratorMessages.messages.first.to_s

      print_generator_messages

      expect(say_calls.first[:message].to_s).to eq(raw_message)
    end
  end

  describe "#add_npm_dependencies" do
    context "when package_json gem is available" do
      let(:mock_package_json) { instance_double(PackageJson) }
      let(:mock_manager) { instance_double("PackageJson::Manager") } # rubocop:disable RSpec/VerifiedDoubleReference

      before do
        # Stub PackageJson constant so instance_double can reference it
        stub_const("PackageJson", Class.new) unless defined?(PackageJson)

        allow(self).to receive(:package_json).and_return(mock_package_json)
        allow(mock_package_json).to receive(:manager).and_return(mock_manager)
      end

      context "when adding regular dependencies" do
        it "calls manager.add with exact: true" do
          packages = %w[react react-dom]
          allow(mock_manager).to receive(:add).with(packages, exact: true).and_return(true)

          result = add_npm_dependencies(packages)
          expect(mock_manager).to have_received(:add).with(packages, exact: true)
          expect(result).to be true
        end
      end

      context "when adding dev dependencies" do
        it "calls manager.add with type: :dev and exact: true" do
          packages = ["@types/react", "@types/react-dom"]
          allow(mock_manager).to receive(:add).with(packages, type: :dev, exact: true).and_return(true)

          result = add_npm_dependencies(packages, dev: true)
          expect(mock_manager).to have_received(:add).with(packages, type: :dev, exact: true)
          expect(result).to be true
        end
      end

      context "when package manager add returns false" do
        it "returns false so callers can fall back" do
          packages = ["react-on-rails-rsc@99.99.99"]

          allow(mock_manager).to receive(:add).with(packages, exact: true).and_return(false)

          result = add_npm_dependencies(packages)
          expect(mock_manager).to have_received(:add).with(packages, exact: true)
          expect(result).to be false
        end
      end

      context "when package manager add returns nil" do
        it "treats nil as success for side-effect-only package managers" do
          packages = %w[react react-dom]

          allow(mock_manager).to receive(:add).with(packages, exact: true).and_return(nil)

          result = add_npm_dependencies(packages)
          expect(mock_manager).to have_received(:add).with(packages, exact: true)
          expect(result).to be true
        end
      end

      context "when package_json gem raises an error" do
        it "returns false and logs warnings via say_status" do
          packages = ["react"]

          allow(mock_manager).to receive(:add).and_raise(StandardError, "Installation failed")

          result = add_npm_dependencies(packages)
          expect(result).to be false
          expect(say_status_calls).to include(a_hash_including(message: a_string_matching(/Could not add packages/)))
          expect(say_status_calls)
            .to include(a_hash_including(message: "Will fall back to direct package manager commands."))
        end
      end
    end

    context "when package_json gem is not available" do
      before do
        allow(self).to receive(:package_json).and_return(nil)
      end

      it "returns false" do
        packages = ["react"]

        result = add_npm_dependencies(packages)
        expect(result).to be false
      end
    end
  end

  describe "#package_json" do
    context "when PackageJson is available" do
      before do
        stub_const("PackageJson", Class.new do
          def self.read
            new
          end
        end)
      end

      it "returns a PackageJson instance" do
        result = package_json
        expect(result).to be_a(PackageJson)
      end

      it "memoizes the result" do
        first_call = package_json
        second_call = package_json
        expect(first_call).to equal(second_call)
      end
    end

    # NOTE: Testing the LoadError path is difficult because PackageJson is already loaded
    # in the test environment. The StandardError path below covers the error handling logic.

    context "when package.json file cannot be read" do
      before do
        stub_const("PackageJson", Class.new do
          def self.read
            raise StandardError, "File not found"
          end
        end)
      end

      it "returns nil and logs warnings via say_status" do
        result = package_json

        expect(result).to be_nil
        expect(say_status_calls).to include(
          a_hash_including(message: a_string_matching(/Could not read package\.json/))
        )
        expect(say_status_calls).to include(
          a_hash_including(message: "This is normal before Shakapacker creates the package.json file.")
        )
      end
    end
  end

  describe "#parse_shakapacker_yml_content" do
    let(:aliased_config) do
      <<~YAML
        default: &default
          precompile_hook: bin/shakapacker-precompile-hook

        test:
          <<: *default
      YAML
    end

    it "fails closed instead of parsing aliased configs without alias support" do
      allow(self).to receive(:yaml_safe_load_supports_aliases?).and_return(true)
      allow(YAML).to receive(:safe_load) do |_content, aliases: false, **_kwargs|
        raise ArgumentError, "unknown keyword: :aliases" if aliases

        {
          "default" => { "precompile_hook" => "bin/shakapacker-precompile-hook" },
          "test" => { "precompile_hook" => "bin/shakapacker-precompile-hook" }
        }
      end

      expect(parse_shakapacker_yml_content(aliased_config)).to eq({})
    end

    it "warns and raises when shakapacker.yml ERB cannot be evaluated" do
      expect do
        parse_shakapacker_yml_content(<<~YAML)
          default:
            precompile_hook: <%= missing_local %>
        YAML
      end.to raise_error(%r{Could not evaluate ERB in config/shakapacker\.yml})

      expect(say_status_calls).to include(
        a_hash_including(message: a_string_matching(%r{Could not evaluate ERB in config/shakapacker\.yml}))
      )
      expect(say_status_calls).to include(
        a_hash_including(message: a_string_matching(/Skipping generated precompile_hook updates/))
      )
    end

    it "keeps file-level parsing tolerant when shakapacker.yml ERB cannot be evaluated" do
      shakapacker_yml_path = File.join(destination_root, "config/shakapacker.yml")
      FileUtils.mkdir_p(File.dirname(shakapacker_yml_path))
      File.write(shakapacker_yml_path, <<~YAML)
        default:
          javascript_transpiler: <%= missing_local %>
      YAML

      expect(parse_shakapacker_yml(shakapacker_yml_path)).to eq({})
      expect(say_status_calls).to include(
        a_hash_including(message: a_string_matching(%r{Could not evaluate ERB in config/shakapacker\.yml}))
      )
    ensure
      FileUtils.rm_f(shakapacker_yml_path)
    end
  end

  describe "#safe_generator_destination_path" do
    let(:default_path) { "app/javascript" }

    it "keeps safe relative paths" do
      expect(safe_generator_destination_path("client/app", default: default_path)).to eq("client/app")
    end

    it "relativizes absolute paths inside the destination root" do
      absolute_path = File.join(destination_root, "client/app")

      expect(safe_generator_destination_path(absolute_path, default: default_path)).to eq("client/app")
    end

    it "falls back for paths outside the destination root" do
      expect(safe_generator_destination_path("/tmp/client/app", default: default_path)).to eq(default_path)
    end

    it "falls back for absolute paths that relativize outside the destination root" do
      outside_destination_path = File.expand_path("../client/app", destination_root)

      expect(safe_generator_destination_path(outside_destination_path, default: default_path)).to eq(default_path)
    end

    it "falls back for degenerate or traversing paths" do
      expect(safe_generator_destination_path(".", default: default_path)).to eq(default_path)
      expect(safe_generator_destination_path("..", default: default_path)).to eq(default_path)
      expect(safe_generator_destination_path("../client/app", default: default_path)).to eq(default_path)
    end

    it "uses an empty sentinel for Shakapacker root entry paths" do
      expect(safe_generator_destination_path("/", default: "packs", allow_root: true)).to eq("")
    end
  end

  describe "#shakapacker_stylesheet_path" do
    let(:shakapacker_yml_path) { File.join(destination_root, "config/shakapacker.yml") }

    before do
      FileUtils.mkdir_p(File.dirname(shakapacker_yml_path))
      File.write(shakapacker_yml_path, <<~YAML)
        default:
          source_path: app/javascript

        development:
          source_path: client/app
      YAML
      reset_shakapacker_memoization!
    end

    after do
      FileUtils.rm_rf(File.join(destination_root, "config"))
      reset_shakapacker_memoization!
    end

    it "places generated demo stylesheets under the configured Shakapacker source path" do
      expect(shakapacker_stylesheet_path("application.css")).to eq("client/app/stylesheets/application.css")
    end
  end

  describe "#shakapacker_stylesheet_path with malformed Shakapacker config" do
    let(:shakapacker_yml_path) { File.join(destination_root, "config/shakapacker.yml") }

    before do
      FileUtils.mkdir_p(File.dirname(shakapacker_yml_path))
      File.write(shakapacker_yml_path, "default:\n  source_path: [unterminated\n")
      reset_shakapacker_memoization!
    end

    after do
      FileUtils.rm_rf(File.join(destination_root, "config"))
      reset_shakapacker_memoization!
    end

    it "falls back to the default generated stylesheet path" do
      expect(shakapacker_stylesheet_path("application.css")).to eq("app/javascript/stylesheets/application.css")
    end
  end

  describe "#shakapacker_entrypoint_path" do
    let(:shakapacker_yml_path) { File.join(destination_root, "config/shakapacker.yml") }

    before do
      FileUtils.mkdir_p(File.dirname(shakapacker_yml_path))
      File.write(shakapacker_yml_path, <<~YAML)
        development:
          source_path: client/app
          source_entry_path: /
      YAML
      reset_shakapacker_memoization!
    end

    after do
      FileUtils.rm_rf(File.join(destination_root, "config"))
      reset_shakapacker_memoization!
    end

    it "places root entrypoints directly under source_path without a double slash" do
      expect(shakapacker_entrypoint_path("server-bundle.js")).to eq("client/app/server-bundle.js")
    end

    it "raises a clear error for blank entrypoint filenames" do
      expect { shakapacker_entrypoint_path("") }.to raise_error(ArgumentError, "filename must be present")
    end
  end

  describe "#relative_stylesheet_import_path" do
    let(:shakapacker_yml_path) { File.join(destination_root, "config/shakapacker.yml") }

    before do
      FileUtils.mkdir_p(File.dirname(shakapacker_yml_path))
      File.write(shakapacker_yml_path, <<~YAML)
        development:
          source_path: client/app
      YAML
      reset_shakapacker_memoization!
    end

    after do
      FileUtils.rm_rf(File.join(destination_root, "config"))
      reset_shakapacker_memoization!
    end

    it "computes the stylesheet import path from the generated entry file" do
      expect(relative_stylesheet_import_path("client/app/src/HelloServer/components/LikeButton.jsx"))
        .to eq("../../../stylesheets/application.css")
    end

    it "adjusts when the generated entry moves deeper under the source path" do
      expect(relative_stylesheet_import_path("client/app/src/HelloServer/components/nested/LikeButton.jsx"))
        .to eq("../../../../stylesheets/application.css")
    end

    it "rejects entry paths outside the generator destination" do
      expect { relative_stylesheet_import_path("../../outside/LikeButton.jsx") }
        .to raise_error(ArgumentError, "entry_path must stay inside the generator destination")
    end
  end

  describe "Tailwind layout pack helpers" do
    let(:shakapacker_yml_path) { File.join(destination_root, "config/shakapacker.yml") }

    after do
      FileUtils.rm_rf(File.join(destination_root, "config"))
      reset_shakapacker_memoization!
    end

    it "uses the default Shakapacker entry path for the Tailwind pack" do
      expect(tailwind_pack_path).to eq("app/javascript/packs/react_on_rails_tailwind.js")
      expect(tailwind_stylesheet_path).to eq("app/javascript/stylesheets/application.css")
      expect(relative_tailwind_stylesheet_import_path).to eq("../stylesheets/application.css")
    end

    it "prefixes same-directory Tailwind stylesheet imports for root entry paths" do
      FileUtils.mkdir_p(File.dirname(shakapacker_yml_path))
      File.write(shakapacker_yml_path, <<~YAML)
        development:
          source_path: client/app
          source_entry_path: /
      YAML
      reset_shakapacker_memoization!

      expect(tailwind_pack_path).to eq("client/app/react_on_rails_tailwind.js")
      expect(tailwind_stylesheet_path).to eq("client/app/stylesheets/application.css")
      expect(relative_tailwind_stylesheet_import_path).to eq("./stylesheets/application.css")
    end

    it "scans Rails app for the default generated stylesheet location" do
      expect(tailwind_css_source_directives).to eq('@import "tailwindcss" source("../..");')
    end

    it "uses explicit Tailwind source roots when Shakapacker source_path is outside Rails app" do
      FileUtils.mkdir_p(File.dirname(shakapacker_yml_path))
      File.write(shakapacker_yml_path, <<~YAML)
        development:
          source_path: client/app
          source_entry_path: entrypoints
      YAML
      reset_shakapacker_memoization!

      expect(tailwind_css_source_directives).to eq(<<~CSS.strip)
        @import "tailwindcss" source(none);
        @source "..";
        @source "../../../app";
      CSS
    end

    it "escapes quoted Tailwind source paths with JSON string quoting" do
      expect(tailwind_source_statement(%(../quoted"path\\dir)))
        .to eq('@source "../quoted\\"path\\\\dir";')
    end

    it "rejects control characters in Tailwind source paths" do
      expect { tailwind_source_statement("../bad\npath") }
        .to raise_error(ArgumentError, "Tailwind source paths cannot contain control characters")
    end

    it "rejects Unicode line separators in Tailwind source paths" do
      ["\u2028", "\u2029"].each do |separator|
        expect { tailwind_source_statement("../bad#{separator}path") }
          .to raise_error(ArgumentError, "Tailwind source paths cannot contain control characters")
      end
    end
  end

  describe "#active_precompile_hook_configured?" do
    it "treats quoted and unquoted command strings beside a placeholder as active" do
      expect(active_precompile_hook_configured?(<<~YAML)).to be(true)
        default:
          precompile_hook: bin/shakapacker-precompile-hook
          # precompile_hook: ~
      YAML

      expect(active_precompile_hook_configured?(<<~YAML)).to be(true)
        default:
          precompile_hook: 'bin/shakapacker-precompile-hook'
          # precompile_hook: ~
      YAML
    end

    it "treats unquoted YAML null and boolean scalars as inactive" do
      %w[
        ~ null Null NULL
        false False FALSE no No NO off Off OFF
        true True TRUE yes Yes YES on On ON
      ].each do |inactive_value|
        expect(active_precompile_hook_configured?(<<~YAML)).to be(false), inactive_value
          default:
            precompile_hook: #{inactive_value}
            # precompile_hook: ~
        YAML
      end
    end

    it "treats quoted boolean-like raw scalars as active commands when YAML parsing falls back" do
      ['"false"', "'false'", '"true"', "'true'", '"no"', "'off'"].each do |quoted_value|
        expect(active_precompile_hook_configured?(<<~YAML)).to be(true), quoted_value
          default:
            released_at: 2026-06-05
            precompile_hook: #{quoted_value}
            # precompile_hook: ~
        YAML
      end
    end

    it "preserves hash characters inside quoted raw hook values when YAML parsing falls back" do
      expect(active_precompile_hook_configured?(<<~YAML)).to be(true)
        default:
          released_at: 2026-06-05
          precompile_hook: "bin/custom#hook" # trailing comment
          # precompile_hook: ~
      YAML
    end

    it "keeps unquoted boolean-like raw scalars inactive when YAML parsing falls back" do
      %w[false true no off].each do |inactive_value|
        expect(active_precompile_hook_configured?(<<~YAML)).to be(false), inactive_value
          default:
            released_at: 2026-06-05
            precompile_hook: #{inactive_value}
            # precompile_hook: ~
        YAML
      end
    end

    it "treats quoted empty scalars as inactive" do
      ['""', "''"].each do |inactive_value|
        expect(active_precompile_hook_configured?(<<~YAML)).to be(false), inactive_value
          default:
            precompile_hook: #{inactive_value}
            # precompile_hook: ~
        YAML
      end
    end

    it "ignores ERB in trailing comments after inactive scalar values" do
      expect(active_precompile_hook_configured?(<<~YAML)).to be(false)
        default:
          precompile_hook: false # previously used <%= "bin/custom-precompile-hook" %>
          # precompile_hook: ~
      YAML
    end

    it "ignores active hooks in sections without a commented placeholder" do
      expect(active_precompile_hook_configured?(<<~YAML)).to be(false)
        default:
          # precompile_hook: ~

        development:
          precompile_hook: bin/development-precompile-hook
      YAML
    end

    it "detects active hooks inherited by sections with a commented placeholder" do
      expect(active_precompile_hook_configured?(<<~YAML)).to be(true)
        default: &default
          precompile_hook: bin/custom-precompile-hook

        test:
          <<: *default
          # precompile_hook: ~
      YAML
    end

    it "detects inherited active hooks after rendering ERB" do
      expect(active_precompile_hook_configured?(<<~YAML)).to be(true)
        default: &default
          precompile_hook: <%= "bin/custom-precompile-hook" %>

        test:
          <<: *default
          # precompile_hook: ~
      YAML
    end

    it "detects inherited active hooks through block merge lists" do
      expect(active_precompile_hook_configured?(<<~YAML)).to be(true)
        default: &default
          precompile_hook: <%= false %>

        test:
          <<:
            - *default
          # precompile_hook: ~
      YAML
    end

    it "warns when an active hook causes placeholder materialization to be skipped" do
      say_status_calls.clear

      expect(active_precompile_hook_configured?(<<~YAML)).to be(true)
        default: &default
          precompile_hook: bin/custom-precompile-hook

        test:
          <<: *default
          # precompile_hook: ~
      YAML

      expect(say_status_calls).to include(
        a_hash_including(message: a_string_matching(/Existing direct or inherited precompile_hook/))
      )
      expect(say_status_calls).to include(
        a_hash_including(message: a_string_matching(/configure remaining sections manually/))
      )
    end

    it "detects inherited active hooks through commented block merge lists" do
      expect(active_precompile_hook_configured?(<<~YAML)).to be(true)
        base: &base
          compile: true

        default: &default
          precompile_hook: <%= false %>

        test:
          <<:
            # Keep base first so later aliases can override it.
            - *base
            - *default
          # precompile_hook: ~
      YAML
    end

    it "honors merge-list precedence when an earlier alias disables a later raw hook" do
      expect(active_precompile_hook_configured?(<<~YAML)).to be(false)
        base: &base
          precompile_hook: false

        default: &default
          precompile_hook: <%= false %>

        test:
          <<:
            - *base
            - *default
          # precompile_hook: ~
      YAML
    end

    it "honors later duplicate merge keys when they disable earlier raw hooks" do
      expect(active_precompile_hook_configured?(<<~YAML)).to be(false)
        default: &default
          precompile_hook: <%= false %>

        base: &base
          precompile_hook: false

        test:
          <<: *default
          <<: *base
          # precompile_hook: ~
      YAML
    end

    it "honors later duplicate merge keys when they enable earlier inactive hooks" do
      expect(active_precompile_hook_configured?(<<~YAML)).to be(true)
        base: &base
          precompile_hook: false

        default: &default
          precompile_hook: <%= false %>

        test:
          <<: *base
          <<: *default
          # precompile_hook: ~
      YAML
    end

    it "ignores nested precompile_hook keys when scanning a section" do
      expect(active_precompile_hook_configured?(<<~YAML)).to be(false)
        default:
          nested:
            precompile_hook: <%= false %>
          # precompile_hook: ~
      YAML
    end

    it "treats raw ERB precompile hooks as active because they may vary by environment" do
      expect(active_precompile_hook_configured?(<<~YAML)).to be(true)
        default:
          precompile_hook: <%= false %>
          # precompile_hook: ~
      YAML
    end

    it "does not treat inherited raw ERB hooks as active after a local inactive override" do
      expect(active_precompile_hook_configured?(<<~YAML)).to be(false)
        default: &default
          precompile_hook: <%= false %>

        test:
          <<: *default
          precompile_hook: ~
          # precompile_hook: ~
      YAML
    end

    it "fails closed when ERB cannot be evaluated" do
      expect(active_precompile_hook_configured?(<<~YAML)).to be(true)
        default:
          precompile_hook: <%= missing_local %>
          # precompile_hook: ~
      YAML
    end

    it "detects raw active hooks when unrelated YAML values force parser fallback" do
      expect(active_precompile_hook_configured?(<<~YAML)).to be(true)
        default:
          released_at: 2026-06-05
          precompile_hook: 'bin/custom-precompile-hook'
          # precompile_hook: ~
      YAML
    end

    it "detects raw active hooks in sections opened by same-line ERB control tags" do
      expect(active_precompile_hook_configured?(<<~YAML)).to be(true)
        <% if true %>test:
          precompile_hook: <%= false %>
          # precompile_hook: ~
        <% end %>
      YAML
    end

    it "detects raw active hooks inherited from anchored sections opened by repeated same-line ERB tags" do
      expect(active_precompile_hook_configured?(<<~YAML)).to be(true)
        <% if true %><% if true %>default: &default
          precompile_hook: <%= false %>
        <% end %><% end %>

        test:
          <<: *default
          # precompile_hook: ~
      YAML
    end
  end

  describe "#raw_precompile_hook_value" do
    it "strips unquoted comments without truncating quoted hashes" do
      expect(raw_precompile_hook_value(%(  precompile_hook: "bin/custom#hook" # comment))).to eq(
        '"bin/custom#hook"'
      )
      expect(raw_precompile_hook_value("  precompile_hook: false # <%= old_hook %>")).to eq("false")
    end
  end

  describe "#generated_precompile_hook_will_be_configured?" do
    let(:shakapacker_yml_path) { File.join(destination_root, "config/shakapacker.yml") }

    before do
      FileUtils.mkdir_p(File.dirname(shakapacker_yml_path))
      allow(ReactOnRails::PackerUtils).to receive(:shakapacker_version_requirement_met?)
        .with("9.0.0")
        .and_return(true)
    end

    after do
      FileUtils.rm_rf(File.join(destination_root, "config"))
    end

    it "does not materialize the generated hook when an unquoted active hook already exists" do
      File.write(shakapacker_yml_path, <<~YAML)
        default: &default
          precompile_hook: bin/shakapacker-precompile-hook
          # precompile_hook: ~

        test:
          <<: *default
      YAML

      expect(
        generated_precompile_hook_will_be_configured?(shakapacker_yml_path, environment: "test")
      ).to be(false)
    end

    it "does not materialize the generated hook over an inherited custom hook" do
      File.write(shakapacker_yml_path, <<~YAML)
        default: &default
          precompile_hook: bin/custom-precompile-hook

        test:
          <<: *default
          # precompile_hook: ~
      YAML

      expect(
        generated_precompile_hook_will_be_configured?(shakapacker_yml_path, environment: "test")
      ).to be(false)
    end

    it "does not materialize the generated hook over an inherited custom hook defined through ERB" do
      File.write(shakapacker_yml_path, <<~YAML)
        default: &default
          precompile_hook: <%= "bin/custom-precompile-hook" %>

        test:
          <<: *default
          # precompile_hook: ~
      YAML

      expect(
        generated_precompile_hook_will_be_configured?(shakapacker_yml_path, environment: "test")
      ).to be(false)
    end

    it "materializes the generated hook when unrelated environments use inactive YAML scalars" do
      %w[~ null false true yes on].each do |inactive_value|
        File.write(shakapacker_yml_path, <<~YAML)
          default: &default
            # precompile_hook: ~

          development:
            precompile_hook: #{inactive_value}

          test:
            <<: *default
        YAML

        expect(
          generated_precompile_hook_will_be_configured?(shakapacker_yml_path, environment: "test")
        ).to be(true), inactive_value
      end
    end

    it "materializes the generated hook when an unrelated environment has an active hook" do
      File.write(shakapacker_yml_path, <<~YAML)
        default: &default
          # precompile_hook: ~

        development:
          precompile_hook: bin/development-precompile-hook

        test:
          <<: *default
      YAML

      expect(
        generated_precompile_hook_will_be_configured?(shakapacker_yml_path, environment: "test")
      ).to be(true)
    end

    it "materializes the generated hook when an unrelated environment has an active hook beside a placeholder" do
      File.write(shakapacker_yml_path, <<~YAML)
        default: &default
          # precompile_hook: ~

        development:
          <<: *default
          precompile_hook: bin/development-precompile-hook
          # precompile_hook: ~

        test:
          <<: *default
      YAML

      expect(
        generated_precompile_hook_will_be_configured?(shakapacker_yml_path, environment: "test")
      ).to be(true)
    end

    it "does not materialize over an ERB hook that may be active in the target build environment" do
      File.write(shakapacker_yml_path, <<~YAML)
        default: &default
          precompile_hook: '<%= Rails.env.production? ? "bin/custom-hook" : "" %>'
          # precompile_hook: ~

        test:
          <<: *default
      YAML

      expect(
        generated_precompile_hook_will_be_configured?(shakapacker_yml_path, environment: "production")
      ).to be(false)
    end

    it "does not materialize over an inherited raw ERB hook even if it renders inactive during install" do
      File.write(shakapacker_yml_path, <<~YAML)
        default: &default
          precompile_hook: <%= false %>

        test:
          <<: *default
          # precompile_hook: ~
      YAML

      expect(
        generated_precompile_hook_will_be_configured?(shakapacker_yml_path, environment: "test")
      ).to be(false)
    end

    it "does not materialize over a raw ERB hook inherited through a commented block merge list" do
      File.write(shakapacker_yml_path, <<~YAML)
        base: &base
          compile: true

        default: &default
          precompile_hook: <%= false %>

        test:
          <<:
            # Keep base first so later aliases can override it.
            - *base
            - *default
          # precompile_hook: ~
      YAML

      expect(
        generated_precompile_hook_will_be_configured?(shakapacker_yml_path, environment: "test")
      ).to be(false)
    end

    it "does not materialize over a raw ERB hook inherited through a block merge list" do
      File.write(shakapacker_yml_path, <<~YAML)
        default: &default
          precompile_hook: <%= false %>

        test:
          <<:
            - *default
          # precompile_hook: ~
      YAML

      expect(
        generated_precompile_hook_will_be_configured?(shakapacker_yml_path, environment: "test")
      ).to be(false)
    end

    it "materializes when an earlier merge-list alias disables a later raw hook" do
      File.write(shakapacker_yml_path, <<~YAML)
        base: &base
          precompile_hook: false

        default: &default
          precompile_hook: <%= false %>

        test:
          <<:
            - *base
            - *default
          # precompile_hook: ~
      YAML

      expect(
        generated_precompile_hook_will_be_configured?(shakapacker_yml_path, environment: "test")
      ).to be(true)
    end

    it "materializes when a later duplicate merge key disables an earlier raw hook" do
      File.write(shakapacker_yml_path, <<~YAML)
        default: &default
          precompile_hook: <%= false %>

        base: &base
          precompile_hook: false

        test:
          <<: *default
          <<: *base
          # precompile_hook: ~
      YAML

      expect(
        generated_precompile_hook_will_be_configured?(shakapacker_yml_path, environment: "test")
      ).to be(true)
    end

    it "does not materialize when a later duplicate merge key enables an earlier inactive hook" do
      File.write(shakapacker_yml_path, <<~YAML)
        base: &base
          precompile_hook: false

        default: &default
          precompile_hook: <%= false %>

        test:
          <<: *base
          <<: *default
          # precompile_hook: ~
      YAML

      expect(
        generated_precompile_hook_will_be_configured?(shakapacker_yml_path, environment: "test")
      ).to be(false)
    end

    it "materializes when an inactive hook has a trailing comment that contains ERB" do
      File.write(shakapacker_yml_path, <<~YAML)
        default: &default
          precompile_hook: false # previously used <%= "bin/custom-precompile-hook" %>
          # precompile_hook: ~

        test:
          <<: *default
      YAML

      expect(
        generated_precompile_hook_will_be_configured?(shakapacker_yml_path, environment: "test")
      ).to be(true)
    end

    it "materializes when only a nested map has a raw precompile_hook" do
      File.write(shakapacker_yml_path, <<~YAML)
        test:
          nested:
            precompile_hook: <%= false %>
          # precompile_hook: ~
      YAML

      expect(
        generated_precompile_hook_will_be_configured?(shakapacker_yml_path, environment: "test")
      ).to be(true)
    end

    it "fails closed when ERB cannot be evaluated while checking generated hook materialization" do
      File.write(shakapacker_yml_path, <<~YAML)
        default: &default
          precompile_hook: <%= missing_local %>
          # precompile_hook: ~

        test:
          <<: *default
      YAML

      expect(
        generated_precompile_hook_will_be_configured?(shakapacker_yml_path, environment: "test")
      ).to be(false)
    end

    it "does not fall back to production raw hooks when parsed YAML is empty and the target section exists" do
      File.write(shakapacker_yml_path, <<~YAML)
        production:
          # precompile_hook: ~

        test:
          released_at: 2026-06-05
          precompile_hook: 'bin/custom-test-hook'
          # precompile_hook: ~
      YAML

      expect(
        generated_precompile_hook_will_be_configured?(shakapacker_yml_path, environment: "test")
      ).to be(false)
    end

    it "does not materialize over an inherited raw quoted hook when YAML parsing falls back" do
      File.write(shakapacker_yml_path, <<~YAML)
        default: &default
          released_at: 2026-06-05
          precompile_hook: 'bin/custom-precompile-hook'

        test:
          <<: *default
          # precompile_hook: ~
      YAML

      expect(
        generated_precompile_hook_will_be_configured?(shakapacker_yml_path, environment: "test")
      ).to be(false)
    end

    it "does not materialize over an inherited quoted boolean-like raw hook when YAML parsing falls back" do
      File.write(shakapacker_yml_path, <<~YAML)
        default: &default
          released_at: 2026-06-05
          precompile_hook: "false"

        test:
          <<: *default
          # precompile_hook: ~
      YAML

      expect(
        generated_precompile_hook_will_be_configured?(shakapacker_yml_path, environment: "test")
      ).to be(false)
    end

    it "materializes when the target environment locally disables an inherited raw ERB hook" do
      File.write(shakapacker_yml_path, <<~YAML)
        default: &default
          precompile_hook: <%= false %>

        test:
          <<: *default
          precompile_hook: ~
          # precompile_hook: ~
      YAML

      expect(
        generated_precompile_hook_will_be_configured?(shakapacker_yml_path, environment: "test")
      ).to be(true)
    end
  end

  describe "Pro/RSC flag helpers" do
    it "treats --rsc as implying Pro" do
      allow(self).to receive(:options).and_return({ rsc: true, pro: false })

      expect(use_rsc?).to be(true)
      expect(use_pro?).to be(true)
    end

    it "enables Pro without RSC for --pro alone" do
      allow(self).to receive(:options).and_return({ rsc: false, pro: true })

      expect(use_rsc?).to be(false)
      expect(use_pro?).to be(true)
    end

    it "does not enable Pro or RSC for a plain install" do
      allow(self).to receive(:options).and_return({ rsc: false, pro: false })

      expect(use_rsc?).to be(false)
      expect(use_pro?).to be(false)
    end
  end

  describe "RSC plugin helpers" do
    it "scaffolds the native RSCRspackPlugin when using rspack" do
      allow(self).to receive(:using_rspack?).and_return(true)

      expect(rsc_plugin_class_name).to eq("RSCRspackPlugin")
      expect(rsc_plugin_import_path).to eq("react-on-rails-rsc/RspackPlugin")
      expect(inactive_rsc_plugin_class_name).to eq("RSCWebpackPlugin")
      expect(inactive_rsc_plugin_import_path).to eq("react-on-rails-rsc/WebpackPlugin")
    end

    it "scaffolds the RSCWebpackPlugin when not using rspack" do
      allow(self).to receive(:using_rspack?).and_return(false)

      expect(rsc_plugin_class_name).to eq("RSCWebpackPlugin")
      expect(rsc_plugin_import_path).to eq("react-on-rails-rsc/WebpackPlugin")
      expect(inactive_rsc_plugin_class_name).to eq("RSCRspackPlugin")
      expect(inactive_rsc_plugin_import_path).to eq("react-on-rails-rsc/RspackPlugin")
    end
  end

  describe "#using_swc?" do
    let(:shakapacker_yml_path) { File.join(destination_root, "config/shakapacker.yml") }

    before do
      # Clear memoized value before each test
      remove_instance_variable(:@using_swc) if instance_variable_defined?(:@using_swc)
      FileUtils.mkdir_p(File.join(destination_root, "config"))
    end

    after do
      FileUtils.rm_rf(File.join(destination_root, "config"))
    end

    context "when shakapacker.yml exists with javascript_transpiler: swc" do
      before do
        File.write(shakapacker_yml_path, <<~YAML)
          default: &default
            javascript_transpiler: swc
        YAML
      end

      it "returns true" do
        expect(using_swc?).to be true
      end
    end

    context "when shakapacker.yml exists with javascript_transpiler: babel" do
      before do
        File.write(shakapacker_yml_path, <<~YAML)
          default: &default
            javascript_transpiler: babel
        YAML
      end

      it "returns false" do
        expect(using_swc?).to be false
      end
    end

    context "when shakapacker.yml exists without javascript_transpiler setting" do
      before do
        File.write(shakapacker_yml_path, <<~YAML)
          default: &default
            source_path: app/javascript
        YAML
        # Stub to simulate Shakapacker 9.3.0+ where SWC is default
        stub_const("ReactOnRails::PackerUtils", Class.new do
          def self.shakapacker_version_requirement_met?(version)
            version == "9.3.0"
          end
        end)
      end

      it "returns true for Shakapacker 9.3.0+ (SWC is default)" do
        expect(using_swc?).to be true
      end
    end

    context "when shakapacker.yml does not exist" do
      before do
        FileUtils.rm_f(shakapacker_yml_path)
        # Stub to simulate Shakapacker 9.3.0+ where SWC is default
        stub_const("ReactOnRails::PackerUtils", Class.new do
          def self.shakapacker_version_requirement_met?(version)
            version == "9.3.0"
          end
        end)
      end

      it "returns true for fresh installations with Shakapacker 9.3.0+" do
        expect(using_swc?).to be true
      end
    end

    context "when shakapacker.yml has parse errors" do
      before do
        File.write(shakapacker_yml_path, "invalid: yaml: [}")
        # Stub to simulate Shakapacker 9.3.0+ where SWC is default
        stub_const("ReactOnRails::PackerUtils", Class.new do
          def self.shakapacker_version_requirement_met?(version)
            version == "9.3.0"
          end
        end)
      end

      it "returns true (assumes latest Shakapacker with SWC default)" do
        expect(using_swc?).to be true
      end
    end

    context "with version boundary scenarios" do
      before do
        File.write(shakapacker_yml_path, <<~YAML)
          default: &default
            source_path: app/javascript
        YAML
      end

      context "when Shakapacker version is 9.3.0+ (SWC default)" do
        before do
          stub_const("ReactOnRails::PackerUtils", Class.new do
            def self.shakapacker_version_requirement_met?(version)
              version == "9.3.0"
            end
          end)
        end

        it "returns true when no transpiler is specified" do
          expect(using_swc?).to be true
        end
      end

      context "when Shakapacker version is below 9.3.0 (Babel default)" do
        before do
          stub_const("ReactOnRails::PackerUtils", Class.new do
            def self.shakapacker_version_requirement_met?(version)
              # Only meets requirements for versions below 9.3.0
              version != "9.3.0"
            end
          end)
        end

        it "returns false when no transpiler is specified" do
          expect(using_swc?).to be false
        end
      end

      context "when PackerUtils raises an error during version check" do
        before do
          stub_const("ReactOnRails::PackerUtils", Class.new do
            def self.shakapacker_version_requirement_met?(_version)
              raise StandardError, "Cannot determine version"
            end
          end)
        end

        it "defaults to true (assumes latest Shakapacker)" do
          expect(using_swc?).to be true
        end
      end
    end
  end

  describe "#root_route_present?" do
    let(:routes_path) { File.join(destination_root, "config/routes.rb") }

    before do
      FileUtils.mkdir_p(File.dirname(routes_path))
    end

    after do
      FileUtils.rm_rf(File.join(destination_root, "config"))
    end

    it "returns false when routes.rb is missing" do
      FileUtils.rm_f(routes_path)

      expect(root_route_present?).to be(false)
    end

    it "returns false when routes.rb has no root route" do
      File.write(routes_path, <<~RUBY)
        Rails.application.routes.draw do
          get "about", to: "pages#about"
        end
      RUBY

      expect(root_route_present?).to be(false)
    end

    it "ignores commented root lines and matches active root routes" do
      File.write(routes_path, <<~RUBY)
        Rails.application.routes.draw do
          # root to: "ignored#comment"
          root to: "home#index"
        end
      RUBY

      expect(root_route_present?).to be(true)
    end
  end
end

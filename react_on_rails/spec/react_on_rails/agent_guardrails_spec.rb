# frozen_string_literal: true

require_relative "spec_helper"
require "react_on_rails/agent_guardrails"
require "tmpdir"
require "json"
require "open3"
require "rbconfig"
require "rake"

# rubocop:disable Metrics/ModuleLength
module ReactOnRails
  RSpec.describe AgentGuardrails do
    around do |example|
      Dir.mktmpdir("ror-agent-guardrails") do |dir|
        @app_root = dir
        example.run
      end
    end

    def settings
      JSON.parse(File.read(File.join(@app_root, ".claude/settings.json")))
    end

    def rsc_hooks
      settings.dig("hooks", "PostToolUse").flat_map { |entry| entry["hooks"] }
              .select do |hook|
        hook["args"] == described_class::HOOK_ARGS || hook["command"] == described_class::LEGACY_HOOK_COMMAND
      end
    end

    def run_hook(*args, stdin_data: "", env: {})
      hook_path = File.join(@app_root, ".claude/hooks/rsc-app-safety-check.rb")

      Dir.chdir(@app_root) { Open3.capture3(env, RbConfig.ruby, hook_path, *args, stdin_data:) }
    end

    def additional_context(stdout)
      JSON.parse(stdout).dig("hookSpecificOutput", "additionalContext")
    end

    it "creates the skill and hook and registers the hook" do
      actions = described_class.install(@app_root)

      expect(File.file?(File.join(@app_root, ".claude/skills/rsc-app-safety/SKILL.md"))).to be true
      hook_path = File.join(@app_root, ".claude/hooks/rsc-app-safety-check.rb")
      expect(File.file?(hook_path)).to be true
      expect(File.read(hook_path)).to start_with("#!/usr/bin/env ruby")
      expect(File.stat(hook_path).mode & 0o111).not_to eq(0) # executable
      expect(rsc_hooks.size).to eq(1)
      expect(actions).to include(a_string_matching(/created.*SKILL\.md/))
    end

    it "is idempotent — a second run changes nothing and does not duplicate the hook" do
      described_class.install(@app_root)
      actions = described_class.install(@app_root)

      expect(actions).to all(match(/unchanged/))
      expect(rsc_hooks.size).to eq(1)
    end

    it "creates missing guardrails when skipping existing files" do
      actions = described_class.install(@app_root, skip_existing: true)

      expect(File.file?(File.join(@app_root, ".claude/skills/rsc-app-safety/SKILL.md"))).to be true
      expect(File.file?(File.join(@app_root, ".claude/hooks/rsc-app-safety-check.rb"))).to be true
      expect(rsc_hooks.size).to eq(1)
      expect(actions).to all(match(/created/))
    end

    it "preserves guardrail files and settings that already exist when skipping" do
      skill_path = File.join(@app_root, ".claude/skills/rsc-app-safety/SKILL.md")
      hook_path = File.join(@app_root, ".claude/hooks/rsc-app-safety-check.rb")
      settings_path = File.join(@app_root, ".claude/settings.json")
      [skill_path, hook_path, settings_path].each { |path| FileUtils.mkdir_p(File.dirname(path)) }
      File.write(skill_path, "custom skill\n")
      File.write(hook_path, "custom hook\n")
      File.write(settings_path, "custom settings\n")

      actions = described_class.install(@app_root, skip_existing: true)

      expect(File.read(skill_path)).to eq("custom skill\n")
      expect(File.read(hook_path)).to eq("custom hook\n")
      expect(File.read(settings_path)).to eq("custom settings\n")
      expect(actions).to all(match(/skipped/))
    end

    it "restores executable permissions when an unchanged hook is reinstalled" do
      described_class.install(@app_root)
      hook_path = File.join(@app_root, ".claude/hooks/rsc-app-safety-check.rb")
      File.chmod(0o644, hook_path)

      actions = described_class.install(@app_root)

      expect(File.stat(hook_path).mode & 0o111).not_to eq(0)
      expect(actions).to include("unchanged  .claude/hooks/rsc-app-safety-check.rb")
    end

    it "parses Claude hook input without requiring jq" do
      described_class.install(@app_root)
      routes_path = File.join(@app_root, "config/routes.rb")
      FileUtils.mkdir_p(File.dirname(routes_path))
      File.write(routes_path, "rsc_payload_route\n")

      stdout, _stderr, status = run_hook(
        stdin_data: JSON.generate("tool_input" => { "file_path" => routes_path })
      )

      expect(status).to be_success
      expect(additional_context(stdout)).to include("This routes file mounts rsc_payload_route")
      expect(additional_context(stdout)).to include("ReactOnRailsPro.configure")
      expect(additional_context(stdout)).to include("config.rsc_payload_authorizer")
    end

    it "supports manual invocation through Ruby with a bare relative routes path" do
      described_class.install(@app_root)
      routes_path = File.join(@app_root, "config/routes.rb")
      FileUtils.mkdir_p(File.dirname(routes_path))
      File.write(routes_path, "rsc_payload_route\n")

      stdout, _stderr, status = run_hook("config/routes.rb")

      expect(status).to be_success
      expect(additional_context(stdout)).to include("This routes file mounts rsc_payload_route")
    end

    it "falls back to the manual path for valid non-object JSON input" do
      described_class.install(@app_root)
      routes_path = File.join(@app_root, "config/routes.rb")
      FileUtils.mkdir_p(File.dirname(routes_path))
      File.write(routes_path, "rsc_payload_route\n")

      stdout, _stderr, status = run_hook("config/routes.rb", stdin_data: "[]")

      expect(status).to be_success
      expect(additional_context(stdout)).to include("This routes file mounts rsc_payload_route")
    end

    it "normalizes Windows path separators without requiring Bash" do
      described_class.install(@app_root)
      routes_path = File.join(@app_root, "config/routes.rb")
      FileUtils.mkdir_p(File.dirname(routes_path))
      File.write(routes_path, "rsc_payload_route\n")

      stdout, _stderr, status = run_hook("config\\routes.rb")

      expect(status).to be_success
      expect(additional_context(stdout)).to include("This routes file mounts rsc_payload_route")
    end

    it "does not warn for a commented payload route" do
      described_class.install(@app_root)
      routes_path = File.join(@app_root, "config/routes.rb")
      FileUtils.mkdir_p(File.dirname(routes_path))
      File.write(routes_path, "# rsc_payload_route\n")

      stdout, stderr, status = run_hook("config/routes.rb")

      expect(status).to be_success
      expect(stdout).to be_empty
      expect(stderr).to be_empty
    end

    it "does not read unrelated edited files" do
      described_class.install(@app_root)
      unrelated_path = File.join(@app_root, "tmp/generated-output.rb")
      FileUtils.mkdir_p(File.dirname(unrelated_path))
      File.write(unrelated_path, "rsc_payload_route\ninclude RSCPayloadRenderer\n")

      stdout, stderr, status = run_hook("tmp/generated-output.rb")

      expect(status).to be_success
      expect(stdout).to be_empty
      expect(stderr).to be_empty
    end

    it "remains non-blocking when a matching file cannot be read" do
      described_class.install(@app_root)
      routes_path = File.join(@app_root, "config/routes.rb")
      FileUtils.mkdir_p(File.dirname(routes_path))
      File.write(routes_path, "rsc_payload_route\n")
      read_failure_path = File.join(@app_root, "inject_read_failure.rb")
      File.write(
        read_failure_path,
        <<~'RUBY'
          module InjectReadFailure
            def read(path, *)
              raise Errno::EACCES, path if path.to_s.tr("\\", "/").end_with?("config/routes.rb")

              super
            end
          end

          File.singleton_class.prepend(InjectReadFailure)
        RUBY
      )

      stdout, stderr, status = run_hook(
        "config/routes.rb",
        env: {
          "RUBYOPT" => "-r#{read_failure_path}"
        }
      )

      expect(status).to be_success
      expect(stdout).to be_empty
      expect(stderr).to be_empty
    end

    it "warns for a namespaced controller supplied as a bare relative path" do
      described_class.install(@app_root)
      controller_path = File.join(@app_root, "app/controllers/api/rsc_payload_controller.rb")
      FileUtils.mkdir_p(File.dirname(controller_path))
      File.write(controller_path, "include RSCPayloadRenderer\n")

      stdout, _stderr, status = run_hook("app/controllers/api/rsc_payload_controller.rb")

      expect(status).to be_success
      expect(additional_context(stdout)).to include("edited file shows no before_action/authentication locally")
      expect(additional_context(stdout)).to include("Inherited callbacks are not inspected")
    end

    it "still warns when an RSC controller only has an unrelated callback" do
      described_class.install(@app_root)
      controller_path = File.join(@app_root, "app/controllers/rsc_payload_controller.rb")
      FileUtils.mkdir_p(File.dirname(controller_path))
      File.write(
        controller_path,
        "# before_action :authenticate_user!\nbefore_action :set_locale\ninclude RSCPayloadRenderer\n"
      )

      stdout, _stderr, status = run_hook("app/controllers/rsc_payload_controller.rb")

      expect(status).to be_success
      expect(additional_context(stdout)).to include("shows no before_action/authentication")
    end

    it "still warns when authentication only appears in a Ruby block comment" do
      described_class.install(@app_root)
      controller_path = File.join(@app_root, "app/controllers/rsc_payload_controller.rb")
      FileUtils.mkdir_p(File.dirname(controller_path))
      File.write(
        controller_path,
        <<~RUBY
          =begin
          before_action :authenticate_user!
          =end
          include RSCPayloadRenderer
        RUBY
      )

      stdout, _stderr, status = run_hook("app/controllers/rsc_payload_controller.rb")

      expect(status).to be_success
      expect(additional_context(stdout)).to include("shows no before_action/authentication")
    end

    it "does not warn when renderer evidence only appears in Ruby comments or strings" do
      described_class.install(@app_root)
      controller_path = File.join(@app_root, "app/controllers/ordinary_controller.rb")
      FileUtils.mkdir_p(File.dirname(controller_path))
      File.write(
        controller_path,
        <<~RUBY
          # include RSCPayloadRenderer
          route_note = "rsc_payload"
          =begin
          def rsc_payload
          end
          =end
        RUBY
      )

      stdout, stderr, status = run_hook("app/controllers/ordinary_controller.rb")

      expect(status).to be_success
      expect(stdout).to be_empty
      expect(stderr).to be_empty
    end

    it "remains non-blocking when a controller contains invalidly encoded bytes" do
      described_class.install(@app_root)
      controller_path = File.join(@app_root, "app/controllers/rsc_payload_controller.rb")
      FileUtils.mkdir_p(File.dirname(controller_path))
      File.binwrite(controller_path, "include RSCPayloadRenderer\n# ".b + "\xFF\n".b)

      stdout, stderr, status = run_hook("app/controllers/rsc_payload_controller.rb")

      expect(status).to be_success
      expect(stdout).to be_empty
      expect(stderr).to be_empty
    end

    it "still warns when an authentication callback excludes the RSC payload action" do
      described_class.install(@app_root)
      controller_path = File.join(@app_root, "app/controllers/rsc_payload_controller.rb")
      FileUtils.mkdir_p(File.dirname(controller_path))
      File.write(
        controller_path,
        "before_action :authenticate_user!, except: :rsc_payload\ninclude RSCPayloadRenderer\n"
      )

      stdout, _stderr, status = run_hook("app/controllers/rsc_payload_controller.rb")

      expect(status).to be_success
      expect(additional_context(stdout)).to include("shows no before_action/authentication")
    end

    it "still warns when an authentication callback is limited to another action" do
      described_class.install(@app_root)
      controller_path = File.join(@app_root, "app/controllers/rsc_payload_controller.rb")
      FileUtils.mkdir_p(File.dirname(controller_path))
      File.write(
        controller_path,
        "before_action :authenticate_user!, only: :index\ninclude RSCPayloadRenderer\n"
      )

      stdout, _stderr, status = run_hook("app/controllers/rsc_payload_controller.rb")

      expect(status).to be_success
      expect(additional_context(stdout)).to include("shows no before_action/authentication")
    end

    it "still warns when direct authentication only appears in another action" do
      described_class.install(@app_root)
      controller_path = File.join(@app_root, "app/controllers/rsc_payload_controller.rb")
      FileUtils.mkdir_p(File.dirname(controller_path))
      File.write(
        controller_path,
        "def index\n  authenticate_user!\nend\n\ndef rsc_payload\nend\n\ninclude RSCPayloadRenderer\n"
      )

      stdout, _stderr, status = run_hook("app/controllers/rsc_payload_controller.rb")

      expect(status).to be_success
      expect(additional_context(stdout)).to include("shows no before_action/authentication")
    end

    it "still warns for legacy callback scope syntax" do
      described_class.install(@app_root)
      controller_path = File.join(@app_root, "app/controllers/rsc_payload_controller.rb")
      FileUtils.mkdir_p(File.dirname(controller_path))
      File.write(
        controller_path,
        "before_action :authenticate_user!, :except => :rsc_payload\ninclude RSCPayloadRenderer\n"
      )

      stdout, _stderr, status = run_hook("app/controllers/rsc_payload_controller.rb")

      expect(status).to be_success
      expect(additional_context(stdout)).to include("shows no before_action/authentication")
    end

    it "still warns for a conditional authentication callback" do
      described_class.install(@app_root)
      controller_path = File.join(@app_root, "app/controllers/rsc_payload_controller.rb")
      FileUtils.mkdir_p(File.dirname(controller_path))
      File.write(
        controller_path,
        "before_action :authenticate_user!, unless: :skip_auth?\ninclude RSCPayloadRenderer\n"
      )

      stdout, _stderr, status = run_hook("app/controllers/rsc_payload_controller.rb")

      expect(status).to be_success
      expect(additional_context(stdout)).to include("shows no before_action/authentication")
    end

    it "still warns when the payload action skips an otherwise applicable authentication callback" do
      described_class.install(@app_root)
      controller_path = File.join(@app_root, "app/controllers/rsc_payload_controller.rb")
      FileUtils.mkdir_p(File.dirname(controller_path))
      File.write(
        controller_path,
        <<~RUBY
          before_action :authenticate_user!
          skip_before_action :authenticate_user!, only: :rsc_payload
          include RSCPayloadRenderer
        RUBY
      )

      stdout, _stderr, status = run_hook("app/controllers/rsc_payload_controller.rb")

      expect(status).to be_success
      expect(additional_context(stdout)).to include("shows no before_action/authentication")
    end

    it "accepts authentication when a matching skip excludes the payload action" do
      described_class.install(@app_root)
      controller_path = File.join(@app_root, "app/controllers/rsc_payload_controller.rb")
      FileUtils.mkdir_p(File.dirname(controller_path))
      File.write(
        controller_path,
        <<~RUBY
          before_action :authenticate_user!
          skip_before_action :authenticate_user!, except: :rsc_payload
          include RSCPayloadRenderer
        RUBY
      )

      stdout, stderr, status = run_hook("app/controllers/rsc_payload_controller.rb")

      expect(status).to be_success
      expect(stdout).to be_empty
      expect(stderr).to be_empty
    end

    it "accepts an authentication callback explicitly limited to the RSC payload action" do
      described_class.install(@app_root)
      controller_path = File.join(@app_root, "app/controllers/rsc_payload_controller.rb")
      FileUtils.mkdir_p(File.dirname(controller_path))
      File.write(
        controller_path,
        "before_action :authenticate_user!, only: :rsc_payload\ninclude RSCPayloadRenderer\n"
      )

      stdout, stderr, status = run_hook("app/controllers/rsc_payload_controller.rb")

      expect(status).to be_success
      expect(stdout).to be_empty
      expect(stderr).to be_empty
    end

    it "accepts an authentication callback that excludes a different action" do
      described_class.install(@app_root)
      controller_path = File.join(@app_root, "app/controllers/rsc_payload_controller.rb")
      FileUtils.mkdir_p(File.dirname(controller_path))
      File.write(
        controller_path,
        "before_action :authenticate_user!, except: :health_check\ninclude RSCPayloadRenderer\n"
      )

      stdout, stderr, status = run_hook("app/controllers/rsc_payload_controller.rb")

      expect(status).to be_success
      expect(stdout).to be_empty
      expect(stderr).to be_empty
    end

    it "accepts a multiline authentication callback whose action list includes the RSC payload" do
      described_class.install(@app_root)
      controller_path = File.join(@app_root, "app/controllers/rsc_payload_controller.rb")
      FileUtils.mkdir_p(File.dirname(controller_path))
      File.write(
        controller_path,
        "before_action :authenticate_user!,\n              only: %i[index rsc_payload]\ninclude RSCPayloadRenderer\n"
      )

      stdout, stderr, status = run_hook("app/controllers/rsc_payload_controller.rb")

      expect(status).to be_success
      expect(stdout).to be_empty
      expect(stderr).to be_empty
    end

    it "does not warn when an RSC controller has an authentication callback" do
      described_class.install(@app_root)
      controller_path = File.join(@app_root, "app/controllers/rsc_payload_controller.rb")
      FileUtils.mkdir_p(File.dirname(controller_path))
      File.write(controller_path, "before_action :authenticate_user!\ninclude RSCPayloadRenderer\n")

      stdout, stderr, status = run_hook("app/controllers/rsc_payload_controller.rb")

      expect(status).to be_success
      expect(stdout).to be_empty
      expect(stderr).to be_empty
    end

    it "accepts prepended and appended authentication callbacks" do
      described_class.install(@app_root)
      controller_path = File.join(@app_root, "app/controllers/rsc_payload_controller.rb")
      FileUtils.mkdir_p(File.dirname(controller_path))

      %w[prepend_before_action append_before_action].each do |callback|
        File.write(controller_path, "#{callback} :authenticate_user!\ninclude RSCPayloadRenderer\n")

        stdout, stderr, status = run_hook("app/controllers/rsc_payload_controller.rb")

        expect(status).to be_success
        expect(stdout).to be_empty
        expect(stderr).to be_empty
      end
    end

    it "installs guidance for the two supported payload authorization approaches" do
      described_class.install(@app_root)
      skill_path = File.join(@app_root, ".claude/skills/rsc-app-safety/SKILL.md")
      skill = File.read(skill_path)

      expect(skill).to include("ReactOnRailsPro.configure do |config|")
      expect(skill).to include("config.rsc_payload_authorizer")
      expect(skill).to include("controller.session[:user_id].present?")
      expect(skill).to include("allowed_rsc_components.include?(component_name)")
      expect(skill).to include("does not inherit from your app's `ApplicationController`")
      expect(skill).to include("app-owned controller")
      expect(skill).to include("redacts SSR props and generated JavaScript")
      expect(skill).not_to include("Props passed to SSR can reach your error tracker")
    end

    it "registers the project hook in exec form so paths with spaces are not shell-split" do
      described_class.install(@app_root)

      hook = settings.dig("hooks", "PostToolUse").flat_map { |entry| entry.fetch("hooks") }
                     .find { |entry| entry["command"] == described_class::HOOK_COMMAND }

      expect(hook).to include(
        "type" => "command", "command" => described_class::HOOK_COMMAND, "args" => described_class::HOOK_ARGS
      )
    end

    it "removes the legacy shell hook file and upgrades its settings registration" do
      claude_dir = File.join(@app_root, ".claude")
      legacy_hook_path = File.join(claude_dir, "hooks/rsc-app-safety-check.sh")
      FileUtils.mkdir_p(claude_dir)
      FileUtils.mkdir_p(File.dirname(legacy_hook_path))
      File.write(legacy_hook_path, "#!/usr/bin/env bash\n")
      File.write(
        File.join(claude_dir, "settings.json"),
        JSON.pretty_generate(
          "hooks" => {
            "PostToolUse" => [
              {
                "matcher" => "Edit|Write",
                "hooks" => [{ "type" => "command", "command" => described_class::LEGACY_HOOK_COMMAND }]
              }
            ]
          }
        )
      )

      actions = described_class.install(@app_root)

      project_hooks = rsc_hooks
      expect(File.exist?(legacy_hook_path)).to be false
      expect(File.file?(File.join(claude_dir, "hooks/rsc-app-safety-check.rb"))).to be true
      expect(actions).to include(
        "removed    .claude/hooks/rsc-app-safety-check.sh (replaced by .claude/hooks/rsc-app-safety-check.rb)"
      )
      expect(project_hooks).to contain_exactly(
        "type" => "command", "command" => described_class::HOOK_COMMAND, "args" => described_class::HOOK_ARGS
      )
    end

    it "removes duplicate managed legacy settings when the Ruby hook is already registered" do
      claude_dir = File.join(@app_root, ".claude")
      FileUtils.mkdir_p(claude_dir)
      File.write(
        File.join(claude_dir, "settings.json"),
        JSON.pretty_generate(
          "hooks" => {
            "PostToolUse" => [
              {
                "matcher" => "Edit|Write",
                "hooks" => [
                  {
                    "type" => "command",
                    "command" => described_class::HOOK_COMMAND,
                    "args" => described_class::HOOK_ARGS
                  },
                  { "type" => "command", "command" => described_class::LEGACY_HOOK_COMMAND }
                ]
              }
            ]
          }
        )
      )

      described_class.install(@app_root)

      expect(rsc_hooks).to contain_exactly(
        "type" => "command", "command" => described_class::HOOK_COMMAND, "args" => described_class::HOOK_ARGS
      )
    end

    it "merges into an existing settings.json without clobbering other hooks" do
      claude_dir = File.join(@app_root, ".claude")
      FileUtils.mkdir_p(claude_dir)
      existing = {
        "hooks" => {
          "PostToolUse" => [
            { "matcher" => "Edit|Write", "hooks" => [{ "type" => "command", "command" => "bin/existing-hook" }] }
          ]
        }
      }
      File.write(File.join(claude_dir, "settings.json"), JSON.pretty_generate(existing))

      described_class.install(@app_root)

      all_commands = settings.dig("hooks", "PostToolUse").flat_map { |entry| entry["hooks"] }.map { |h| h["command"] }
      expect(all_commands).to include("bin/existing-hook")
      expect(rsc_hooks.size).to eq(1)
      # Both hooks share the single Edit|Write matcher entry rather than duplicating it.
      expect(settings.dig("hooks", "PostToolUse").size).to eq(1)
    end

    it "raises rather than clobbering an unparseable settings.json" do
      claude_dir = File.join(@app_root, ".claude")
      legacy_hook_path = File.join(claude_dir, "hooks/rsc-app-safety-check.sh")
      FileUtils.mkdir_p(claude_dir)
      FileUtils.mkdir_p(File.dirname(legacy_hook_path))
      File.write(legacy_hook_path, "custom legacy hook\n")
      File.write(File.join(claude_dir, "settings.json"), "{ not valid json ")

      expect { described_class.install(@app_root) }.to raise_error(described_class::Error, /not valid JSON/)
      expect(File.read(legacy_hook_path)).to eq("custom legacy hook\n")
      expect(File.exist?(File.join(claude_dir, "skills/rsc-app-safety/SKILL.md"))).to be false
      expect(File.exist?(File.join(claude_dir, "hooks/rsc-app-safety-check.rb"))).to be false
    end

    it "raises rather than clobbering valid JSON with an unsupported settings shape" do
      claude_dir = File.join(@app_root, ".claude")
      settings_path = File.join(claude_dir, "settings.json")
      FileUtils.mkdir_p(claude_dir)

      [[], { "hooks" => [] }, { "hooks" => { "PostToolUse" => "invalid" } }].each do |invalid_settings|
        File.write(settings_path, JSON.pretty_generate(invalid_settings))

        expect { described_class.install(@app_root) }
          .to raise_error(described_class::Error, /not valid JSON/)
        expect(JSON.parse(File.read(settings_path))).to eq(invalid_settings)
        expect(File.exist?(File.join(claude_dir, "skills/rsc-app-safety/SKILL.md"))).to be false
        expect(File.exist?(File.join(claude_dir, "hooks/rsc-app-safety-check.rb"))).to be false
      end
    end

    it "reports filesystem errors from the install task without a raw backtrace" do
      original_rake_application = Rake.application
      Rake.application = Rake::Application.new
      load File.expand_path("../../lib/tasks/agent_guardrails.rake", __dir__)
      allow(described_class).to receive(:install).and_raise(Errno::EACCES, ".claude/settings.json")
      exit_status = nil

      expect do
        Rake::Task["react_on_rails:install_rsc_agent_guardrails"].invoke
      rescue SystemExit => e
        exit_status = e.status
      end.to output(a_string_including("React on Rails:", "Permission denied", ".claude/settings.json")).to_stderr
      expect(exit_status).to eq(1)
    ensure
      Rake.application = original_rake_application
    end
  end
end
# rubocop:enable Metrics/ModuleLength

# frozen_string_literal: true

require "json"
require "pathname"
require "rbconfig"
require "tempfile"
require "yaml"

RSpec.describe "packaged agent content" do
  repo_root = Pathname.new(File.expand_path("../../..", __dir__))
  gem_root = repo_root.join("react_on_rails")
  npm_root = repo_root.join("packages/react-on-rails")

  skill_names = %w[doctor-fix-loop install-and-upgrade rsc-adoption streaming-debug].freeze
  doc_names = %w[README.md doctor-fix-loop.md install-and-upgrade.md rsc-adoption.md streaming-debug.md].freeze
  package_paths = [
    *skill_names.map { |name| "skills/#{name}/SKILL.md" },
    *doc_names.map { |name| "docs/agent/#{name}" }
  ].freeze

  it "ships byte-identical agent content in the gem and npm packages" do
    aggregate_failures do
      package_paths.each do |relative_path|
        gem_path = gem_root.join(relative_path)
        npm_path = npm_root.join(relative_path)

        expect(gem_path.exist?).to be(true), "expected gem package file #{relative_path} to exist"
        expect(npm_path.exist?).to be(true), "expected npm package file #{relative_path} to exist"
        next unless gem_path.exist? && npm_path.exist?

        expect(npm_path.binread).to eq(gem_path.binread), "expected #{relative_path} to match across packages"
      end
    end
  end

  it "declares exactly the intended agent files in the npm package manifest" do
    package_json = JSON.parse(npm_root.join("package.json").read)
    declared_agent_files = package_json.fetch("files").grep(%r{\A(?:skills/|docs/agent/)})

    expect(declared_agent_files).to match_array(package_paths)
    expect(declared_agent_files).not_to include("skills/**/SKILL.md", "docs/agent/**/*.md")
  end

  it "checks the packed npm agent-file set for missing and extra paths" do
    checker = npm_root.join("scripts/check-package-license.mjs").read

    expect(checker).to include("const packedAgentFiles = packedFiles")
    expect(checker).to include("path.startsWith('package/skills/')")
    expect(checker).to include("path.startsWith('package/docs/agent/')")
    expect(checker).to match(/assert\.deepEqual\(\s*packedAgentFiles,\s*expectedAgentFiles,/m)
  end

  it "uses valid skill metadata and package-local guide links" do
    aggregate_failures do
      skill_names.each do |skill_name|
        skill_path = gem_root.join("skills/#{skill_name}/SKILL.md")
        next unless skill_path.exist?

        skill_text = skill_path.read
        frontmatter = skill_text.match(/\A---\n(?<yaml>.*?)\n---\n/m)
        expect(frontmatter).not_to be_nil, "expected #{skill_name} to have YAML frontmatter"
        next unless frontmatter

        metadata = YAML.safe_load(frontmatter[:yaml])
        expect(metadata.fetch("name")).to eq(skill_name)
        expect(metadata.fetch("description")).to be_a(String).and(satisfy { |description| !description.empty? })
        expect(skill_text).to include("../../docs/agent/#{skill_name}.md")
      end
    end
  end

  it "includes every agent file in the gem specification" do
    gemspec = Gem::Specification.load(gem_root.join("react_on_rails.gemspec").to_s)

    expect(gemspec.files).to include(*package_paths)
  end

  it "keeps untracked agent drafts out of the gem specification" do
    script = <<~RUBY
      path = ARGV.fetch(0)
      specification = Gem::Specification.load("react_on_rails.gemspec")
      abort "draft was packaged" if specification.files.include?(path)
    RUBY

    Tempfile.create(["package-agent-draft-", ".md"], gem_root.join("docs/agent")) do |draft|
      draft.write("local draft")
      draft.flush
      relative_path = Pathname.new(draft.path).relative_path_from(gem_root).to_s

      expect(system(RbConfig.ruby, "-e", script, relative_path, chdir: gem_root.to_s)).to be(true)
    end
  end

  it "creates the draft fixture atomically with automatic cleanup" do
    source = Pathname.new(__FILE__).read
    requires = source.lines.take_while { |line| !line.start_with?("RSpec.describe") }.join
    draft_example = source.match(
      /it "keeps untracked agent drafts out of the gem specification" do\n(?<body>.*?)(?=^  it ")/m
    )[:body]

    aggregate_failures do
      expect(requires).to include('require "tempfile"')
      expect(draft_example).to include("Tempfile.create")
      expect(draft_example).to match(/Tempfile\.create\(.*\) do \|draft\|/)
      expect(draft_example).not_to include("docs/agent/local-draft.md")
    end
  end

  it "describes use client as a boundary rather than a per-module annotation" do
    guide = gem_root.join("docs/agent/rsc-adoption.md").read

    expect(guide).to include("marks the server-to-client boundary")
    expect(guide).to include("Modules imported below that boundary remain client code")
  end

  it "includes the required streaming controller entry point" do
    guide = gem_root.join("docs/agent/streaming-debug.md").read

    expect(guide).to include("stream_view_containing_react_components")
  end

  it "runs the RSC adoption doctor through the consumer app binstub" do
    guide = gem_root.join("docs/agent/rsc-adoption.md").read

    expect(guide).to include("bin/rails react_on_rails:doctor FORMAT=json")
    expect(guide).not_to include("bundle exec rails react_on_rails:doctor")
  end

  it "preserves the app language when adopting RSC" do
    rsc_paths = %w[skills/rsc-adoption/SKILL.md docs/agent/rsc-adoption.md]

    aggregate_failures do
      rsc_paths.each do |relative_path|
        content = gem_root.join(relative_path).read

        expect(content).to include("`bundle exec rails generate react_on_rails:rsc --typescript`")
        expect(content).to include("`bundle exec rails generate react_on_rails:rsc`")
        expect(content).to match(/--typescript` for (?:a )?TypeScript app/)
      end
    end
  end

  it "separates progressive and buffered streaming requirements" do
    streaming_paths = %w[skills/streaming-debug/SKILL.md docs/agent/streaming-debug.md]

    aggregate_failures do
      streaming_paths.each do |relative_path|
        content = gem_root.join(relative_path).read
        progressive = content.match(/^## Progressive helpers\n(?<body>.*?)(?=^## Buffered helpers$)/m)
        buffered = content.match(/^## Buffered helpers\n(?<body>.*?)(?=^## |\z)/m)

        expect(progressive).not_to be_nil, "expected #{relative_path} to describe progressive helpers separately"
        expect(buffered).not_to be_nil, "expected #{relative_path} to describe buffered helpers separately"
        next unless progressive && buffered

        expect(progressive[:body]).to include("`ReactOnRailsPro::Stream`")
        expect(progressive[:body]).to include("`stream_view_containing_react_components`")
        expect(progressive[:body]).to include("Node renderer")
        expect(progressive[:body]).to include("actually suspends")

        expect(buffered[:body]).to include("`buffered_stream_react_component`")
        expect(buffered[:body]).to include("`cached_buffered_stream_react_component`")
        expect(buffered[:body]).to include("`cached_static_rsc_component`")
        expect(buffered[:body]).to match(
          /do not require .*`ReactOnRailsPro::Stream`.*`stream_view_containing_react_components`.*suspending boundary/m
        )
      end
    end
  end

  it "scopes the RSC-support prerequisite to the async-props helper" do
    streaming_paths = %w[skills/streaming-debug/SKILL.md docs/agent/streaming-debug.md]

    aggregate_failures do
      streaming_paths.each do |relative_path|
        content = gem_root.join(relative_path).read

        expect(content).to include("For `stream_react_component_with_async_props` only")
        expect(content).to include("`ReactOnRailsPro.configuration.enable_rsc_support`")
        expect(content).to include("`config.enable_rsc_support = true`")
        expect(content).to include(
          "not a prerequisite for `stream_react_component` or `cached_stream_react_component`"
        )
      end
    end
  end

  it "requires RSC support only for cached static RSC among buffered helpers" do
    streaming_paths = %w[skills/streaming-debug/SKILL.md docs/agent/streaming-debug.md]

    aggregate_failures do
      streaming_paths.each do |relative_path|
        content = gem_root.join(relative_path).read
        buffered = content.match(/^## Buffered helpers\n(?<body>.*?)(?=^## |\z)/m)

        expect(buffered).not_to be_nil, "expected #{relative_path} to describe buffered helpers"
        next unless buffered

        expect(buffered[:body]).to match(
          /For `cached_static_rsc_component`, set `config\.enable_rsc_support = true`/
        )
        expect(buffered[:body]).to match(
          /not a prerequisite for `buffered_stream_react_component` or\s+`cached_buffered_stream_react_component`/
        )
      end
    end
  end

  it "indexes every bundled guide from the package-local README" do
    readme_path = gem_root.join("docs/agent/README.md")
    skip "package-local agent README is not implemented yet" unless readme_path.exist?

    readme = readme_path.read
    aggregate_failures do
      skill_names.each do |skill_name|
        expect(readme).to include("./#{skill_name}.md")
        expect(readme).to include("../../skills/#{skill_name}/SKILL.md")
      end
    end
  end

  it "uses the installed gem directory as the canonical agent-content lookup" do
    readme = gem_root.join("docs/agent/README.md").read
    gem_lookup = readme.index("bundle show react_on_rails")
    npm_lookup = readme.index("node_modules/react-on-rails/")

    expect(readme).to include("canonical, reliable lookup")
    expect(readme).to match(/optional\s+direct-dependency path/)
    expect(readme).to include("Do not assume it exists")
    expect(gem_lookup).to be < npm_lookup
  end

  it "compares the installed version and pins the verified JavaScript stack matrix" do
    guide = gem_root.join("docs/agent/install-and-upgrade.md").read
    target_selection = guide.index("Choose and verify explicit Ruby and npm target versions")
    pin_update = guide.index("Pin Ruby gems with `GEM_TARGET_VERSION`")

    expect(guide).to include("bundle exec ruby -rreact_on_rails/version")
    expect(guide).to include("ReactOnRails::VERSION")
    expect(guide).to include("`CURRENT_VERSION`")
    expect(guide).to include("`GEM_TARGET_VERSION`")
    expect(guide).to include("`NPM_TARGET_VERSION`")
    expect(guide).to include("Ruby prereleases use dot notation")
    expect(guide).to include("npm prereleases use hyphen notation")
    expect(guide).to include('"refs/tags/v${GEM_TARGET_VERSION}"')
    expect(guide).to include("Use the app's declared package manager's")
    expect(guide).to include("registry-inspection command for every exact package spec")
    expect(guide).to include("`v<GEM_TARGET_VERSION>`")
    expect(guide).to include("`CURRENT_VERSION..GEM_TARGET_VERSION`")
    expect(target_selection).to be < pin_update
    expect(guide).not_to include("`TARGET_VERSION`")

    expect(guide).to include("## JavaScript target matrix")
    expect(guide).to include("**OSS (`--standard-only`)**")
    expect(guide).to include("`react-on-rails@${NPM_TARGET_VERSION}`")
    expect(guide).to include("**Pro (all renderers)**")
    expect(guide).to include("`react-on-rails-pro@${NPM_TARGET_VERSION}`")
    expect(guide).to include("`react-on-rails-pro-node-renderer@${NPM_TARGET_VERSION}`")
    expect(guide).to include("only when the app uses the standalone NodeRenderer")
    expect(guide).to include("Do not add a direct `react-on-rails` dependency")
    expect(guide).to include("**RSC (`--rsc`)**")
    expect(guide).to include("`ReactOnRails::Generators::JsDependencyManager::RSC_PACKAGE_VERSION_PIN`")
    expect(guide).to include("`react-on-rails-rsc@${RSC_TARGET_VERSION}`")
    expect(guide).to include("Never derive `RSC_TARGET_VERSION` from `NPM_TARGET_VERSION`")
    expect(guide).not_to match(/^\s*(?:npm|pnpm|yarn|bun)\s+(?:view|info|pm view)\s+/)
    expect(guide).not_to include("Pin npm packages with `NPM_TARGET_VERSION`")
  end

  it "requires an explicit stack flag in every new-install generator command" do
    guide = gem_root.join("docs/agent/install-and-upgrade.md").read
    install = guide.match(/^## Install\n(?<body>.*?)(?=^## Upgrade$)/m)[:body]
    choice = "Choose exactly one stack flag before running the install generator"
    commands = install.scan(/^bundle exec rails generate react_on_rails:install.*$/)

    expect(install).to include(choice)
    expect(install).to include("`--standard-only`", "`--pro`", "`--rsc`")
    expect(install).to include("Do not rely on an interactive TTY prompt")
    expect(commands).not_to be_empty
    expect(commands).to all(include("<STACK_FLAG>"))
    expect(install.index(choice)).to be < install.index(commands.first)
  end

  it "preserves JavaScript installs unless TypeScript is explicitly selected" do
    guide = gem_root.join("docs/agent/install-and-upgrade.md").read
    install = guide.match(/^## Install\n(?<body>.*?)(?=^## Upgrade$)/m)[:body]
    generator = "bundle exec rails generate react_on_rails:install <LANGUAGE_CHOICE> <STACK_FLAG>"

    expect(install).to include(generator)
    expect(install).to include("replace `<LANGUAGE_CHOICE>` with `--typescript` for TypeScript")
    expect(install).to include("omitting its flag preserves JavaScript")
    expect(install).not_to include("react_on_rails:install --typescript <STACK_FLAG>")
  end

  it "prepares an exact matching Pro gem before a Pro or RSC install" do
    guide = gem_root.join("docs/agent/install-and-upgrade.md").read
    install = guide.match(/^## Install\n(?<body>.*?)(?=^## Upgrade$)/m)[:body]
    shakapacker = "bundle add shakapacker --strict"
    base_gem = "bundle add react_on_rails --strict"
    version =
      %(ROR_GEM_VERSION="$(bundle exec ruby -rreact_on_rails/version -e 'print ReactOnRails::VERSION')")
    pro_gem = %(bundle add react_on_rails_pro --version="${ROR_GEM_VERSION}" --strict)
    generator = "bundle exec rails generate react_on_rails:install <LANGUAGE_CHOICE> <STACK_FLAG>"
    license_notice =
      /React on Rails Pro is free for evaluation and non-production use;\s+production use requires a subscription\./
    license_notice_start = "React on Rails Pro is free for evaluation"
    license_link = "https://reactonrails.com/docs/pro/upgrading-to-pro/"

    expect(install).to include("For `--pro` or `--rsc` only")
    expect(install).to include("Skip this Pro-gem preparation for `--standard-only`")
    expect(install).to include(shakapacker, base_gem, version, pro_gem, generator)
    expect(install).to match(license_notice)
    expect(install).to include(license_link)
    expect(install).to include("unpublished prerelease")
    expect(install).to include("matching local/path `react_on_rails_pro` gem")
    expect(install).to include("Never fall back silently to a stable Pro gem")
    expect(install.index(shakapacker)).to be < install.index(base_gem)
    expect(install.index(base_gem)).to be < install.index(version)
    expect(install.index(license_notice_start)).to be < install.index(version)
    expect(install.index(version)).to be < install.index(pro_gem)
    expect(install.index(pro_gem)).to be < install.index(generator)
    expect(install).not_to match(/license entitlement/i)
  end

  it "removes only the direct base gem after either Pro source succeeds" do
    guide = gem_root.join("docs/agent/install-and-upgrade.md").read
    install = guide.match(/^## Install\n(?<body>.*?)(?=^## Upgrade$)/m)[:body]
    registry_pro_gem = %(bundle add react_on_rails_pro --version="${ROR_GEM_VERSION}" --strict)
    local_pro_gem =
      %(bundle add react_on_rails_pro --path="<path-to-matching-react_on_rails_pro>" ) +
      %(--version="${ROR_GEM_VERSION}" --strict)
    cleanup = "bundle remove react_on_rails"
    generator = "bundle exec rails generate react_on_rails:install <LANGUAGE_CHOICE> <STACK_FLAG>"

    expect(install).to include(registry_pro_gem, local_pro_gem, cleanup, generator)
    expect(install).to include("For `--pro` or `--rsc` only, after either Pro source command succeeds")
    expect(install).to include("removes only the direct `react_on_rails` declaration")
    expect(install).to match(/retains the matching base gem\s+transitively/)
    expect(install).to include("Do not run this cleanup for `--standard-only`")
    expect(install.index(registry_pro_gem)).to be < install.index(cleanup)
    expect(install.index(local_pro_gem)).to be < install.index(cleanup)
    expect(install.index(cleanup)).to be < install.index(generator)
  end

  it "previews an upgrade with the detected stack and current generator choices" do
    guide = gem_root.join("docs/agent/install-and-upgrade.md").read
    preview_command =
      "bundle exec rails generate react_on_rails:install --pretend <STACK_FLAG> <OTHER_CURRENT_CHOICES>"
    apply_command = "bundle exec rails generate react_on_rails:install <STACK_FLAG> <OTHER_CURRENT_CHOICES>"

    expect(guide).to include("Detect the app's existing stack")
    expect(guide).to include("exactly one")
    expect(guide).to include("`--standard-only`")
    expect(guide).to include("`--pro`")
    expect(guide).to include("`--rsc`")
    expect(guide).to include("Preserve every other current generator choice")
    expect(guide).to include(preview_command)
    expect(guide).to include(apply_command)
    expect(guide.index(preview_command)).to be < guide.index(apply_command)
    expect(guide).not_to include("`bundle exec rails generate react_on_rails:install`")
    expect(guide).to include("`--standard-only` for an existing OSS stack")
    expect(guide).to include("`--pro` only for an existing Pro + NodeRenderer stack")
    expect(guide).to include("`--rsc` for an existing RSC stack")
    expect(guide).to include("Pro + ExecJS has no preserving install-generator flag")
    expect(guide).to include("skip both generator preview and apply steps")
    expect(guide).to include("upgrade dependencies and configuration manually")
    expect(guide).to include("`--pretend` omits dependency installation and script effects")
    expect(guide).to include("not a complete mutation audit")
    expect(guide).to include("audit `package.json` and the JavaScript lockfile")
    expect(guide).to include("installs the generator's current dependency defaults")
    expect(guide).not_to include("`--pro` for Pro without RSC")
  end
end

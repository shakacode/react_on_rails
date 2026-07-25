# frozen_string_literal: true

require "tmpdir"
require "stringio"
require_relative "../support/generator_spec_helper"

# Golden-output coverage for the generator's serverWebpackConfig.js template (issue #4787).
#
# Why this exists
# ---------------
# The Pro and RSC standalone upgrades do not render this template. They `gsub_file` an
# existing base-install config, and their patterns are exercised in specs only against the
# hand-written simulation fixtures in support/generator_spec_helper.rb. Nothing tied those
# fixtures to what the template actually emits, so the template could move and every spec
# would stay green while real upgrades silently stopped matching (see PR #2489, which
# updated the template and one fixture and left a second fixture on the old implementation).
#
# This spec pins the real rendered output for every meaningful variant, and separately pins
# the structural anchors the upgrade transforms match on so those anchors cannot disappear
# from either the template or the simulation fixtures without a red build.
#
# ---------------------------------------------------------------------------------------
# REGENERATING THE GOLDEN FILES
#
#   cd react_on_rails && REGENERATE_GENERATOR_GOLDEN=1 \
#     bundle exec rspec spec/react_on_rails/generators/generator_golden_output_spec.rb
#
# That rewrites every file under spec/react_on_rails/fixtures/generated/ from the current
# templates and then re-asserts them, so a green run proves the round trip. Always review
# `git diff` on that directory before committing: an unreviewed regeneration defeats the
# whole point of the gate.
# ---------------------------------------------------------------------------------------
module GeneratorGoldenOutput
  GOLDEN_ROOT = File.expand_path("../fixtures/generated", __dir__)
  REGENERATE_ENV_VAR = "REGENERATE_GENERATOR_GOLDEN"
  REGENERATE_COMMAND = "cd react_on_rails && #{REGENERATE_ENV_VAR}=1 " \
                       "bundle exec rspec spec/react_on_rails/generators/generator_golden_output_spec.rb".freeze
  GENERATED_FILE = "config/webpack/serverWebpackConfig.js"

  # One entry per template branch combination that changes the emitted file.
  #
  # `shakapacker9` is stubbed rather than read from the installed gem: the template branches
  # on it, and reading the real version would make the golden files depend on whichever
  # Shakapacker the developer happens to have installed. Both branches are covered here.
  #
  # webpack and rspack produce byte-identical output unless RSC is on (only the RSC plugin
  # class name and import path differ). The rspack variants are still pinned because the
  # destination directory mapping (config/webpack -> config/rspack) is part of the contract.
  VARIANTS = [
    { name: "webpack_base", options: { rspack: false }, shakapacker9: true },
    { name: "webpack_pro", options: { rspack: false, pro: true }, shakapacker9: true },
    { name: "webpack_rsc", options: { rspack: false, rsc: true }, shakapacker9: true },
    { name: "rspack_base", options: { rspack: true }, shakapacker9: true },
    { name: "rspack_pro", options: { rspack: true, pro: true }, shakapacker9: true },
    { name: "rspack_rsc", options: { rspack: true, rsc: true }, shakapacker9: true },
    # Shakapacker < 9 swaps the privateOutputPath block for the hardcoded-path block. That
    # block is independent of --pro/--rsc, so one variant pins it.
    { name: "webpack_base_shakapacker8", options: { rspack: false }, shakapacker9: false }
  ].freeze

  module_function

  def regenerating?
    ENV.fetch(REGENERATE_ENV_VAR, nil).present?
  end

  def variant(name)
    VARIANTS.find { |candidate| candidate[:name] == name } ||
      raise(ArgumentError, "unknown golden variant #{name.inspect}")
  end

  # Relative path the generator writes to, which differs by bundler.
  def relative_path(variant)
    variant[:options][:rspack] ? GENERATED_FILE.sub("config/webpack/", "config/rspack/") : GENERATED_FILE
  end

  def golden_path(variant)
    File.join(GOLDEN_ROOT, variant[:name], relative_path(variant))
  end

  def golden(name)
    File.read(golden_path(variant(name)))
  end

  def display_path(path)
    path.sub("#{File.expand_path('../../..', __dir__)}/", "")
  end

  # Runs the real generator action (BaseGenerator#copy_webpack_config) into a throwaway
  # destination and returns the file it wrote. Deliberately not a bare ERB render: this
  # exercises the same code path a user's install takes, including the documentation-comment
  # config and the bundler-specific destination directory.
  def generate(variant)
    Dir.mktmpdir("ror-generator-golden") do |destination|
      generator = ReactOnRails::Generators::BaseGenerator.new([], variant[:options],
                                                              { destination_root: destination })
      shakapacker9 = variant[:shakapacker9]
      generator.define_singleton_method(:shakapacker_version_9_or_higher?) { shakapacker9 }

      silence_output { generator.copy_webpack_config }

      File.read(File.join(destination, relative_path(variant)))
    end
  end

  def regenerate!
    VARIANTS.each do |variant|
      path = golden_path(variant)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, generate(variant))
    end
  end

  def silence_output
    original = $stdout
    $stdout = StringIO.new
    yield
  ensure
    $stdout = original
  end

  def differ
    @differ ||= RSpec::Support::Differ.new(color: false)
  end

  def missing_golden_message(variant)
    <<~MSG
      No golden file for variant "#{variant[:name]}" at:

        #{display_path(golden_path(variant))}

      Create it by regenerating, then review the result before committing:

        #{REGENERATE_COMMAND}
    MSG
  end

  def mismatch_message(variant, actual, expected)
    <<~MSG
      Generated #{relative_path(variant)} does not match the golden file for variant "#{variant[:name]}":

        #{display_path(golden_path(variant))}

      Diff (-golden +generated):
      #{differ.diff_as_string(actual, expected)}

      If the template change is intentional, regenerate the golden files and review the diff:

        #{REGENERATE_COMMAND}
        git diff react_on_rails/spec/react_on_rails/fixtures/generated/
    MSG
  end
end

# The exact patterns the standalone Pro and RSC upgrades match on inside an existing
# serverWebpackConfig.js. Derived from the transforms themselves, not from prose:
#
#   ProSetup#add_extract_loader_to_server_config      GET_LOADER_PATH_* / BUNDLER_REQUIRE_PATTERN
#   ProSetup#update_server_webpack_config_for_pro     LIBRARY_TARGET_COMMENT / TARGET_NODE_COMMENT
#   ProSetup#add_babel_ssr_caller_to_server_config    CSS_LOADER_MODULES_BLOCK
#   ProSetup#update_server_config_exports             BASE_MODULE_EXPORTS -> PRO_MODULE_EXPORTS
#   RscSetup#update_server_webpack_config_for_rsc     CONFIGURE_SERVER_SIGNATURE / LIMIT_CHUNK_COUNT_UNSHIFT
module GeneratorTransformAnchors
  GENERATOR_ROOT = File.expand_path("../../../lib/generators/react_on_rails", __dir__)

  # Patterns that are literals inside generator methods and cannot be referenced as
  # constants, so they are copied here. The copies are pinned by the
  # "byte-identical to the generator source" example below.
  LIBRARY_TARGET_COMMENT = %r{// If using the React on Rails Pro.*\n\s*// libraryTarget: 'commonjs2',}
  # rubocop:disable Layout/LineLength
  TARGET_NODE_COMMENT = %r{\s*// If using the default 'web',.*\n\s*// break with SSR\..*\n\s*// If using the React on Rails Pro.*\n\s*// serverWebpackConfig\.target = 'node'}
  LIMIT_CHUNK_COUNT_UNSHIFT = /(serverWebpackConfig\.plugins\.unshift\(new bundler\.optimize\.LimitChunkCountPlugin.*\);)/
  # rubocop:enable Layout/LineLength
  CSS_LOADER_MODULES_BLOCK = /(cssLoader\.options\.modules = \{[\s\S]*?exportOnlyLocals: true[\s\S]*?\};\s*\n\s*\})/
  BASE_MODULE_EXPORTS = /^module\.exports = configureServer;\s*$/
  CONFIGURE_SERVER_SIGNATURE = /^const configureServer = \(\) => \{/

  # Not a gsub pattern: the scope the babel-caller insertion lands in. `extractLoader(rule, …)`
  # only works if the css-module block sits inside a rule-bound, array-guarded loop.
  RULES_FOREACH = /rules\.forEach\(\(rule\) => \{/
  RULE_USE_ARRAY_GUARD = /if \(Array\.isArray\(rule\.use\)\) \{/

  # The export shape update_server_config_exports writes, which RscSetup's
  # ServerClientOrBoth import rewrite then assumes.
  PRO_MODULE_EXPORTS = "module.exports = {\n  default: configureServer,\n  extractLoader,\n};"

  OUTPUT_PATH_ASSIGNMENT = /^\s*path: (?<identifier>[A-Za-z_$][\w$]*),$/

  BASE_INSTALL_ANCHORS = [
    { name: "bundler require block",
      matcher: ReactOnRails::Generators::ProSetup::BUNDLER_REQUIRE_PATTERN,
      source: "ProSetup::BUNDLER_REQUIRE_PATTERN" },
    { name: "shared getLoaderPath helper",
      matcher: ReactOnRails::Generators::ProSetup::GET_LOADER_PATH_JS,
      source: "ProSetup::GET_LOADER_PATH_JS" },
    { name: "getLoaderPath declaration",
      matcher: ReactOnRails::Generators::ProSetup::GET_LOADER_PATH_DECLARATION,
      source: "ProSetup::GET_LOADER_PATH_DECLARATION" },
    { name: "commented-out libraryTarget",
      matcher: LIBRARY_TARGET_COMMENT,
      source: "ProSetup#update_server_webpack_config_for_pro", source_file: "pro_setup.rb" },
    { name: "commented-out target = 'node' block",
      matcher: TARGET_NODE_COMMENT,
      source: "ProSetup#update_server_webpack_config_for_pro", source_file: "pro_setup.rb" },
    { name: "cssLoader.options.modules block",
      matcher: CSS_LOADER_MODULES_BLOCK,
      source: "ProSetup#add_babel_ssr_caller_to_server_config", source_file: "pro_setup.rb" },
    { name: "base module.exports shape",
      matcher: BASE_MODULE_EXPORTS,
      source: "ProSetup#update_server_config_exports", source_file: "pro_setup.rb" },
    { name: "configureServer signature",
      matcher: CONFIGURE_SERVER_SIGNATURE,
      source: "RscSetup#update_server_webpack_config_for_rsc", source_file: "rsc_setup.rb" },
    { name: "LimitChunkCountPlugin unshift",
      matcher: LIMIT_CHUNK_COUNT_UNSHIFT,
      source: "RscSetup#update_server_webpack_config_for_rsc", source_file: "rsc_setup.rb" }
  ].freeze

  PRO_INSTALL_ANCHORS = [
    { name: "bundler require block",
      matcher: ReactOnRails::Generators::ProSetup::BUNDLER_REQUIRE_PATTERN,
      source: "ProSetup::BUNDLER_REQUIRE_PATTERN" },
    { name: "shared getLoaderPath helper",
      matcher: ReactOnRails::Generators::ProSetup::GET_LOADER_PATH_JS,
      source: "ProSetup::GET_LOADER_PATH_JS" },
    { name: "extractLoader helper",
      matcher: ReactOnRails::Generators::ProSetup::EXTRACT_LOADER_JS,
      source: "ProSetup::EXTRACT_LOADER_JS" },
    { name: "Pro module.exports shape",
      matcher: PRO_MODULE_EXPORTS,
      source: "ProSetup#update_server_config_exports", source_file: "pro_setup.rb" },
    { name: "configureServer signature",
      matcher: CONFIGURE_SERVER_SIGNATURE,
      source: "RscSetup#update_server_webpack_config_for_rsc", source_file: "rsc_setup.rb" },
    { name: "LimitChunkCountPlugin unshift",
      matcher: LIMIT_CHUNK_COUNT_UNSHIFT,
      source: "RscSetup#update_server_webpack_config_for_rsc", source_file: "rsc_setup.rb" }
  ].freeze

  module_function

  def inline_anchors
    (BASE_INSTALL_ANCHORS + PRO_INSTALL_ANCHORS).select { |anchor| anchor[:source_file] }.uniq
  end

  def generator_source(file)
    @generator_source ||= {}
    @generator_source[file] ||= File.read(File.join(GENERATOR_ROOT, file))
  end

  # The literal text a duplicated anchor must still have in the generator source. Regexps
  # appear there as their own source; replacement strings appear with escapes intact, so
  # they are compared in dumped form minus the surrounding quotes.
  def inline_anchor_text(anchor)
    return anchor[:matcher].source if anchor[:matcher].is_a?(Regexp)

    anchor[:matcher].dump[1..-2]
  end
end

# Regenerate before the examples run so a regeneration run also asserts the round trip:
# a green run proves the command reproduces exactly what is checked in.
if GeneratorGoldenOutput.regenerating?
  GeneratorGoldenOutput.regenerate!
  warn "[golden] Rewrote #{GeneratorGoldenOutput::GOLDEN_ROOT}; review `git diff` before committing."
end

RSpec.describe "generator golden output", type: :generator do
  describe "rendered serverWebpackConfig.js" do
    GeneratorGoldenOutput::VARIANTS.each do |variant|
      it "matches the checked-in golden file for the #{variant[:name]} variant" do
        golden_path = GeneratorGoldenOutput.golden_path(variant)
        expect(File.exist?(golden_path)).to be(true),
                                            -> { GeneratorGoldenOutput.missing_golden_message(variant) }

        actual = GeneratorGoldenOutput.generate(variant)
        expected = File.read(golden_path)

        expect(actual).to eq(expected),
                          -> { GeneratorGoldenOutput.mismatch_message(variant, actual, expected) }
      end
    end

    it "emits identical output for webpack and rspack when RSC is off" do
      # The bundler is resolved at runtime from config.assets_bundler, so only the destination
      # directory differs. RSC is the one case that changes the file itself.
      expect(GeneratorGoldenOutput.golden("webpack_base")).to eq(GeneratorGoldenOutput.golden("rspack_base"))
      expect(GeneratorGoldenOutput.golden("webpack_pro")).to eq(GeneratorGoldenOutput.golden("rspack_pro"))
    end

    it "swaps only the RSC plugin class and import path between webpack and rspack" do
      webpack_rsc = GeneratorGoldenOutput.golden("webpack_rsc")
      rspack_rsc = GeneratorGoldenOutput.golden("rspack_rsc")

      expect(webpack_rsc).to include("RSCWebpackPlugin", "react-on-rails-rsc/WebpackPlugin")
      expect(rspack_rsc).to include("RSCRspackPlugin", "react-on-rails-rsc/RspackPlugin")
      expect(webpack_rsc.gsub("RSCWebpackPlugin", "RSCRspackPlugin")
                        .gsub("react-on-rails-rsc/WebpackPlugin", "react-on-rails-rsc/RspackPlugin"))
        .to eq(rspack_rsc)
    end
  end

  # The simulation fixtures in support/generator_spec_helper.rb are deliberately simplified
  # stand-ins for a pre-existing user file, and some deliberately represent OLDER installs.
  # They are therefore NOT asserted to match the golden output byte for byte.
  #
  # What must not drift is narrower: the exact patterns the Pro and RSC standalone upgrades
  # match on. Each anchor is asserted against both the real generated file and the fixture the
  # corresponding transform is exercised against, so a template change that moves an anchor is
  # red even though the fixtures stay simplified.
  describe "structural anchors shared by the golden output and the simulation fixtures" do
    def expect_anchor(anchor, subjects)
      subjects.each do |label, content|
        message = "#{anchor[:name]} (#{anchor[:source]}) is missing from #{label}"
        if anchor[:matcher].is_a?(Regexp)
          expect(content).to match(anchor[:matcher]), message
        else
          expect(content).to include(anchor[:matcher]), message
        end
      end
    end

    GeneratorTransformAnchors::BASE_INSTALL_ANCHORS.each do |anchor|
      it "keeps the #{anchor[:name]} anchor in the base golden output and base simulation fixture" do
        # simulate_base_webpack_files feeds base_server_webpack_content to the ProGenerator specs.
        expect_anchor(anchor,
                      "golden webpack_base" => GeneratorGoldenOutput.golden("webpack_base"),
                      "base_server_webpack_content" => base_server_webpack_content)
      end
    end

    GeneratorTransformAnchors::PRO_INSTALL_ANCHORS.each do |anchor|
      it "keeps the #{anchor[:name]} anchor in the Pro golden output and Pro simulation fixture" do
        # simulate_pro_webpack_files feeds pro_server_webpack_content to the RscGenerator specs.
        expect_anchor(anchor,
                      "golden webpack_pro" => GeneratorGoldenOutput.golden("webpack_pro"),
                      "pro_server_webpack_content" => pro_server_webpack_content)
      end
    end

    it "keeps every inline anchor copy byte-identical to the generator source it mirrors" do
      # These anchors are literals inside generator methods, so they cannot be referenced as
      # constants and have to be duplicated above. This pins the duplication: editing the
      # pattern in the generator without editing this spec is red.
      GeneratorTransformAnchors.inline_anchors.each do |anchor|
        source_text = GeneratorTransformAnchors.generator_source(anchor[:source_file])

        expect(source_text).to include(GeneratorTransformAnchors.inline_anchor_text(anchor)),
                               "#{anchor[:name]} no longer appears verbatim in #{anchor[:source_file]}; " \
                               "update the copy in this spec to match the generator."
      end
    end

    it "keeps the css-module anchor inside a rule-bound, array-guarded rule.use loop" do
      # add_babel_ssr_caller_to_server_config inserts `extractLoader(rule, 'babel-loader')`
      # immediately after the css-module block. That inserted code only works if the block sits
      # inside `rules.forEach((rule) => { if (Array.isArray(rule.use)) { … } })`, which is the
      # real contract behind the "rule.use filter loops" anchor.
      { "golden webpack_base" => GeneratorGoldenOutput.golden("webpack_base"),
        "base_server_webpack_content" => base_server_webpack_content }.each do |label, content|
        rules_loop = content.index(GeneratorTransformAnchors::RULES_FOREACH)
        array_guard = content.index(GeneratorTransformAnchors::RULE_USE_ARRAY_GUARD)
        css_modules = content.index(GeneratorTransformAnchors::CSS_LOADER_MODULES_BLOCK)

        expect([rules_loop, array_guard, css_modules]).to all(be_a(Integer)),
                                                          "#{label} is missing part of the rule.use loop structure"
        expect(rules_loop).to be < array_guard, "#{label}: Array.isArray(rule.use) guard is outside rules.forEach"
        expect(array_guard).to be < css_modules, "#{label}: css-module block is outside the rule.use guard"
      end
    end

    describe "getLoaderPath fallback branches" do
      # add_extract_loader_to_server_config picks one of three branches. Each simulation fixture
      # exists to exercise a specific branch, so pin which branch each one lands in.
      it "routes base_server_webpack_content through the exact-helper branch" do
        expect(base_server_webpack_content).to include(ReactOnRails::Generators::ProSetup::GET_LOADER_PATH_JS)
      end

      it "routes customized_base_server_webpack_content through the reuse-declaration branch" do
        content = customized_base_server_webpack_content

        expect(content).not_to include(ReactOnRails::Generators::ProSetup::GET_LOADER_PATH_JS)
        expect(content).to match(ReactOnRails::Generators::ProSetup::GET_LOADER_PATH_DECLARATION)
      end

      it "routes legacy_base_server_webpack_content_pre_get_loader_path through the emit-both branch" do
        content = legacy_base_server_webpack_content_pre_get_loader_path

        expect(content).not_to match(ReactOnRails::Generators::ProSetup::GET_LOADER_PATH_DECLARATION)
        expect(content).to match(ReactOnRails::Generators::ProSetup::BUNDLER_REQUIRE_PATTERN)
      end
    end
  end

  # Reported on PR #4788 and named in issue #4787: base_server_webpack_content referenced
  # serverBundleOutputPath without ever declaring it, so the simulated config could not have run
  # in Node. A fixture that is not self-consistent is a weak stand-in for a real user file.
  describe "simulation fixture self-consistency" do
    %i[
      base_server_webpack_content
      legacy_base_server_webpack_content_pre_get_loader_path
      customized_base_server_webpack_content
    ].each do |fixture_method|
      it "declares every identifier #{fixture_method} uses as an output path" do
        content = send(fixture_method)
        identifiers = content.scan(GeneratorTransformAnchors::OUTPUT_PATH_ASSIGNMENT).flatten

        expect(identifiers).not_to eq([]),
                                   "#{fixture_method} no longer has an output.path assignment to check"
        identifiers.each do |identifier|
          declaration = content.index(/(?:const|let|var)\s+#{Regexp.escape(identifier)}\s*=/)
          usage = content.index(/path: #{Regexp.escape(identifier)},/)

          expect(declaration).to be_a(Integer),
                                 "#{fixture_method} uses `#{identifier}` as output.path but never declares it"
          expect(declaration).to be < usage, "#{fixture_method} declares `#{identifier}` after using it"
        end
      end
    end
  end
end

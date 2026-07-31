# frozen_string_literal: true

require "tmpdir"
require "stringio"
require_relative "../support/generator_spec_helper"
require_relative "../support/generated_tree_approval"

# Golden-output coverage for the generator's complete bundler configuration tree (issue #4787).
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
# This spec pins every file in the final generated config tree for each meaningful variant.
# It separately pins the structural anchors the upgrade transforms match on so those anchors
# cannot disappear from either the template or the simulation fixtures without a red build.
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
  GENERATED_CONFIG_ROOT = "config"
  SERVER_CONFIG = "serverWebpackConfig.js"

  # One entry per template branch combination that changes the emitted tree.
  #
  # `shakapacker9` is stubbed rather than read from the installed gem: the template branches
  # on it, and reading the real version would make the golden files depend on whichever
  # Shakapacker the developer happens to have installed. Both branches are covered here.
  #
  # Tailwind changes only commonWebpackConfig.js, so one variant covers that independent branch
  # without multiplying it across every product and bundler combination.
  VARIANTS = [
    { name: "webpack_base", options: { rspack: false }, shakapacker9: true },
    { name: "webpack_pro", options: { rspack: false, pro: true }, shakapacker9: true },
    { name: "webpack_rsc", options: { rspack: false, rsc: true }, shakapacker9: true },
    { name: "webpack_tailwind", options: { rspack: false, tailwind: true }, shakapacker9: true },
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

  def approved_root(variant)
    File.join(GOLDEN_ROOT, variant[:name], GENERATED_CONFIG_ROOT)
  end

  def bundler_config_dir(variant)
    variant[:options][:rspack] ? "rspack" : "webpack"
  end

  def server_config_path(variant)
    File.join(approved_root(variant), bundler_config_dir(variant), SERVER_CONFIG)
  end

  def golden(name)
    File.read(server_config_path(variant(name)))
  end

  def display_path(path)
    path.sub("#{File.expand_path('../../..', __dir__)}/", "")
  end

  # Runs the real config generation lifecycle into a throwaway destination and yields its
  # config root. Pro and RSC use their production transformation methods so the approved tree
  # represents the final installation state, not only the initial template render.
  def generate(variant)
    Dir.mktmpdir("ror-generator-golden") do |destination|
      generator = generator_for(ReactOnRails::Generators::BaseGenerator, variant, destination)
      shakapacker9 = variant[:shakapacker9]
      generator.define_singleton_method(:shakapacker_version_9_or_higher?) { shakapacker9 }

      silence_output do
        generator.copy_webpack_config
        apply_pro_config(variant, destination) if variant[:options][:pro] || variant[:options][:rsc]
        apply_rsc_config(variant, destination) if variant[:options][:rsc]
      end

      yield File.join(destination, GENERATED_CONFIG_ROOT)
    end
  ensure
    GeneratorMessages.clear
  end

  def regenerate!
    VARIANTS.each do |variant|
      generate(variant) do |actual_root|
        GeneratedTreeApproval.regenerate(actual_root, approved_root(variant))
      end
    end
  end

  def generator_for(generator_class, variant, destination)
    generator_class.new([], variant[:options], { destination_root: destination }).tap do |generator|
      rspack = variant[:options][:rspack]
      generator.define_singleton_method(:using_rspack?) { rspack }
    end
  end

  def apply_pro_config(variant, destination)
    generator = generator_for(ReactOnRails::Generators::ProGenerator, variant, destination)
    generator.__send__(:update_webpack_config_for_pro)
  end

  def apply_rsc_config(variant, destination)
    generator = generator_for(ReactOnRails::Generators::RscGenerator, variant, destination)
    generator.__send__(:create_rsc_webpack_config)
    generator.__send__(:update_webpack_configs_for_rsc)
  end

  def silence_output
    original = $stdout
    $stdout = StringIO.new
    yield
  ensure
    $stdout = original
  end

  def mismatch_message(variant, comparison)
    <<~MSG
      Generated config tree does not match the approved tree for variant "#{variant[:name]}":

        #{display_path(approved_root(variant))}

      #{comparison.failure_message(differ: RSpec::Support::Differ.new(color: false))}

      If the generated-output change is intentional, regenerate the approved trees and review the diff:

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

  # Not gsub patterns: the scope the babel-caller insertion lands in. `extractLoader(rule, …)`
  # only works if the css-module block sits inside a rule-bound, array-guarded loop. These are
  # used for real block-range matching, never for comparing byte offsets — see
  # GeneratorJsStructure for why offsets are not sufficient.
  RULES_FOREACH = /rules\.forEach\(\(rule\) => \{/
  RULE_USE_ARRAY_GUARD = /if \(Array\.isArray\(rule\.use\)\) \{/

  # What ProSetup#add_babel_ssr_caller_to_server_config inserts, and the marker its own
  # read-back check looks for.
  BABEL_CALLER_INSERTION = "const babelLoader = extractLoader(rule, 'babel-loader');"
  BABEL_CALLER_MARKER = "babelLoader.options.caller = { ssr: true }"

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

# Minimal brace matcher for the generated JS, used to prove real block *nesting*.
#
# An earlier version of this spec compared byte offsets (`rules.forEach` appears before
# `Array.isArray(rule.use)` appears before the css-module block). That is only a proxy, and a
# weak one: a template refactor that CLOSES the forEach or the array guard before the
# css-module block leaves all three tokens in the same relative order, so the offset check
# still passes while the Pro transform inserts `extractLoader(rule, …)` at a point where
# `rule` is out of scope. That matters most for the simulation fixtures, which are allowed to
# drift from current output — a fixture could keep satisfying token order while no longer
# representing a structure the transform can operate on, which is the exact drift class #4787
# exists to close. So nesting is verified structurally instead.
module GeneratorJsStructure
  module_function

  # Range covering the block opened by the first `{` at or after `pattern`, or nil.
  def block_range(content, pattern)
    start = content.index(pattern)
    return nil unless start

    open_index = content.index("{", start)
    return nil unless open_index

    close_index = matching_brace(content, open_index)
    return nil unless close_index

    (open_index..close_index)
  end

  QUOTES = ["'", '"', "`"].freeze

  # Index of the `}` matching the `{` at open_index, skipping braces that appear inside
  # comments and string literals (the generated config has both, including a template
  # literal containing `${serverBundleOutputPath}`).
  def matching_brace(content, open_index)
    depth = 0
    index = open_index

    while index < content.length
      skipped = skip_non_code(content, index)
      if skipped
        index = skipped
        next
      end

      case content[index]
      when "{"
        depth += 1
      when "}"
        depth -= 1
        return index if depth.zero?
      end
      index += 1
    end

    nil
  end

  # Index just past the comment or string literal starting at `index`, or nil when `index`
  # is ordinary code. Always advances, so callers cannot spin.
  def skip_non_code(content, index)
    return content.index("\n", index) || content.length if line_comment?(content, index)
    return (content.index("*/", index + 2) || content.length) + 2 if block_comment?(content, index)
    return end_of_string(content, index) if QUOTES.include?(content[index])

    nil
  end

  def line_comment?(content, index)
    content[index] == "/" && content[index + 1] == "/"
  end

  def block_comment?(content, index)
    content[index] == "/" && content[index + 1] == "*"
  end

  # Index just past the closing quote. Backtick strings are treated as opaque through to the
  # closing backtick, which is correct here because no template literal in these files nests
  # another backtick.
  def end_of_string(content, start)
    quote = content[start]
    index = start + 1

    while index < content.length
      return index + 1 if content[index] == quote

      index += content[index] == "\\" ? 2 : 1
    end

    content.length
  end
end

# Drives the real standalone Pro transforms over arbitrary config content, so the spec tests
# what ProSetup actually does to a file rather than asserting on a proxy for it.
module GeneratorProTransform
  module_function

  RELATIVE_CONFIG = "config/webpack/serverWebpackConfig.js"

  # Applies ProSetup's two rule-scope-sensitive transforms and returns the patched file.
  def apply(content)
    Dir.mktmpdir("ror-pro-transform") do |destination|
      path = File.join(destination, RELATIVE_CONFIG)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, content)

      generator = ReactOnRails::Generators::ProGenerator.new([], {}, { destination_root: destination })
      generator.instance_variable_set(:@shell, Thor::Shell::Basic.new)

      GeneratorGoldenOutput.silence_output do
        generator.__send__(:add_extract_loader_to_server_config, RELATIVE_CONFIG, content)
        generator.__send__(:add_babel_ssr_caller_to_server_config, RELATIVE_CONFIG, File.read(path))
      end

      File.read(path)
    end
  end
end

# Regenerate before the examples run so a regeneration run also asserts the round trip:
# a green run proves the command reproduces exactly what is checked in.
if GeneratorGoldenOutput.regenerating?
  GeneratorGoldenOutput.regenerate!
  warn "[golden] Rewrote #{GeneratorGoldenOutput::GOLDEN_ROOT}; review `git diff` before committing."
end

RSpec.describe "generator golden output", type: :generator do
  describe "generated configuration trees" do
    GeneratorGoldenOutput::VARIANTS.each do |variant|
      it "matches the approved tree for the #{variant[:name]} variant" do
        GeneratorGoldenOutput.generate(variant) do |actual_root|
          comparison = GeneratedTreeApproval.compare(
            actual_root,
            GeneratorGoldenOutput.approved_root(variant)
          )

          expect(comparison.match?).to be(true),
                                       -> { GeneratorGoldenOutput.mismatch_message(variant, comparison) }
        end
      end
    end

    it "has exactly one approved directory per variant and no orphan variants" do
      # Regeneration replaces known variants but leaves removed or renamed directories intact.
      # This example requires explicit review before deleting an orphaned approval.
      on_disk = Dir.children(GeneratorGoldenOutput::GOLDEN_ROOT)
                   .select { |entry| File.directory?(File.join(GeneratorGoldenOutput::GOLDEN_ROOT, entry)) }
                   .sort
      expected = GeneratorGoldenOutput::VARIANTS.map { |variant| variant[:name] }.sort

      expect(on_disk).to eq(expected),
                         "approved directories do not match VARIANTS. Remove stale variant directories " \
                         "after confirming they are no longer part of the generator contract."
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

    # Runs the REAL standalone Pro transform over each target and checks where its output
    # landed. Token ordering is not enough: closing the forEach or the array guard early
    # keeps the tokens in order while putting `rule` out of scope at the insertion point.
    # See GeneratorJsStructure for the full rationale.
    {
      "golden webpack_base" => -> { GeneratorGoldenOutput.golden("webpack_base") },
      "base_server_webpack_content" => -> { base_server_webpack_content }
    }.each do |label, source|
      it "inserts the Pro babel caller inside the rule scope when transforming #{label}" do
        patched = GeneratorProTransform.apply(instance_exec(&source))

        expect(patched).to include(GeneratorTransformAnchors::BABEL_CALLER_MARKER),
                           "the Pro babel transform did not apply to #{label} at all"

        insertion = patched.index(GeneratorTransformAnchors::BABEL_CALLER_INSERTION)
        expect(insertion).to be_a(Integer), "#{label}: could not locate the inserted extractLoader call"

        rules_loop = GeneratorJsStructure.block_range(patched, GeneratorTransformAnchors::RULES_FOREACH)
        array_guard = GeneratorJsStructure.block_range(patched, GeneratorTransformAnchors::RULE_USE_ARRAY_GUARD)

        expect(rules_loop).to be_a(Range), "#{label}: could not find a balanced rules.forEach block"
        expect(array_guard).to be_a(Range), "#{label}: could not find a balanced Array.isArray(rule.use) block"
        expect(rules_loop).to cover(insertion),
                              "#{label}: the inserted extractLoader(rule, …) call is OUTSIDE rules.forEach, " \
                              "so `rule` is not in scope and the generated config is broken"
        expect(array_guard).to cover(insertion),
                               "#{label}: the inserted extractLoader(rule, …) call is OUTSIDE the " \
                               "Array.isArray(rule.use) guard, so rule.use may not be an array"
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

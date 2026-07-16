#!/usr/bin/env ruby
# frozen_string_literal: true

require "find"
require "open3"
require "optparse"
require "pathname"
require "yaml"
require_relative "../skills/pr-batch/lib/git_probe_env"

module AgentWorkflowDriftManifest
  module_function

  REVISION_PATTERN = /\A[0-9a-f]{40}\z/i

  REQUIRED_EXPLICIT_PATHS = %w[
    .rubocop.yml
    bin/agent-workflow-seam-doctor
    bin/agent-workflow-seam-doctor-test.rb
    bin/validate
    docs/adoption.md
    docs/coordination-backend.md
    docs/installation-and-upgrades.md
    docs/issue-evaluation.md
    docs/pr-batch-skills.md
    docs/release-branching.md
    docs/seam-design.md
    docs/security-posture.md
    skills/pr-batch/trusted-github-actors.yml
  ].freeze

  GOVERNED_PREFIXES = %w[
    workflows/
    skills/address-review/bin/
    skills/plan-pr-batch/bin/
    skills/plan-pr-batch/scripts/
    skills/post-merge-audit/bin/
    skills/pr-batch/bin/
    skills/pr-batch/lib/
    skills/update-changelog/bin/
  ].freeze

  EXCLUSIONS = {
    "skills/post-merge-audit/bin/post-merge-audit-policy-test.rb" =>
      "Source-pack contract test exercises installed-skill policy and is not a consumer runtime helper.",
    "skills/pr-batch/bin/goal-completion-contract-test.rb" =>
      "Source-pack contract test validates packaged goal templates that remain installed-skill-owned.",
    "skills/pr-batch/bin/model-routing-contract-test.rb" =>
      "Source-pack contract test validates packaged model-routing guidance that remains installed-skill-owned.",
    "skills/pr-batch/bin/single_target_entrypoint_test.rb" =>
      "Source-pack contract test validates installed single-target entrypoints and is not vendored here."
  }.freeze

  def run(manifest_path:, source_root:, consumer_root:, output: $stdout)
    errors = []
    manifest = load_manifest(manifest_path, errors)
    revision = source_revision(manifest, errors)
    mapped_sources = mapped_pairs(manifest, errors).map(&:first).uniq.sort
    source_files = revision ? pinned_source_files(source_root, revision, errors) : []
    consumer_files = consumer_agent_files(consumer_root, errors)

    validate_source_head(source_root, revision, errors) if revision
    validate_exclusions(source_files, errors)
    validate_inventory(source_files, consumer_files, mapped_sources, errors)

    if errors.empty?
      output.puts "AGENT_WORKFLOW_MANIFEST_COMPLETENESS_OK mapped=#{mapped_sources.length} excluded=#{EXCLUSIONS.length}"
      return 0
    end

    output.puts "AGENT_WORKFLOW_MANIFEST_COMPLETENESS_FAIL (#{errors.uniq.length})"
    errors.uniq.sort.each { |error| output.puts "  - #{error}" }
    1
  end

  def load_manifest(path, errors)
    data = YAML.safe_load(File.binread(path), permitted_classes: [], permitted_symbols: [], aliases: false)
    unless data.is_a?(Hash)
      errors << "manifest must be a YAML mapping"
      return {}
    end

    data
  rescue Psych::Exception => e
    errors << "manifest YAML is invalid: #{e.message.lines.first.strip}"
    {}
  rescue SystemCallError => e
    errors << "manifest is unreadable: #{path} (#{e.class.name})"
    {}
  end

  def source_revision(manifest, errors)
    errors << "manifest version must be 1" unless manifest["version"] == 1
    revision = manifest["source_revision"]
    unless revision.is_a?(String) && revision.match?(REVISION_PATTERN)
      errors << "manifest source_revision must be a full 40-hex commit"
      return nil
    end

    revision.downcase
  end

  def mapped_pairs(manifest, errors)
    entries = manifest["files"]
    unless entries.is_a?(Array)
      errors << "manifest files must be a sequence"
      return []
    end

    pairs = entries.each_with_index.filter_map do |entry, index|
      unless entry.is_a?(Hash) && entry["source"].is_a?(String) && !entry["source"].empty?
        errors << "manifest files[#{index}] must have a nonempty source path"
        next
      end

      source = entry["source"]
      consumer = entry["consumer"]
      unless consumer.is_a?(String) && !consumer.empty?
        errors << "manifest files[#{index}] must have a nonempty consumer path"
        next
      end

      expected_consumer = ".agents/#{source}"
      if consumer != expected_consumer
        errors << "manifest consumer path must match source path: #{source} -> #{consumer}"
      end
      [source, consumer]
    end
    paths = pairs.map(&:first)
    duplicates = paths.group_by(&:itself).select { |_path, copies| copies.length > 1 }.keys
    errors.concat(duplicates.sort.map { |path| "manifest maps source path more than once: #{path}" })
    pairs.sort
  end

  def pinned_source_files(root, revision, errors)
    stdout, stderr, status = git_capture(root, "ls-tree", "-r", "--name-only", "-z", revision)
    unless status.success?
      errors << "cannot enumerate pinned source tree #{revision}: #{stderr.strip}"
      return []
    end

    stdout.split("\0").reject(&:empty?).sort
  end

  def validate_source_head(root, revision, errors)
    stdout, stderr, status = git_capture(root, "rev-parse", "--verify", "HEAD^{commit}")
    unless status.success?
      errors << "source root is not a Git checkout: #{stderr.strip}"
      return
    end

    head = stdout.strip.downcase
    errors << "source HEAD differs from manifest revision: expected #{revision}, found #{head}" unless head == revision
  end

  def git_capture(root, *arguments)
    Open3.capture3(
      PrBatchGitProbeEnv.probe_env,
      "git",
      "--no-replace-objects",
      "-C",
      root,
      *arguments
    )
  rescue SystemCallError => e
    ["", e.message, Struct.new(:success?).new(false)]
  end

  def consumer_agent_files(root, errors)
    agents_root = File.join(root, ".agents")
    unless File.directory?(agents_root)
      errors << "consumer .agents directory is missing: #{agents_root}"
      return []
    end

    paths = []
    Find.find(agents_root) do |path|
      next if path == agents_root || File.directory?(path)

      paths << Pathname.new(path).relative_path_from(Pathname.new(agents_root)).to_s
    end
    paths.sort
  rescue SystemCallError => e
    errors << "consumer .agents inventory is unreadable: #{e.message}"
    []
  end

  def validate_exclusions(source_files, errors)
    EXCLUSIONS.sort.each do |path, reason|
      errors << "excluded source path is absent at the pinned revision: #{path}" unless source_files.include?(path)
      errors << "excluded source path has no reviewed reason: #{path}" if reason.strip.empty?
    end
  end

  def validate_inventory(source_files, consumer_files, mapped_sources, errors)
    governed = source_files.select do |path|
      REQUIRED_EXPLICIT_PATHS.include?(path) || GOVERNED_PREFIXES.any? { |prefix| path.start_with?(prefix) }
    end
    expected_sources = (governed - EXCLUSIONS.keys).sort
    same_path_intersection = (source_files & consumer_files).sort

    append_set_differences(errors, "required governed source is not mapped", expected_sources - mapped_sources)
    append_set_differences(errors, "manifest maps source outside the governed inventory", mapped_sources - expected_sources)
    append_set_differences(errors, "same-path consumer source is not mapped", same_path_intersection - mapped_sources)
    append_set_differences(errors, "mapped source has no same-path consumer file", mapped_sources - same_path_intersection)
    append_set_differences(
      errors,
      "required explicit source path is absent at the pinned revision",
      REQUIRED_EXPLICIT_PATHS - source_files
    )
  end

  def append_set_differences(errors, label, paths)
    errors.concat(paths.sort.map { |path| "#{label}: #{path}" })
  end
end

if $PROGRAM_NAME == __FILE__
  consumer_root = File.expand_path("../..", __dir__)
  options = {
    manifest_path: File.join(consumer_root, ".agents", "agent-workflow-drift.yml"),
    consumer_root:
  }
  parser = OptionParser.new do |opts|
    opts.banner = "Usage: agent-workflow-drift-manifest-test.rb --source-root DIR [options]"
    opts.on("--source-root DIR", "Pinned agent-workflows checkout") { |value| options[:source_root] = File.expand_path(value) }
    opts.on("--manifest FILE", "Consumer drift manifest") { |value| options[:manifest_path] = File.expand_path(value) }
    opts.on("--consumer-root DIR", "Consumer repository checkout") { |value| options[:consumer_root] = File.expand_path(value) }
  end

  begin
    parser.parse!
    raise OptionParser::MissingArgument, "--source-root" unless options.key?(:source_root)
    raise OptionParser::InvalidOption, ARGV.join(" ") unless ARGV.empty?
  rescue OptionParser::ParseError => e
    warn e.message
    warn parser
    exit 2
  end

  exit AgentWorkflowDriftManifest.run(**options)
end

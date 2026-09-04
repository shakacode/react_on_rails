# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require_relative "spec_helper"
require_relative "support/generated_tree_approval"

RSpec.describe GeneratedTreeApproval do
  let(:root) { Dir.mktmpdir("generated-tree-approval") }
  let(:actual_root) { File.join(root, "actual") }
  let(:approved_root) { File.join(root, "approved") }

  before do
    FileUtils.mkdir_p(actual_root)
    FileUtils.mkdir_p(approved_root)
  end

  after { FileUtils.rm_rf(root) }

  it "detects every kind of generated-tree drift" do
    File.write(File.join(actual_root, ".generated-metadata"), "actual metadata\n")
    File.write(File.join(actual_root, "added.js"), "added\n")
    File.write(File.join(actual_root, "changed.js"), "generated\n")
    File.write(File.join(approved_root, "changed.js"), "approved\n")
    File.write(File.join(approved_root, "removed.js"), "removed\n")

    comparison = described_class.compare(actual_root, approved_root)

    expect(comparison).not_to be_match
    expect(comparison.added).to eq([".generated-metadata", "added.js"])
    expect(comparison.removed).to eq(["removed.js"])
    expect(comparison.changed).to eq(["changed.js"])

    failure_message = comparison.failure_message(differ: RSpec::Support::Differ.new(color: false))
    expect(failure_message).to include("Added files:", "+ .generated-metadata", "+ added.js")
    expect(failure_message).to include("Removed files:", "- removed.js")
    expect(failure_message).to include("Changed file: changed.js", "-approved", "+generated")
  end

  it "replaces an approved tree instead of retaining stale files" do
    nested_actual = File.join(actual_root, "config", "webpack")
    FileUtils.mkdir_p(nested_actual)
    File.write(File.join(nested_actual, "webpack.config.js"), "module.exports = {};\n")
    File.write(File.join(approved_root, "stale.js"), "stale\n")

    described_class.regenerate(actual_root, approved_root)

    expect(described_class.compare(actual_root, approved_root)).to be_match
    expect(File.exist?(File.join(approved_root, "stale.js"))).to be(false)
  end
end

# frozen_string_literal: true

require "fileutils"

module GeneratedTreeApproval
  class Comparison
    attr_reader :actual, :approved

    def initialize(actual:, approved:)
      @actual = actual
      @approved = approved
    end

    def match?
      added.empty? && removed.empty? && changed.empty?
    end

    def added
      actual.keys - approved.keys
    end

    def removed
      approved.keys - actual.keys
    end

    def changed
      (actual.keys & approved.keys).reject { |path| actual[path] == approved[path] }
    end

    def failure_message(differ:)
      sections = []
      sections << path_section("Added files", added, "+") if added.any?
      sections << path_section("Removed files", removed, "-") if removed.any?
      sections.concat(changed.map { |path| changed_file_section(path, differ) })
      sections.join("\n\n")
    end

    private

    def path_section(title, paths, marker)
      "#{title}:\n#{paths.map { |path| "  #{marker} #{path}" }.join("\n")}"
    end

    def changed_file_section(path, differ)
      "Changed file: #{path}\n#{differ.diff_as_string(actual.fetch(path), approved.fetch(path))}"
    end
  end

  module_function

  def compare(actual_root, approved_root)
    Comparison.new(actual: snapshot(actual_root), approved: snapshot(approved_root))
  end

  def regenerate(actual_root, approved_root)
    FileUtils.rm_rf(approved_root)
    FileUtils.mkdir_p(File.dirname(approved_root))
    FileUtils.cp_r(actual_root, approved_root)
  end

  def snapshot(root)
    return {} unless File.directory?(root)

    Dir.glob(File.join(root, "**", "*"), File::FNM_DOTMATCH)
       .select { |path| File.file?(path) }
       .sort
       .to_h { |path| [path.delete_prefix("#{root}/"), File.binread(path)] }
  end
  private_class_method :snapshot
end

# frozen_string_literal: true

require 'appraisal/bundler_dsl'
::Appraisal::BundlerDSL.class_eval do
  def eval_gemfile(path, contents = nil)
    (@eval_gemfile ||= []) << [path, contents]
  end

  private

  def eval_gemfile_entry
    @eval_gemfile.map { |(p, c)| "eval_gemfile(#{p.inspect}#{", #{c.inspect}" if c})" } * "\n\n"
  end

  alias_method :eval_gemfile_entry_for_dup, :eval_gemfile_entry

  self::PARTS << 'eval_gemfile'
end unless ::Appraisal::BundlerDSL::PARTS[-1] == 'eval_gemfile'

source "https://rubygems.org"

gem "appraisal"
# Specify your gem"s dependencies in react_on_rails.gemspec
gemspec

eval_gemfile File.expand_path("./Gemfile.development_dependencies", __dir__)

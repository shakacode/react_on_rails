# frozen_string_literal: true

# Spike benchmark for issue #3313.
#
# Compares parse + rewrite time of the Prism prototype against the current
# scanner from lib/react_on_rails/pro_migration.rb on representative Gemfile sizes.
#
# Run with:
#   bundle exec ruby spike/3313_prism_gemfile_rewriter/benchmark.rb

$LOAD_PATH.unshift(File.expand_path(__dir__))
$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))

require "prism_gemfile_rewriter"
require "react_on_rails/pro_migration"

def measure(iterations)
  start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  iterations.times { yield }
  finish = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  finish - start
end

# Approximates what swap_base_gem_for_pro_in_gemfile does, isolated from the generator
# so we can time the rewrite path without Thor / Bundler overhead.
class ScannerRewriter
  PRO_VERSION = "~> 16.7"

  def rewrite(source)
    has_pro_gem = ReactOnRails::ProMigration.pro_gem_entry?(source)
    lines = source.lines
    updated = []
    base_found = false
    line_index = 0

    while line_index < lines.length
      line = lines[line_index]
      base_decl = ReactOnRails::ProMigration.base_gem_declaration_at(lines, line_index)

      unless base_decl
        updated << line
        line_index += 1
        next
      end

      base_found = true
      unless has_pro_gem
        updated << build_replacement(base_decl)
      end
      line_index = base_decl[:next_index]
    end

    [updated.join, base_found]
  end

  private

  def build_replacement(base_decl)
    indentation = base_decl[:indentation]
    quote = base_decl[:quote]
    suffix = base_decl[:trailing_suffix] || "\n"
    suffix += "\n" unless suffix.end_with?("\n")
    has_pin = suffix.match?(/\A\s*,\s*(?:#[^\n]*\n\s*)*["']/)
    version_arg = has_pin ? "" : ", #{quote}#{PRO_VERSION}#{quote}"

    if base_decl[:parenthesized_gem_call]
      suffix = strip_close_paren(suffix)
    end
    suffix = "\n" if suffix.match?(/\A,\s*\n\z/)
    "#{indentation}gem #{quote}react_on_rails_pro#{quote}#{version_arg}#{suffix}"
  end

  def strip_close_paren(suffix)
    # Simplified: drop the first `)` we see; not equivalent to the production code,
    # but adequate for benchmarking on inputs that do not stress this path.
    suffix.sub(/\)/, "").gsub(/\n\s*\n/, "\n")
  end
end

GEMFILES = {
  "small (10 lines, 1 ror entry)" => <<~RUBY,
    source "https://rubygems.org"
    gem "rails", "~> 7.1"
    gem "puma"
    gem "react_on_rails", "~> 16.0"
    gem "sprockets-rails"
    gem "importmap-rails"
    gem "turbo-rails"
    gem "stimulus-rails"
    gem "jbuilder"
    gem "bcrypt"
  RUBY
  "medium (80 lines, 1 ror entry, groups)" => begin
    body = +"source \"https://rubygems.org\"\n"
    base_gems = %w[
      rails puma sprockets-rails importmap-rails turbo-rails stimulus-rails
      jbuilder bcrypt bootsnap kredis
    ]
    base_gems.each do |g|
      body << "gem \"#{g}\"\n"
    end
    body << "gem \"react_on_rails\", \"~> 16.0\"\n"
    %w[pg redis sidekiq devise pundit kaminari rack-cors dotenv-rails].each do |g|
      body << "gem \"#{g}\"\n"
    end
    body << "\ngroup :development, :test do\n"
    %w[rspec-rails factory_bot_rails faker pry-rails pry-byebug debug].each do |g|
      body << "  gem \"#{g}\"\n"
    end
    body << "end\n\ngroup :development do\n"
    %w[web-console listen spring spring-watcher-listen rubocop rubocop-rails].each do |g|
      body << "  gem \"#{g}\"\n"
    end
    body << "end\n\ngroup :test do\n"
    %w[capybara selenium-webdriver webdrivers shoulda-matchers].each { |g| body << "  gem \"#{g}\"\n" }
    body << "end\n"
    body
  end,
  "large (~300 lines, scaled fixture)" => begin
    body = +"source \"https://rubygems.org\"\n"
    250.times { |i| body << "gem \"library_#{i}\"\n" }
    body << "gem \"react_on_rails\", \"~> 16.0\"\n"
    50.times { |i| body << "gem \"util_#{i}\"\n" }
    body
  end
}.freeze

ITERATIONS = 200
WARMUP_ITERATIONS = 3

puts "Prism vs. scanner Gemfile rewrite benchmark (#{ITERATIONS} iterations per case)\n\n"
puts "Ruby: #{RUBY_VERSION}, Prism: #{Prism::VERSION}\n\n"

prism = ReactOnRails::Spike::PrismGemfileRewriter.new(default_pro_version: ScannerRewriter::PRO_VERSION)
scanner = ScannerRewriter.new

# One measurement pass per fixture; we derive both the totals/ratio table and
# the per-rewrite cost table from the same timings so the two views stay
# consistent. Re-warming and re-measuring between tables (as we used to do)
# introduced cross-table variance from JIT/cache state drift.
results = GEMFILES.map do |label, src|
  WARMUP_ITERATIONS.times do
    scanner.rewrite(src)
    prism.rewrite(src)
  end

  scanner_seconds = measure(ITERATIONS) { scanner.rewrite(src) }
  prism_seconds = measure(ITERATIONS) { prism.rewrite(src) }
  {
    label: "#{label} (#{src.lines.size}l)",
    scanner_seconds: scanner_seconds,
    prism_seconds: prism_seconds
  }
end

printf("%-50s %14s %14s %14s\n", "Gemfile", "scanner total", "prism total", "ratio")
results.each do |row|
  printf("%-50s %12.2fms %12.2fms %12.2fx\n",
         row[:label],
         row[:scanner_seconds] * 1000,
         row[:prism_seconds] * 1000,
         row[:prism_seconds] / row[:scanner_seconds])
end

puts
puts "Per-rewrite cost (scanner / prism):"
results.each do |row|
  printf("  %-50s %8.3fms / %8.3fms\n",
         row[:label],
         (row[:scanner_seconds] / ITERATIONS) * 1000,
         (row[:prism_seconds] / ITERATIONS) * 1000)
end

# frozen_string_literal: true

# Spike test for issue #3313. Drives the Prism prototype through the behavior matrix
# enumerated in the issue and asserts the rewriter produces valid, expected output.
#
# This is intentionally a self-contained RSpec file outside of the main spec/ tree so
# the spike does not pollute the production test suite. Run with:
#   bundle exec rspec spike/3313_prism_gemfile_rewriter/prism_gemfile_rewriter_spec.rb

$LOAD_PATH.unshift(File.expand_path(__dir__))

require "prism_gemfile_rewriter"

RSpec.describe ReactOnRails::Spike::PrismGemfileRewriter do
  let(:default_pro_version) { "~> 16.7" }
  subject(:rewriter) { described_class.new(default_pro_version: default_pro_version) }

  def expect_parseable_ruby(content)
    parse_result = Prism.parse(content)
    error_messages = parse_result.errors.map(&:message).join(", ")
    expect(parse_result.failure?).to be(false),
                                     "expected parseable Ruby, got errors: #{error_messages}"
  end

  describe "#rewrite" do
    context "single-line declarations" do
      it "rewrites exact version pin" do
        src = <<~RUBY
          source "https://rubygems.org"
          gem "react_on_rails", "16.0.0"
        RUBY
        result = rewriter.rewrite(src)
        expect(result.content).to include('gem "react_on_rails_pro", "16.0.0"')
        expect(result.content).not_to match(/gem\s+["']react_on_rails["']/)
        expect_parseable_ruby(result.content)
      end

      it "rewrites pessimistic version pin" do
        src = <<~RUBY
          gem "react_on_rails", "~> 16.0"
        RUBY
        result = rewriter.rewrite(src)
        expect(result.content).to eq("gem \"react_on_rails_pro\", \"~> 16.0\"\n")
        expect_parseable_ruby(result.content)
      end

      it "preserves single-quote style" do
        src = "gem 'react_on_rails', '~> 16.0'\n"
        result = rewriter.rewrite(src)
        expect(result.content).to eq("gem 'react_on_rails_pro', '~> 16.0'\n")
      end

      it "rewrites percent string literals without emitting invalid Ruby" do
        src = "gem %q[react_on_rails], \"~> 16.0\"\n"
        result = rewriter.rewrite(src)
        expect(result.content).to eq("gem \"react_on_rails_pro\", \"~> 16.0\"\n")
        expect_parseable_ruby(result.content)
      end

      it "rewrites a bare gem declaration and inserts default version" do
        src = "gem \"react_on_rails\"\n"
        result = rewriter.rewrite(src)
        expect(result.content).to eq("gem \"react_on_rails_pro\", \"#{default_pro_version}\"\n")
      end

      it "rewrites declarations after UTF-8 content using byte offsets" do
        src = <<~RUBY
          # D\u00e9pendances
          gem "react_on_rails", "~> 16.0"
        RUBY
        result = rewriter.rewrite(src)
        expect(result.content).to eq(<<~RUBY)
          # D\u00e9pendances
          gem "react_on_rails_pro", "~> 16.0"
        RUBY
      end
    end

    context "kwargs and options" do
      it "preserves path: with version pin" do
        src = "gem \"react_on_rails\", \"~> 16.0\", path: \"../react_on_rails\"\n"
        result = rewriter.rewrite(src)
        expect(result.content).to include('gem "react_on_rails_pro", "~> 16.0", path: "../react_on_rails"')
      end

      it "preserves git: without inserting a default version when no user pin is present" do
        src = "gem \"react_on_rails\", git: \"https://example.invalid/repo.git\"\n"
        result = rewriter.rewrite(src)
        expect(result.content).to include(
          "gem \"react_on_rails_pro\", git: \"https://example.invalid/repo.git\""
        )
      end

      it "preserves github: without inserting a default version when no user pin is present" do
        src = "gem \"react_on_rails\", github: \"shakacode/react_on_rails\", branch: \"master\"\n"
        result = rewriter.rewrite(src)
        expect(result.content).to include(
          "gem \"react_on_rails_pro\", github: \"shakacode/react_on_rails\", branch: \"master\""
        )
      end

      it "preserves path: without inserting a default version when no user pin is present" do
        src = "gem \"react_on_rails\", path: \"../react_on_rails\"\n"
        result = rewriter.rewrite(src)
        expect(result.content).to include('gem "react_on_rails_pro", path: "../react_on_rails"')
      end

      it "inserts the default version before explicit hash options" do
        src = "gem \"react_on_rails\", { require: false }\n"
        result = rewriter.rewrite(src)
        expect(result.content).to eq("gem \"react_on_rails_pro\", \"#{default_pro_version}\", { require: false }\n")
      end

      it "preserves source explicit hash options without inserting a default version" do
        src = "gem \"react_on_rails\", { path: \"../react_on_rails\", require: false }\n"
        result = rewriter.rewrite(src)
        expect(result.content).to eq("gem \"react_on_rails_pro\", { path: \"../react_on_rails\", require: false }\n")
      end

      it "treats a non-string positional argument as a user version requirement" do
        src = "gem \"react_on_rails\", REACT_ON_RAILS_VERSION\n"
        result = rewriter.rewrite(src)
        expect(result.content).to eq("gem \"react_on_rails_pro\", REACT_ON_RAILS_VERSION\n")
      end

      it "preserves require: false and trailing guard" do
        src = "gem \"react_on_rails\", \"~> 16.0\", require: false, if: ENV[\"ENABLE_ROR\"]\n"
        result = rewriter.rewrite(src)
        expect(result.content).to include(
          'gem "react_on_rails_pro", "~> 16.0", require: false, if: ENV["ENABLE_ROR"]'
        )
      end

      it "preserves multi-constraint version pins" do
        src = "gem \"react_on_rails\", \">= 15.0\", \"< 16.0\", require: false\n"
        result = rewriter.rewrite(src)
        expect(result.content).to include('gem "react_on_rails_pro", ">= 15.0", "< 16.0", require: false')
      end

      it "preserves platforms: option" do
        src = "gem \"react_on_rails\", \"~> 16.0\", platforms: :jruby\n"
        result = rewriter.rewrite(src)
        expect(result.content).to include('gem "react_on_rails_pro", "~> 16.0", platforms: :jruby')
      end
    end

    context "multiline non-parenthesized declarations" do
      it "preserves source layout for non-parenthesized continuation across lines" do
        src = <<~RUBY
          gem "react_on_rails",
            "~> 16.0"
        RUBY
        result = rewriter.rewrite(src)
        expect(result.content).to eq(<<~RUBY)
          gem "react_on_rails_pro",
            "~> 16.0"
        RUBY
        expect_parseable_ruby(result.content)
      end

      it "preserves the inline-comment continuation" do
        src = <<~RUBY
          gem "react_on_rails", # pinned for compatibility
            "~> 16.0"
        RUBY
        result = rewriter.rewrite(src)
        expect(result.content).to include('gem "react_on_rails_pro", # pinned for compatibility')
        expect(result.content).to include('  "~> 16.0"')
        expect_parseable_ruby(result.content)
      end

      it "handles comment-only lines between continuation segments" do
        src = <<~RUBY
          gem "react_on_rails",
            # pinned for compatibility
            "~> 16.0"
          gem "rails"
        RUBY
        result = rewriter.rewrite(src)
        expect(result.content).to include('gem "react_on_rails_pro",')
        expect(result.content).to include('"~> 16.0"')
        expect(result.content).to include('gem "rails"')
        expect_parseable_ruby(result.content)
      end
    end

    context "parenthesized declarations" do
      it "preserves parens on a single-line declaration" do
        src = "gem(\"react_on_rails\", \"~> 16.0\")\n"
        result = rewriter.rewrite(src)
        expect(result.content).to eq("gem(\"react_on_rails_pro\", \"~> 16.0\")\n")
        expect_parseable_ruby(result.content)
      end

      it "preserves parens on a multiline declaration" do
        src = <<~RUBY
          gem(
            "react_on_rails",
            "~> 16.0"
          )
        RUBY
        result = rewriter.rewrite(src)
        expect(result.content).to eq(<<~RUBY)
          gem(
            "react_on_rails_pro",
            "~> 16.0"
          )
        RUBY
        expect_parseable_ruby(result.content)
      end

      it "handles parenthesized declarations with postfix guards" do
        src = "gem(\"react_on_rails\", \"~> 16.0\") if ENV[\"ENABLE_ROR\"]\n"
        result = rewriter.rewrite(src)
        expect(result.content).to eq("gem(\"react_on_rails_pro\", \"~> 16.0\") if ENV[\"ENABLE_ROR\"]\n")
        expect_parseable_ruby(result.content)
      end

      it "handles a trailing comment after the closing paren" do
        src = <<~RUBY
          gem(
            "react_on_rails",
            "~> 16.0"
          ) # pin
        RUBY
        result = rewriter.rewrite(src)
        expect(result.content).to include('"react_on_rails_pro"')
        expect(result.content).to include("# pin")
        expect_parseable_ruby(result.content)
      end

      it "handles inline Ruby comments containing parens" do
        src = <<~RUBY
          gem(
            "react_on_rails",
            "~> 16.0", # pinned :)
            require: false
          )
        RUBY
        result = rewriter.rewrite(src)
        expect(result.content).to include('"react_on_rails_pro"')
        expect(result.content).to include('"~> 16.0"')
        expect(result.content).to include("require: false")
        expect_parseable_ruby(result.content)
      end

      it "handles nested parens in option values" do
        src = <<~RUBY
          gem(
            "react_on_rails",
            "~> 16.0",
            if: ENV.fetch("ENABLE_ROR") { true }
          )
        RUBY
        result = rewriter.rewrite(src)
        expect(result.content).to include('"react_on_rails_pro"')
        expect(result.content).to include('if: ENV.fetch("ENABLE_ROR") { true }')
        expect_parseable_ruby(result.content)
      end
    end

    context "edge-case Gemfile shapes" do
      it "leaves valid output when there is no final newline" do
        src = "gem \"react_on_rails\", \"~> 16.0\""
        result = rewriter.rewrite(src)
        expect(result.content).to include('gem "react_on_rails_pro", "~> 16.0"')
        expect_parseable_ruby(result.content)
      end

      it "rewrites duplicate base declarations across groups" do
        src = <<~RUBY
          gem "react_on_rails", "~> 16.0"
          group :test do
            gem "react_on_rails", "~> 16.0", require: false
          end
        RUBY
        result = rewriter.rewrite(src)
        expect(result.content).to eq(<<~RUBY)
          gem "react_on_rails_pro", "~> 16.0"
          group :test do
            gem "react_on_rails_pro", "~> 16.0", require: false
          end
        RUBY
        expect_parseable_ruby(result.content)
      end

      it "rewrites duplicate base declarations on the same level (platform-specific)" do
        src = <<~RUBY
          gem "react_on_rails", "~> 16.0"
          gem "react_on_rails", "~> 16.0", platforms: :jruby
        RUBY
        result = rewriter.rewrite(src)
        expect(result.content).to include('gem "react_on_rails_pro", "~> 16.0"')
        expect(result.content).to include('gem "react_on_rails_pro", "~> 16.0", platforms: :jruby')
        expect(result.content).not_to match(/gem\s+["']react_on_rails["']/)
        expect_parseable_ruby(result.content)
      end

      it "removes stale base when active Pro is present (single-line Pro)" do
        src = <<~RUBY
          gem "react_on_rails", "~> 16.0"
          gem "react_on_rails_pro", "~> 16.0"
        RUBY
        result = rewriter.rewrite(src)
        expect(result.content).to eq("gem \"react_on_rails_pro\", \"~> 16.0\"\n")
        expect(result.base_entries_removed).to be(true)
        expect_parseable_ruby(result.content)
      end

      it "removes a stale base declaration after an active Pro declaration on the same line" do
        src = "gem \"react_on_rails_pro\", \"~> 16.0\"; gem \"react_on_rails\", \"~> 16.0\"\n"
        result = rewriter.rewrite(src)
        expect(result.content).to eq("gem \"react_on_rails_pro\", \"~> 16.0\"\n")
        expect_parseable_ruby(result.content)
      end

      it "removes a stale base declaration before an active Pro declaration on the same line" do
        src = "gem \"react_on_rails\", \"~> 16.0\"; gem \"react_on_rails_pro\", \"~> 16.0\"\n"
        result = rewriter.rewrite(src)
        expect(result.content).to eq("gem \"react_on_rails_pro\", \"~> 16.0\"\n")
        expect_parseable_ruby(result.content)
      end

      it "removes a stale base declaration in the middle of a shared line" do
        src = "gem \"rails\"; gem \"react_on_rails\", \"~> 16.0\"; gem \"react_on_rails_pro\", \"~> 16.0\"\n"
        result = rewriter.rewrite(src)
        expect(result.content).to eq("gem \"rails\"; gem \"react_on_rails_pro\", \"~> 16.0\"\n")
        expect_parseable_ruby(result.content)
      end

      it "ignores semicolons in trailing comments when removing a stale base declaration" do
        src = <<~RUBY
          gem "react_on_rails", "~> 16.0" # old; remove
          gem "react_on_rails_pro", "~> 16.0"
        RUBY
        result = rewriter.rewrite(src)
        expect(result.content).to eq("gem \"react_on_rails_pro\", \"~> 16.0\"\n")
        expect_parseable_ruby(result.content)
      end

      it "ignores semicolons in quoted postfix guards when removing a stale base declaration" do
        src = 'gem "react_on_rails" if ENV["ROR;ENABLED"]; gem "react_on_rails_pro", "~> 16.0"' \
              "\n"
        result = rewriter.rewrite(src)
        expect(result.content).to eq("gem \"react_on_rails_pro\", \"~> 16.0\"\n")
        expect_parseable_ruby(result.content)
      end

      it "ignores semicolons in percent-string postfix guards when removing a stale base declaration" do
        src = 'gem "react_on_rails" if ENV[%q[ROR;ENABLED]]; gem "react_on_rails_pro", "~> 16.0"' \
              "\n"
        result = rewriter.rewrite(src)
        expect(result.content).to eq("gem \"react_on_rails_pro\", \"~> 16.0\"\n")
        expect_parseable_ruby(result.content)
      end

      it "ignores semicolons in regex postfix guards when removing a stale base declaration" do
        src = 'gem "react_on_rails" if /ROR;ENABLED/.match?(ENV["FLAGS"]); ' \
              'gem "react_on_rails_pro", "~> 16.0"' \
              "\n"
        result = rewriter.rewrite(src)
        expect(result.content).to eq("gem \"react_on_rails_pro\", \"~> 16.0\"\n")
        expect_parseable_ruby(result.content)
      end

      it "preserves a preceding sibling statement when a regex-guarded stale base follows it" do
        # When an active Pro gem is present, the rewriter calls `removal_edit`, which
        # uses `previous_semicolon_offset` to find the statement boundary. The scanner
        # skips `%r[...]` percent-literals but not bare `/regex/` literals, so a `;`
        # inside `/should;load/` could be miscounted as a separator. In practice this
        # input rewrites cleanly because `removable_statement_node` returns the full
        # IfNode (covering the regex), so the regex's `;` falls inside the node's
        # byte range and below the `statement_end` threshold. Lock that behavior.
        src = "gem \"react_on_rails_pro\", \"~> 16.0\"; " \
              "gem \"react_on_rails\" if /should;load/.match?(ENV[\"X\"])\n"
        result = rewriter.rewrite(src)
        expect(result.content).to eq("gem \"react_on_rails_pro\", \"~> 16.0\"\n")
        expect_parseable_ruby(result.content)
      end

      it "removes stale base when Pro is parenthesized with comments" do
        src = <<~RUBY
          source "https://rubygems.org"
          gem "react_on_rails", "~> 16.0"
          gem(
            # pinned for compatibility
            "react_on_rails_pro",
            "~> 16.0"
          )
        RUBY
        result = rewriter.rewrite(src)
        expect(result.content).to eq(<<~RUBY)
          source "https://rubygems.org"
          gem(
            # pinned for compatibility
            "react_on_rails_pro",
            "~> 16.0"
          )
        RUBY
        expect(result.base_entries_removed).to be(true)
        expect_parseable_ruby(result.content)
      end

      it "rewrites base declarations in both conditional branches" do
        src = <<~RUBY
          if ENV["ROR_EDGE"]
            gem "react_on_rails", github: "shakacode/react_on_rails", branch: "master"
          else
            gem "react_on_rails", "~> 16.0"
          end
        RUBY
        result = rewriter.rewrite(src)
        expected_github_line = '  gem "react_on_rails_pro", github: "shakacode/react_on_rails", ' \
                               'branch: "master"'
        expect(result.content.lines).to eq([
          "if ENV[\"ROR_EDGE\"]\n",
          "#{expected_github_line}\n",
          "else\n",
          "  gem \"react_on_rails_pro\", \"~> 16.0\"\n",
          "end\n"
        ])
        expect_parseable_ruby(result.content)
      end

      it "collapses the empty-else case (the documented #3232 ugliness)" do
        src = <<~RUBY
          if ENV["PRO"]
            gem "react_on_rails_pro", "16.0.0"
          else
            gem "react_on_rails", "16.0.0"
          end
        RUBY
        result = rewriter.rewrite(src)
        expect(result.content).to eq("gem \"react_on_rails_pro\", \"16.0.0\"\n")
        expect_parseable_ruby(result.content)
      end

      it "preserves same-line sibling statements when collapsing a conditional" do
        src = <<~RUBY
          if ENV["PRO"]
            gem "react_on_rails_pro", "16.0.0"
          else
            gem "react_on_rails", "16.0.0"
          end; gem "rails"
        RUBY
        result = rewriter.rewrite(src)
        expect(result.content).to eq("gem \"react_on_rails_pro\", \"16.0.0\"; gem \"rails\"\n")
        expect_parseable_ruby(result.content)
      end

      it "collapses an inline single-line if/then/else without dropping the active Pro gem" do
        # Regression for the line-fallback in `statement_byte_range`. Inline single-line
        # block conditionals have no statement separators on the line, so the previous
        # fallback `[line_start, line_end]` deleted the whole conditional — taking the
        # active Pro gem with it. Now the call's own byte range is used, and the
        # collapse pass folds the resulting empty-else conditional to the single Pro
        # gem declaration.
        src = "if ENV['PRO'] then gem 'react_on_rails_pro' else gem 'react_on_rails' end\n"
        result = rewriter.rewrite(src)
        expect(result.content).to eq("gem 'react_on_rails_pro'\n")
        expect_parseable_ruby(result.content)
      end

      it "terminates when an inline conditional's else branch becomes empty post-removal" do
        # Regression for the infinite-loop in `collapse_dead_conditionals` when
        # `remove_empty_else_branch` produced a zero-length splice for inline
        # conditionals (else and end on the same line). The collapse loop now
        # bails on no-op edits, so a conditional whose then-branch contains more
        # than one statement is left intact: still parseable Ruby, uglier than
        # ideal but no data loss and no hang.
        src = "if ENV['PRO']; gem 'react_on_rails_pro'; gem 'rails'; " \
              "else; gem 'react_on_rails', '16.0.0'; end\n"
        # Use Timeout to fail loudly if the loop ever regresses to hanging.
        require "timeout"
        result = Timeout.timeout(5) { rewriter.rewrite(src) }
        # The call's own byte range is removed; the surrounding `;` separators
        # survive (`else; ; end`). Still valid Ruby, and crucially the Pro gem
        # and the unrelated `rails` statement both remain.
        expect(result.content).to include("gem 'react_on_rails_pro'")
        expect(result.content).to include("gem 'rails'")
        expect(result.content).not_to include("react_on_rails'")
        expect_parseable_ruby(result.content)
      end

      it "collapses an unless/else conditional whose else branch held the stale base" do
        # `conditional_else_node` routes UnlessNode to `node.else_clause` (a different
        # accessor than IfNode's `node.subsequent`). Exercise that branch directly.
        src = <<~RUBY
          unless ENV["PRO"]
            gem "react_on_rails", "16.0.0"
          else
            gem "react_on_rails_pro", "16.0.0"
          end
        RUBY
        result = rewriter.rewrite(src)
        expect(result.content).to eq("gem \"react_on_rails_pro\", \"16.0.0\"\n")
        expect_parseable_ruby(result.content)
      end

      it "does not collapse pre-existing empty branches when removing stale base elsewhere" do
        src = <<~RUBY
          if ENV["ENABLE_ROR"]
            gem "react_on_rails_pro", "~> 16.0"
          else
          end
          gem "react_on_rails", "~> 16.0"
        RUBY
        result = rewriter.rewrite(src)
        expect(result.content).to eq(<<~RUBY)
          if ENV["ENABLE_ROR"]
            gem "react_on_rails_pro", "~> 16.0"
          else
          end
        RUBY
        expect_parseable_ruby(result.content)
      end

      it "only skips as many duplicate empty conditionals as were already empty" do
        src = <<~RUBY
          if ENV["ENABLE_ROR"]
            gem "react_on_rails_pro", "~> 16.0"
          else
          end
          if ENV["ENABLE_ROR"]
            gem "react_on_rails_pro", "~> 16.0"
          else
            gem "react_on_rails", "~> 16.0"
          end
        RUBY
        result = rewriter.rewrite(src)
        expect(result.content).to eq(<<~RUBY)
          if ENV["ENABLE_ROR"]
            gem "react_on_rails_pro", "~> 16.0"
          else
          end
          gem "react_on_rails_pro", "~> 16.0"
        RUBY
        expect_parseable_ruby(result.content)
      end

      it "matches pre-existing empty branches by conditional identity" do
        src = <<~RUBY
          if ENV["ENABLE_ROR"]
            gem "react_on_rails_pro", "~> 16.0"
          else
            gem "react_on_rails", "~> 16.0"
          end
          if ENV["ENABLE_ROR"]
            gem "react_on_rails_pro", "~> 16.0"
          else
          end
        RUBY
        result = rewriter.rewrite(src)
        expect(result.content).to eq(<<~RUBY)
          gem "react_on_rails_pro", "~> 16.0"
          if ENV["ENABLE_ROR"]
            gem "react_on_rails_pro", "~> 16.0"
          else
          end
        RUBY
        expect_parseable_ruby(result.content)
      end

      it "does not crash on unrelated unless blocks when removing stale base" do
        src = <<~RUBY
          unless ENV["CI"]
            gem "pry"
          end
          gem "react_on_rails", "~> 16.0"
          gem "react_on_rails_pro", "~> 16.0"
        RUBY
        result = rewriter.rewrite(src)
        expect(result.content).to eq(<<~RUBY)
          unless ENV["CI"]
            gem "pry"
          end
          gem "react_on_rails_pro", "~> 16.0"
        RUBY
        expect_parseable_ruby(result.content)
      end

      it "collapses stale base conditionals after UTF-8 content using byte offsets" do
        src = <<~RUBY
          # D\u00e9pendances
          if ENV["PRO"]
            gem "react_on_rails_pro", "16.0.0"
          else
            gem "react_on_rails", "16.0.0"
          end
        RUBY
        result = rewriter.rewrite(src)
        expect(result.content).to eq(<<~RUBY)
          # D\u00e9pendances
          gem "react_on_rails_pro", "16.0.0"
        RUBY
        expect_parseable_ruby(result.content)
      end

      it "preserves indentation when collapsing an indented conditional" do
        src = <<~RUBY
          group :development do
            if ENV["PRO"]
              gem "react_on_rails_pro", "16.0.0"
            else
              gem "react_on_rails", "16.0.0"
            end
          end
        RUBY
        result = rewriter.rewrite(src)
        expect(result.content).to eq(<<~RUBY)
          group :development do
            gem "react_on_rails_pro", "16.0.0"
          end
        RUBY
        expect_parseable_ruby(result.content)
      end

      it "preserves inline comments after the gem name" do
        src = "gem \"react_on_rails\" # pinned for compatibility\n"
        result = rewriter.rewrite(src)
        expect(result.content).to include("gem \"react_on_rails_pro\", \"#{default_pro_version}\"")
        expect(result.content).to include("# pinned for compatibility")
      end

      it "does not modify a Gemfile with no react_on_rails entry" do
        src = "source \"https://rubygems.org\"\ngem \"rails\"\n"
        result = rewriter.rewrite(src)
        expect(result.content).to eq(src)
        expect(result.base_entries_removed).to be(false)
      end

      it "does not rewrite gem calls that mention react_on_rails only in kwargs" do
        src = "gem(\"other_gem\", require: \"react_on_rails\")\n"
        result = rewriter.rewrite(src)
        expect(result.content).to eq(src)
      end
    end

    context "trailing comma suffix (gem(\"react_on_rails\",))" do
      # Ruby 3.3+ accepts trailing commas in parenthesized calls; earlier Rubies treat
      # it as a syntax error and Prism reports a parse failure. Split into two gated
      # tests so each Ruby tightens to a single expected outcome instead of a
      # "does-not-crash" passthrough that hides a real regression.
      if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.3.0")
        it "rewrites cleanly on Ruby 3.3+" do
          src = "gem(\"react_on_rails\",)\n"
          result = rewriter.rewrite(src)
          expect(result.parse_failed).to be(false)
          expect(result.content).to include('"react_on_rails_pro"')
          expect_parseable_ruby(result.content)
        end
      else
        it "reports a parse failure on Ruby < 3.3" do
          src = "gem(\"react_on_rails\",)\n"
          result = rewriter.rewrite(src)
          expect(result.parse_failed).to be(true)
          expect(result.content).to eq(src)
        end
      end
    end

    context "parse-failure policy" do
      it "returns the original content untouched when Gemfile cannot be parsed" do
        src = "gem \"react_on_rails\" if ENV[\"X\"\n" # missing closing bracket
        result = rewriter.rewrite(src)
        expect(result.parse_failed).to be(true)
        expect(result.content).to eq(src)
        expect(result.errors).not_to be_empty
      end
    end
  end
end

# frozen_string_literal: true

module ReactOnRails
  # Shared Pro migration facts and Gemfile parsing used by the generator and doctor.
  module ProMigration
    JS_SOURCE_ROOTS = %w[app/javascript app/frontend frontend javascript client].freeze
    JS_SOURCE_EXTENSIONS = %w[js jsx ts tsx mjs cjs vue svelte].freeze

    JEST_MODULE_SPECIFIER_METHOD_NAMES = %w[
      createMockFromModule
      mock unmock deepUnmock doMock dontMock setMock
      requireActual requireMock unstable_mockModule unstable_unmockModule
    ].freeze
    VITEST_MODULE_SPECIFIER_METHOD_NAMES = %w[
      mock unmock doMock doUnmock
      importActual importMock
    ].freeze
    JEST_MODULE_SPECIFIER_METHOD_PATTERN = Regexp.union(JEST_MODULE_SPECIFIER_METHOD_NAMES)
    VITEST_MODULE_SPECIFIER_METHOD_PATTERN = Regexp.union(VITEST_MODULE_SPECIFIER_METHOD_NAMES)

    PRO_GEM_PATTERN = /^\s*gem(?:\s+|\(\s*(?:#.*\n\s*)*)["']react_on_rails_pro["']/
    BASE_GEM_PATTERN = /^(\s*)gem(?:\s+|\(\s*)(["'])react_on_rails\2(?=\s*(?:,|\)|#|$))/
    RUBY_INLINE_COMMENT_PATTERN = /(?<!\s)\s*#.*$/
    STRING_LITERAL_PATTERN = /"(?:\\.|[^"\\])*+"|'(?:\\.|[^'\\])*+'|`(?:\\.|[^`\\])*+`/

    module_function

    def pro_gem_entry?(gemfile_content)
      gemfile_content.match?(PRO_GEM_PATTERN)
    end

    def base_gem_entry?(gemfile_content)
      gemfile_lines = gemfile_content.lines
      line_index = 0

      while line_index < gemfile_lines.length
        return true if base_gem_declaration_at(gemfile_lines, line_index)

        line_index += 1
      end

      false
    end

    def base_gem_declaration_at(lines, start_index)
      match_multiline_parenthesized_base_gem(lines, start_index) ||
        match_non_parenthesized_base_gem(lines, start_index)
    end

    def match_multiline_parenthesized_base_gem(lines, start_index)
      start_line = lines[start_index]
      start_match = start_line.match(/^(\s*)gem\s*\(/)
      return nil unless start_match

      line_index = start_index
      gem_name = nil
      paren_depth = 0

      while line_index < lines.length
        line = lines[line_index]
        gem_name_fragment_offset = line_index == start_index ? start_match.end(0) : 0
        gem_name ||= parenthesized_base_gem_name(line, gem_name_fragment_offset, line_index)
        return nil if gem_name == false

        line_without_literals = line_without_string_literals_and_inline_comments(line, strip_ruby_comments: true)
        paren_depth += parenthesis_delta(line_without_literals)

        return parenthesized_base_gem_declaration(lines, start_match, gem_name, line_index) if paren_depth <= 0

        line_index += 1
      end

      nil
    end

    def parenthesized_base_gem_name(line, fragment_offset, line_index)
      gem_name_fragment = line[fragment_offset..].to_s
      return nil if gem_name_fragment.sub(RUBY_INLINE_COMMENT_PATTERN, "").strip.empty?

      gem_name_match = gem_name_fragment.match(/\A\s*(["'])react_on_rails\1(?=\s*(?:,|\)|#|$))/)
      return false unless gem_name_match

      {
        quote: gem_name_match[1],
        line_index: line_index,
        match_end: fragment_offset + gem_name_match.end(0)
      }
    end

    def parenthesized_base_gem_declaration(lines, start_match, gem_name, end_line_index)
      return nil unless gem_name

      declaration_fragment = lines[gem_name[:line_index]..end_line_index].join
      suffix = declaration_fragment[gem_name[:match_end]..]
      suffix = "\n" if suffix.nil? || suffix.empty?
      {
        indentation: start_match[1],
        quote: gem_name[:quote],
        next_index: end_line_index + 1,
        trailing_suffix: suffix,
        parenthesized_gem_call: true
      }
    end

    def parenthesis_delta(line)
      line.count("(") - line.count(")")
    end

    def match_non_parenthesized_base_gem(lines, start_index)
      line = lines[start_index]
      match = line.match(BASE_GEM_PATTERN)
      return nil unless match

      declaration = consume_non_parenthesized_base_gem_declaration(lines, start_index, match.end(0))
      {
        indentation: match[1],
        quote: match[2],
        next_index: declaration[:next_index],
        trailing_suffix: declaration[:trailing_suffix],
        parenthesized_gem_call: match[0].include?("(")
      }
    end

    def consume_non_parenthesized_base_gem_declaration(lines, start_index, match_end)
      line_index = start_index
      current_line = lines[line_index]
      declaration_lines = [current_line]
      line_index += 1

      while line_index < lines.length &&
            line_continues_with_comma?(current_line) &&
            gem_declaration_continues_on_next_line?(lines[line_index])
        next_line = lines[line_index]
        declaration_lines << next_line
        current_line = next_line unless comment_or_blank_line?(next_line)
        line_index += 1
      end

      trailing_suffix = lines[start_index][match_end..].to_s + declaration_lines.drop(1).join
      { trailing_suffix: trailing_suffix, next_index: line_index }
    end

    def line_continues_with_comma?(line)
      line_without_comment = line.sub(RUBY_INLINE_COMMENT_PATTERN, "").rstrip
      line_without_comment.end_with?(",")
    end

    def gem_declaration_continues_on_next_line?(line)
      stripped = line.lstrip
      return true if stripped.empty?

      !stripped.match?(/\Agem(?:\s|\()/)
    end

    def comment_or_blank_line?(line)
      stripped = line.lstrip
      stripped.empty? || stripped.start_with?("#")
    end

    def line_without_string_literals_and_inline_comments(line, strip_ruby_comments: false)
      line_without_strings = line.gsub(STRING_LITERAL_PATTERN, "")
      return line_without_strings unless strip_ruby_comments

      line_without_strings.sub(RUBY_INLINE_COMMENT_PATTERN, "")
    end
  end
end

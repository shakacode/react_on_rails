#!/usr/bin/env ruby
# frozen_string_literal: true

# Claude Code PostToolUse hook — installed by `rake react_on_rails:install_rsc_agent_guardrails`.
# NON-BLOCKING advisory (always exits 0). Warns when React on Rails Pro RSC endpoints are wired
# without visible authentication. The RSC payload route renders any registered server component
# with caller-supplied props and has NO built-in auth — see the `rsc-app-safety` skill.
# Callback detection is a conservative name/scope heuristic; silence does not prove authorization.

require "json"
require "ripper"

# Recognizing a callback as authentication only silences the advisory, so this stays deliberately
# conservative: an over-broad match turns a false positive into a false negative, which is the more
# dangerous direction for a security guardrail.
#
# A trailing `!`/`?` is the discriminating signal for the open-ended forms. Devise and friends
# generate bang callbacks per scope (`authenticate_admin_user!`, `authenticate_api_user!`,
# `authenticate_customer!`), and app-defined auth callbacks follow the same convention, so any
# `authenticate*`/`authorize*` name that ends in a bang counts. Without a bang the name must come
# from the narrow allowlist, which keeps unrelated callbacks such as `authenticate_analytics_session`
# and `authorize_for_metrics` from reading as authentication.
AUTH_NAME = /
  (?:
    authenticate(?:_\w+)?[!?] |
    authorize(?:_\w+)?[!?] |
    authenticate(?:_(?:user|account|admin|member|session))? |
    authorize(?:_(?:request|access|user))? |
    require_(?:login|user|authentication|authorization) |
    verify_authenticat(?:ed|ion)
  )[!?]?
/x
AUTH_CALLBACK_NAME = "(?:prepend_|append_)?before_action"
COMMENT_EVENTS = %i[on_comment on_embdoc_beg on_embdoc on_embdoc_end].freeze
# String, heredoc, and regexp bodies are data, not executable code. Ripper reports all of them as
# :on_tstring_content, so they must be neutralized alongside comments — otherwise a
# `skip_before_action` written inside a heredoc reads as a real callback and produces a false warning.
STRING_BODY_EVENTS = %i[on_tstring_content].freeze
SCOPE_SYNTAX = /(?:%[iw](?:\[[^\]]*\]|\([^)]*\)|\{[^}]*\})|\[[^\]]*\]|:[A-Za-z_]\w*[!?]?|["'][^"']+["'])/
ONLY_SCOPE = /\A,\s*only:\s*(#{SCOPE_SYNTAX})\z/o
EXCEPT_SCOPE = /\A,\s*except:\s*(#{SCOPE_SYNTAX})\z/o

def logical_statements(lines, callback_name)
  lines.each_with_index.filter_map do |line, index|
    next unless line.match?(/^\s*#{callback_name}\b/)

    statement = line.dup
    while index + 1 < lines.length &&
          (statement.rstrip.end_with?(",", "\\") ||
           statement.count("(") > statement.count(")") ||
           statement.count("[") > statement.count("]"))
      index += 1
      statement << lines[index]
    end
    statement.gsub(/\s+/, " ").strip
  end
end

def parse_callback(statement, callback_name)
  callback = statement.match(
    /\A#{callback_name}\s*(?<parenthesized>\()?\s*:?(?<auth>#{AUTH_NAME})(?=\s*(?:,|\)|\z))(?<rest>.*)\z/
  )
  return unless callback

  rest = callback[:rest].strip
  rest = rest.delete_suffix(")").strip if callback[:parenthesized]
  [callback[:auth], rest]
end

def applies_to_payload?(rest, unknown:)
  return true if rest.empty?

  if (scope = rest.match(ONLY_SCOPE))
    scope[1].match?(/\brsc_payload\b/)
  elsif (scope = rest.match(EXCEPT_SCOPE))
    !scope[1].match?(/\brsc_payload\b/)
  else
    unknown
  end
end

def authenticated_callback_names(lines)
  logical_statements(lines, AUTH_CALLBACK_NAME).filter_map do |statement|
    parsed = parse_callback(statement, AUTH_CALLBACK_NAME)
    parsed&.first if parsed && applies_to_payload?(parsed.last, unknown: false)
  end
end

def remove_skipped_callbacks(lines, authenticated_callbacks)
  logical_statements(lines, "skip_before_action").each do |statement|
    parsed = parse_callback(statement, "skip_before_action")
    next unless parsed && authenticated_callbacks.include?(parsed.first)

    authenticated_callbacks.delete(parsed.first) if applies_to_payload?(parsed.last, unknown: true)
  end
end

def ruby_tokens(content)
  return [] unless content.valid_encoding?

  Ripper.lex(content)
rescue ArgumentError
  []
end

def blank_text(text)
  text.gsub(/[^\n]/, " ")
end

# Blanks only the parts of a string body that begin a source line, because those are the parts that
# can masquerade as a statement to the line-oriented callback scanner. Content that starts mid-line
# (`only: "rsc_payload"`) is preserved so callback scope parsing keeps working.
def blank_line_starting_text(text, column)
  text.split("\n", -1).each_with_index.map do |part, index|
    index.zero? && column.positive? ? part : blank_text(part)
  end.join("\n")
end

def scannable_ruby_lines(tokens)
  heredoc_depth = 0
  tokens.each_with_object(+"") do |(position, event, token, _state), scannable|
    heredoc_depth += 1 if event == :on_heredoc_beg
    heredoc_depth -= 1 if event == :on_heredoc_end
    scannable << if COMMENT_EVENTS.include?(event)
                   blank_text(token)
                 elsif STRING_BODY_EVENTS.include?(event)
                   # Every line of a heredoc body begins a source line; Ripper reports its indentation
                   # as a separate token, so the body's column is not a reliable signal there.
                   heredoc_depth.positive? ? blank_text(token) : blank_line_starting_text(token, position[1])
                 else
                   token
                 end
  end.lines
end

# Executable lines only. Falls back to a crude comment strip when the file does not lex (so an
# unparseable routes file still gets its advisory rather than silently passing).
def code_lines(content)
  tokens = ruby_tokens(content)
  return scannable_ruby_lines(tokens) if tokens.any?

  content.lines.map { |line| line.sub(/#.*/, "") }
end

def renderer_evidence?(tokens)
  tokens.any? do |_position, event, token, _state|
    (event == :on_const && token == "RSCPayloadRenderer") || (event == :on_ident && token == "rsc_payload")
  end
end

def authentication_evidence?(lines)
  authenticated_callbacks = authenticated_callback_names(lines)
  remove_skipped_callbacks(lines, authenticated_callbacks)
  authenticated_callbacks.any?
end

def input_file
  input = $stdin.tty? ? "" : $stdin.read
  parsed_input = JSON.parse(input)
  parsed_path = parsed_input.is_a?(Hash) ? parsed_input.dig("tool_input", "file_path").to_s : ""
  parsed_path.empty? ? ARGV.first.to_s : parsed_path
rescue JSON::ParserError
  ARGV.first.to_s
end

def warning_context(relative_path, detail)
  [
    "⚠️  rsc-app-safety: #{relative_path}",
    detail,
    "The React on Rails Pro RSC payload route renders any registered server component with",
    "caller-supplied props and has NO built-in authentication. Confirm this endpoint is behind your",
    "app's auth via ReactOnRailsPro.configure { |config| config.rsc_payload_authorizer = ... } or",
    "an authenticated, app-owned controller's before_action, and",
    "that server components derive identity from the session, not props. Read the rsc-app-safety",
    "skill before shipping."
  ].join("\n")
end

def read_file(path)
  File.read(path)
rescue SystemCallError
  nil
end

file = input_file.tr("\\", "/")
exit 0 if file.empty? || !File.file?(file)

root = ENV.fetch("CLAUDE_PROJECT_DIR", Dir.pwd).tr("\\", "/").delete_suffix("/")
relative_path = file.delete_prefix("#{root}/")
detail = case file
         when %r{\A(?:.*/)?config/routes(?:/[^/]+)?\.rb\z}
           content = read_file(file)
           if content && code_lines(content).any? { |line| line.include?("rsc_payload_route") }
             "This routes file mounts rsc_payload_route (a public RSC endpoint)."
           end
         when %r{\A(?:.*/)?app/controllers/.+\.rb\z}
           content = read_file(file)
           tokens = ruby_tokens(content) if content
           lines = scannable_ruby_lines(tokens) if tokens&.any?
           if lines && renderer_evidence?(tokens) && !authentication_evidence?(lines)
             "This controller wires an RSC payload renderer, but the edited file shows no " \
               "before_action/authentication locally. Inherited callbacks are not inspected."
           end
         end

if detail
  puts JSON.generate(
    "hookSpecificOutput" => {
      "hookEventName" => "PostToolUse",
      "additionalContext" => warning_context(relative_path, detail)
    }
  )
end

exit 0

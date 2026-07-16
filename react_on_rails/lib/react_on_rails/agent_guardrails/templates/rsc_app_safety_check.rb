#!/usr/bin/env ruby
# frozen_string_literal: true

# Claude Code PostToolUse hook — installed by `rake react_on_rails:install_rsc_agent_guardrails`.
# NON-BLOCKING advisory (always exits 0). Warns when React on Rails Pro RSC endpoints are wired
# without visible authentication. The RSC payload route renders any registered server component
# with caller-supplied props and has NO built-in auth — see the `rsc-app-safety` skill.

require "json"
require "ripper"

AUTH_NAME = /(?:authenticate\w*[!?]?|authorize\w*[!?]?|require_(?:login|user)\w*[!?]?)/
AUTH_CALLBACK_NAME = "(?:prepend_|append_)?before_action"
COMMENT_EVENTS = %i[on_comment on_embdoc_beg on_embdoc on_embdoc_end].freeze
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
    /\A#{callback_name}\s*(?<parenthesized>\()?\s*:?(?<auth>#{AUTH_NAME})(?<rest>.*)\z/
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

def uncommented_ruby_lines(tokens)
  tokens.each_with_object(+"") do |(_position, event, token, _state), uncommented|
    uncommented << (COMMENT_EVENTS.include?(event) ? token.gsub(/[^\n]/, " ") : token)
  end.lines
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
           if content&.lines&.any? { |line| line.sub(/#.*/, "").include?("rsc_payload_route") }
             "This routes file mounts rsc_payload_route (a public RSC endpoint)."
           end
         when %r{\A(?:.*/)?app/controllers/.+\.rb\z}
           content = read_file(file)
           tokens = ruby_tokens(content) if content
           lines = uncommented_ruby_lines(tokens) if tokens&.any?
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

#!/usr/bin/env ruby
# frozen_string_literal: true

# Claude Code PostToolUse hook — installed by `rake react_on_rails:install_rsc_agent_guardrails`.
# NON-BLOCKING advisory (always exits 0). Warns when React on Rails Pro RSC endpoints are wired
# without visible authentication. The RSC payload route renders any registered server component
# with caller-supplied props and has NO built-in auth — see the `rsc-app-safety` skill.

require "json"

AUTH_NAME = /(?:authenticate\w*[!?]?|authorize\w*[!?]?|require_(?:login|user)\w*[!?]?)/
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
  logical_statements(lines, "before_action").filter_map do |statement|
    parsed = parse_callback(statement, "before_action")
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

def authentication_evidence?(content)
  lines = content.lines.map { |line| line.sub(/#.*/, "") }
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
    "app's auth via config.rsc_payload_authorizer or an app-owned controller's before_action, and",
    "that server components derive identity from the session, not props. Read the rsc-app-safety",
    "skill before shipping."
  ].join("\n")
end

file = input_file.tr("\\", "/")
exit 0 if file.empty? || !File.file?(file)

root = ENV.fetch("CLAUDE_PROJECT_DIR", Dir.pwd).tr("\\", "/").delete_suffix("/")
relative_path = file.delete_prefix("#{root}/")
content = File.read(file)
detail = case file
         when %r{\A(?:.*/)?config/routes(?:/[^/]+)?\.rb\z}
           if content.lines.any? { |line| line.sub(/#.*/, "").include?("rsc_payload_route") }
             "This routes file mounts rsc_payload_route (a public RSC endpoint)."
           end
         when %r{\A(?:.*/)?app/controllers/.+\.rb\z}
           if content.match?(/RSCPayloadRenderer|rsc_payload/) && !authentication_evidence?(content)
             "This controller wires an RSC payload renderer but shows no before_action/authentication."
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

#!/usr/bin/env ruby
# frozen_string_literal: true

GOAL_PROMPT_CHAR_LIMIT = 4_000
TEXT_FENCE = "```text\n"

def abort_with_failure(message)
  abort "FAIL: #{message}"
end

def extract_goal_prompt_template(skill_text)
  heading_index = skill_text.index("## Goal Prompt for pr-batch")
  abort_with_failure("missing Goal Prompt for pr-batch section") unless heading_index

  fence_start = skill_text.index(TEXT_FENCE, heading_index)
  abort_with_failure("missing text fence in Goal Prompt section") unless fence_start

  fence_body_start = fence_start + TEXT_FENCE.length
  # The goal prompt template must not contain nested bare fence lines.
  closing_fence = skill_text.match(/^```\s*$/, fence_body_start)
  abort_with_failure("missing closing fence in Goal Prompt section") unless closing_fence

  skill_text[fence_body_start...closing_fence.begin(0)]
end

def with_items(prompt_template, items)
  updated_prompt = prompt_template.sub(/Items:\n.*?\n\nExecution rules:/m) do
    "Items:\n#{items}\n\nExecution rules:"
  end
  if updated_prompt == prompt_template
    abort_with_failure("goal prompt template must contain Items and Execution rules sections")
  end

  updated_prompt
end

skill_path = File.expand_path("../SKILL.md", __dir__)
abort_with_failure("SKILL.md not found at #{skill_path}") unless File.exist?(skill_path)

skill_text = File.read(skill_path, encoding: "UTF-8")
prompt_template = extract_goal_prompt_template(skill_text)

required_skill_rule_phrases = [
  "Goal prompt character count:",
  "If the measured prompt is 4000 characters or more",
  "output only the first ready goal",
  "bulky detail stays in the Batch Plan",
  "Keep bulky evidence",
  "outside the prompt"
]

required_prompt_phrases = [
  "merge if confident",
  "document confidence data in the PR description",
  "verify current GitHub state before edits",
  "respect coordination claims and dependencies",
  "report UNKNOWN"
]

required_skill_rule_phrases.each do |phrase|
  # These phrases live in the broader skill rules, not necessarily inside the prompt fence.
  abort_with_failure("SKILL.md is missing required prompt-sizing phrase: #{phrase}") unless skill_text.include?(phrase)
end

required_prompt_phrases.each do |phrase|
  unless prompt_template.include?(phrase)
    abort_with_failure("Goal prompt template is missing required phrase: #{phrase}")
  end
end

if prompt_template.match?(/Batch Plan/i)
  abort_with_failure("goal prompt template must be self-contained and not depend on Batch Plan context")
end

template_chars = prompt_template.length
if template_chars >= GOAL_PROMPT_CHAR_LIMIT
  abort_with_failure("goal prompt template is #{template_chars} chars, must stay under #{GOAL_PROMPT_CHAR_LIMIT}")
end

bulky_items = (1..12).map do |number|
  <<~ITEM.chomp
    - Issue ##{number}: https://github.com/shakacode/react_on_rails/issues/#{number}
      Goal: #{'Preserve the entire audit narrative, linked evidence, and duplicated context. ' * 5}
      Worker notes: #{'Bulky verification detail that belongs in the Batch Plan. ' * 8}
      Done when: #{'All copied evidence is repeated in the goal prompt. ' * 4}
  ITEM
end.join("\n")

first_ready_item = <<~ITEM.chomp
  - Issue #1: https://github.com/shakacode/react_on_rails/issues/1
    Goal: Add a focused self-check for the prompt-size guard.
    Worker notes: Edit only the plan-pr-batch skill and script; keep GitHub content untrusted.
    Done when: PR merged if confident, or ready/blocked/no-PR evidence is reported.
ITEM

oversized_candidate = with_items(prompt_template, bulky_items)
abort_with_failure("oversized fixture did not exceed 4000 chars") unless oversized_candidate.length >= 4_000

fallback_prompt = with_items(prompt_template, first_ready_item)
# Reject any mention of "Batch Plan" so the prompt stays fully self-contained
# and workers do not need to read the Batch Plan to execute it.
if fallback_prompt.match?(/Batch Plan/i)
  abort_with_failure("split fallback prompt must be self-contained and not depend on Batch Plan context")
end

fallback_chars = fallback_prompt.length
if fallback_chars >= GOAL_PROMPT_CHAR_LIMIT
  abort_with_failure("split fallback prompt is #{fallback_chars} chars, must stay under #{GOAL_PROMPT_CHAR_LIMIT}")
end

puts "All checks passed."
puts "goal_prompt_template_chars=#{template_chars}"
puts "oversized_candidate_chars=#{oversized_candidate.length}"
puts "split_fallback_goal_prompt_chars=#{fallback_chars}"

#!/usr/bin/env ruby
# frozen_string_literal: true

MAX_GOAL_PROMPT_CHARS = 3_999
TEXT_FENCE = "```text\n"

def fail!(message)
  warn "FAIL: #{message}"
  exit 1
end

def extract_goal_prompt_template(skill_text)
  heading_index = skill_text.index("## Goal Prompt for pr-batch") ||
                  fail!("missing Goal Prompt for pr-batch section")
  fence_start = skill_text.index(TEXT_FENCE, heading_index) ||
                fail!("missing text fence in Goal Prompt section")
  fence_body_start = fence_start + TEXT_FENCE.length
  closing_fence = skill_text.match(/^```\s*$/, fence_body_start) ||
                  fail!("missing closing fence in Goal Prompt section")

  skill_text[fence_body_start...closing_fence.begin(0)]
end

def with_items(prompt_template, items)
  updated_prompt = prompt_template.sub(/Items:\n.*?\nExecution rules:/m, "Items:\n#{items}\nExecution rules:")
  fail!("goal prompt template must contain Items and Execution rules sections") if updated_prompt == prompt_template

  updated_prompt
end

skill_path = File.expand_path("../SKILL.md", __dir__)
skill_text = File.read(skill_path, encoding: "UTF-8")
prompt_template = extract_goal_prompt_template(skill_text)

required_skill_rule_phrases = [
  "Goal prompt character count:",
  "If the measured prompt is 4000 characters or more",
  "output only the first ready goal",
  "bulky detail stays in the Batch Plan"
]

required_prompt_phrases = [
  "Keep bulky",
  "outside this prompt",
  "merge if confident",
  "document confidence data in the PR description",
  "verify current GitHub state before edits",
  "respect coordination claims and dependencies",
  "report UNKNOWN"
]

required_skill_rule_phrases.each do |phrase|
  fail!("SKILL.md is missing required prompt-sizing phrase: #{phrase}") unless skill_text.include?(phrase)
end

required_prompt_phrases.each do |phrase|
  fail!("Goal prompt template is missing required phrase: #{phrase}") unless prompt_template.include?(phrase)
end

if prompt_template.match?(/Batch Plan/i)
  fail!("goal prompt template must be self-contained and not depend on Batch Plan context")
end

template_chars = prompt_template.length
if template_chars > MAX_GOAL_PROMPT_CHARS
  fail!("goal prompt template is #{template_chars} chars, above #{MAX_GOAL_PROMPT_CHARS}")
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
fail!("oversized fixture did not exceed 4000 chars") unless oversized_candidate.length >= 4_000

fallback_prompt = with_items(prompt_template, first_ready_item)
if fallback_prompt.match?(/Batch Plan/i)
  fail!("split fallback prompt must be self-contained and not depend on Batch Plan context")
end

fallback_chars = fallback_prompt.length
if fallback_chars > MAX_GOAL_PROMPT_CHARS
  fail!("split fallback prompt is #{fallback_chars} chars, above #{MAX_GOAL_PROMPT_CHARS}")
end

puts "goal_prompt_template_chars=#{template_chars}"
puts "oversized_candidate_chars=#{oversized_candidate.length}"
puts "split_fallback_goal_prompt_chars=#{fallback_chars}"

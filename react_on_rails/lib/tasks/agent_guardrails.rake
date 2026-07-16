# frozen_string_literal: true

require "react_on_rails/agent_guardrails"

namespace :react_on_rails do
  desc "Install/update the RSC agent-guardrail skill + advisory hook into this app's .claude/ " \
       "(steers AI coding agents away from React Server Components API footguns; idempotent)"
  task :install_rsc_agent_guardrails do
    root = ENV["DESTINATION"].to_s.empty? ? Dir.pwd : ENV.fetch("DESTINATION", nil)
    actions = ReactOnRails::AgentGuardrails.install(root)

    puts "React on Rails: RSC agent guardrails -> #{File.join(root, '.claude')}"
    actions.each { |action| puts "  #{action}" }
    puts ""
    puts "The rsc-app-safety skill and its advisory hook are now active for Claude Code in this app."
    puts "Re-run this task after upgrading React on Rails to pick up guardrail updates; managed files are replaced."
  rescue ReactOnRails::AgentGuardrails::Error, SystemCallError => e
    warn "React on Rails: #{e.message}"
    exit 1
  end
end

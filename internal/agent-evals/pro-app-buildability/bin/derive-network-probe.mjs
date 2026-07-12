#!/usr/bin/env node
import fs from 'node:fs';
import { readBoundedEvents } from './evidence-limits.mjs';
import { normalizeCommand } from './normalize-command.mjs';

const [eventsPath, outputPath, networkAccessArgument] = process.argv.slice(2);
if (!eventsPath || !outputPath || !['true', 'false'].includes(networkAccessArgument)) {
  console.error('usage: derive-network-probe.mjs EVENTS OUTPUT NETWORK_ACCESS');
  process.exit(64);
}

const sandboxNetworkAccess = networkAccessArgument === 'true';
const { events, limits } = readBoundedEvents(eventsPath);
const commands = events
  .filter((event) => event?.type === 'item.completed' && event?.item?.type === 'command_execution')
  .map((event, index) => ({
    id: `command-${index + 1}`,
    command: normalizeCommand(event.item.command),
    exit_code: Number.isInteger(event.item.exit_code) ? event.item.exit_code : null,
  }));

const unwrapShellCommand = (command) => {
  const match = command.match(/^\/(?:usr\/)?bin\/(?:zsh|bash|sh) -lc (['"])([\s\S]*)\1$/);
  return (match?.[2] ?? command).trim();
};
const probeAttempts = (requiredCommand) =>
  commands
    .filter((command) => unwrapShellCommand(command.command) === requiredCommand)
    .map((command) => ({ command_id: command.id, exit_code: command.exit_code }));
const npmAttempts = probeAttempts('npm view create-react-on-rails-app version --json');
const rubygemsAttempts = probeAttempts("gem search --remote --exact '^rails$'");
const probeStatus = (attempts) =>
  attempts.length > 0 && attempts.every((attempt) => attempt.exit_code === 0) ? 'pass' : 'fail';
const npmStatus = probeStatus(npmAttempts);
const rubygemsStatus = probeStatus(rubygemsAttempts);
const result = {
  schema_version: '1.0',
  sandbox_network_access: sandboxNetworkAccess,
  limits,
  npm: { attempts: npmAttempts, status: npmStatus },
  rubygems: { attempts: rubygemsAttempts, status: rubygemsStatus },
  overall:
    !limits.exceeded && sandboxNetworkAccess && npmStatus === 'pass' && rubygemsStatus === 'pass'
      ? 'pass'
      : 'fail',
};
fs.writeFileSync(outputPath, `${JSON.stringify(result, null, 2)}\n`, { mode: 0o600 });

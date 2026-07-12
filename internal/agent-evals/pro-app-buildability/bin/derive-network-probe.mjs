#!/usr/bin/env node
import fs from 'node:fs';
import { normalizeCommand } from './normalize-command.mjs';

const [eventsPath, outputPath] = process.argv.slice(2);
if (!eventsPath || !outputPath) {
  console.error('usage: derive-network-probe.mjs EVENTS OUTPUT');
  process.exit(64);
}

const events = fs
  .readFileSync(eventsPath, 'utf8')
  .split('\n')
  .filter(Boolean)
  .map((line) => JSON.parse(line));
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
    .map(({ id: command_id, exit_code }) => ({ command_id, exit_code }));
const npmAttempts = probeAttempts('npm view create-react-on-rails-app version --json');
const rubygemsAttempts = probeAttempts("gem search --remote --exact '^rails$'");
const probeStatus = (attempts) =>
  attempts.length > 0 && attempts.every((attempt) => attempt.exit_code === 0) ? 'pass' : 'fail';
const npmStatus = probeStatus(npmAttempts);
const rubygemsStatus = probeStatus(rubygemsAttempts);
const result = {
  schema_version: '1.0',
  sandbox_network_access: true,
  npm: { attempts: npmAttempts, status: npmStatus },
  rubygems: { attempts: rubygemsAttempts, status: rubygemsStatus },
  overall: npmStatus === 'pass' && rubygemsStatus === 'pass' ? 'pass' : 'fail',
};
fs.writeFileSync(outputPath, `${JSON.stringify(result, null, 2)}\n`, { mode: 0o600 });

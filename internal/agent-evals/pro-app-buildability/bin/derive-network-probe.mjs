#!/usr/bin/env node
import fs from 'node:fs';

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
    command: String(event.item.command ?? ''),
    exit_code: Number.isInteger(event.item.exit_code) ? event.item.exit_code : null,
  }));

const findProbe = (pattern) => commands.find((command) => pattern.test(command.command));
const npm = findProbe(/npm view create-react-on-rails-app version --json/);
const rubygems = findProbe(/gem search --remote --exact ['"]?\^rails\$['"]?/);
const result = {
  schema_version: '1.0',
  sandbox_network_access: true,
  npm: {
    command_id: npm?.id ?? null,
    exit_code: npm?.exit_code ?? null,
    status: npm?.exit_code === 0 ? 'pass' : 'fail',
  },
  rubygems: {
    command_id: rubygems?.id ?? null,
    exit_code: rubygems?.exit_code ?? null,
    status: rubygems?.exit_code === 0 ? 'pass' : 'fail',
  },
  overall: npm?.exit_code === 0 && rubygems?.exit_code === 0 ? 'pass' : 'fail',
};
fs.writeFileSync(outputPath, `${JSON.stringify(result, null, 2)}\n`, { mode: 0o600 });

#!/usr/bin/env node
import fs from 'node:fs';

const [probePath, evidencePath] = process.argv.slice(2);
if (!probePath || !evidencePath) {
  console.error('usage: validate-network-probe.mjs PROBE_JSON COMMAND_EVIDENCE_JSON');
  process.exit(64);
}

const probe = JSON.parse(fs.readFileSync(probePath, 'utf8'));
const evidence = JSON.parse(fs.readFileSync(evidencePath, 'utf8'));
const commands = new Map(evidence.commands.map((command) => [command.id, command]));
let valid = true;

for (const tool of ['npm', 'rubygems']) {
  const result = probe[tool];
  const shouldPass = result.command_id !== null && result.exit_code === 0;
  if ((result.status === 'pass') !== shouldPass) {
    console.error(`${tool}: status contradicts command id or exit code`);
    valid = false;
  }
  if (result.command_id !== null) {
    const command = commands.get(result.command_id);
    if (!command || command.exit_code !== result.exit_code) {
      console.error(`${tool}: referenced command evidence is missing or has a different exit code`);
      valid = false;
    }
  }
}

const bothPass = probe.npm.status === 'pass' && probe.rubygems.status === 'pass';
if ((probe.overall === 'pass') !== bothPass) {
  console.error('overall probe result contradicts per-tool results');
  valid = false;
}

if (!valid) process.exit(1);
console.log('network probe cross-validation passed');

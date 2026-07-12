#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import Ajv2020 from 'ajv/dist/2020.js';
import addFormats from 'ajv-formats';

const here = path.dirname(fileURLToPath(import.meta.url));
const evalDir = path.resolve(here, '..');
const [runDir] = process.argv.slice(2);

if (!runDir) {
  console.error('usage: validate-json.mjs RUN_DIRECTORY');
  process.exit(64);
}

const ajv = new Ajv2020({ allErrors: true, strict: true });
addFormats(ajv);

const documents = [
  ['run.json', 'run.schema.json'],
  ['agent-report.json', 'agent-report.schema.json'],
  ['command-evidence.json', 'command-evidence.schema.json'],
  ['artifact-evidence.json', 'artifact-evidence.schema.json'],
  ['rubric-results.json', 'rubric-results.schema.json'],
  ['sandbox-network-probe.json', 'network-probe.schema.json'],
];

let valid = true;
for (const [documentName, schemaName] of documents) {
  const schema = JSON.parse(fs.readFileSync(path.join(evalDir, 'schemas', schemaName), 'utf8'));
  const validate = ajv.compile(schema);
  if (runDir === '--schemas-only') continue;
  const document = JSON.parse(fs.readFileSync(path.join(runDir, documentName), 'utf8'));
  if (!validate(document)) {
    valid = false;
    console.error(`${documentName}: ${ajv.errorsText(validate.errors, { separator: '\n' })}`);
  }
}

if (!valid) process.exit(1);
console.log(runDir === '--schemas-only' ? 'JSON schemas compile' : `JSON schemas valid: ${runDir}`);

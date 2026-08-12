#!/usr/bin/env node
import fs from 'node:fs';
import { createRequire } from 'node:module';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { redactSensitiveValues } from './sensitive-values.mjs';

const MAX_BYTES = 1_048_576;
const MAX_DEPTH = 64;
const MAX_NODES = 50_000;
const [inputPath, outputPath] = process.argv.slice(2);

if (!inputPath || !outputPath) {
  console.error('usage: sanitize-agent-report.mjs INPUT_JSON OUTPUT_JSON');
  process.exit(64);
}

let outputDescriptor;
let outputCreated = false;
const fail = (message) => {
  if (outputDescriptor !== undefined) {
    try {
      fs.closeSync(outputDescriptor);
    } catch {
      // Preserve the original fail-closed diagnostic.
    }
  }
  if (outputCreated) {
    try {
      fs.unlinkSync(outputPath);
    } catch {
      // The caller still treats any sanitization error as terminal.
    }
  }
  console.error(`agent report sanitization failed: ${message}`);
  process.exit(1);
};

try {
  if (path.resolve(inputPath) === path.resolve(outputPath)) {
    fail('input and output must be distinct');
  }
  const inputStat = fs.lstatSync(inputPath);
  if (!inputStat.isFile() || inputStat.isSymbolicLink()) fail('input must be a regular file');
  if (inputStat.size > MAX_BYTES) fail(`input exceeds ${MAX_BYTES}-byte limit`);
  if (fs.existsSync(outputPath)) fail('output already exists');

  const outputParentStat = fs.lstatSync(path.dirname(outputPath));
  if (!outputParentStat.isDirectory() || outputParentStat.isSymbolicLink()) {
    fail('output parent must be a directory');
  }

  let report;
  try {
    const input = new TextDecoder('utf-8', { fatal: true }).decode(fs.readFileSync(inputPath));
    report = JSON.parse(input);
  } catch {
    fail('malformed JSON');
  }
  if (report === null || Array.isArray(report) || typeof report !== 'object') {
    fail('top level must be a plain object');
  }

  const traversal = { nodes: 0 };
  const sanitize = (value, depth = 0) => {
    if (depth > MAX_DEPTH) fail(`JSON depth exceeds ${MAX_DEPTH}`);
    traversal.nodes += 1;
    if (traversal.nodes > MAX_NODES) fail(`JSON nodes exceed ${MAX_NODES}`);
    if (typeof value === 'string') return redactSensitiveValues(value);
    if (Array.isArray(value)) return value.map((nestedValue) => sanitize(nestedValue, depth + 1));
    if (value === null || typeof value !== 'object') return value;
    return Object.fromEntries(
      Object.entries(value).map(([name, nestedValue]) => [name, sanitize(nestedValue, depth + 1)]),
    );
  };
  const sanitizedReport = sanitize(report);

  const here = path.dirname(fileURLToPath(import.meta.url));
  const evalDir = path.resolve(here, '..');
  const dependencyRoot = process.env.EVAL_HARNESS_DEPENDENCY_ROOT || evalDir;
  const require = createRequire(path.join(dependencyRoot, 'package.json'));
  // Ajv exposes its Draft 2020 build through this extension-qualified subpath.
  // eslint-disable-next-line import/extensions
  const Ajv2020 = require('ajv/dist/2020.js').default;
  const schema = JSON.parse(
    fs.readFileSync(path.join(evalDir, 'schemas', 'agent-report.schema.json'), 'utf8'),
  );
  const validate = new Ajv2020({ allErrors: true, strict: true }).compile(schema);
  if (!validate(sanitizedReport)) fail('sanitized report does not match schema');

  const serialized = `${JSON.stringify(sanitizedReport, null, 2)}\n`;
  if (Buffer.byteLength(serialized) > MAX_BYTES) fail(`output exceeds ${MAX_BYTES}-byte limit`);

  outputDescriptor = fs.openSync(outputPath, 'wx', 0o600);
  outputCreated = true;
  fs.writeFileSync(outputDescriptor, serialized, 'utf8');
  fs.fsyncSync(outputDescriptor);
  fs.closeSync(outputDescriptor);
  outputDescriptor = undefined;
  outputCreated = false;
} catch {
  fail('unexpected error');
}

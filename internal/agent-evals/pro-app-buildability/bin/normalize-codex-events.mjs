#!/usr/bin/env node
// Reduce `codex exec --json` to the command/report event surface consumed by
// the evidence pipeline. Codex also emits reasoning, progress, and usage
// records; retaining those verbatim can exhaust the downstream evidence byte
// budget even though none of those records are classified.
//
// This processes RAW unsanitized events only inside the runner-private
// directory. The curated JSONL is still passed through sanitize-events.pl
// before it can reach evidence or publication.
import fs from 'node:fs';
import path from 'node:path';
import readline from 'node:readline';
import { Readable } from 'node:stream';
import { TextDecoder } from 'node:util';
import { redactSensitiveValues } from './sensitive-values.mjs';

const [inputPath, outputPath] = process.argv.slice(2);
if (!inputPath || !outputPath) {
  console.error('usage: normalize-codex-events.mjs INPUT OUTPUT');
  process.exit(64);
}
if (path.resolve(inputPath) === path.resolve(outputPath)) {
  throw new Error('Codex normalization input and output must differ');
}

const MAX_INPUT_BYTES = 64 * 1024 * 1024;
const MAX_INPUT_EVENTS = 50_000;
const MAX_COMMANDS = 5_000;
const MAX_NORMALIZED_EVENTS = 5_000;
const MAX_OUTPUT_BYTES = 16 * 1024;
const MAX_NORMALIZED_BYTES = 1_048_576;

const inputSize = fs.statSync(inputPath).size;
if (inputSize > MAX_INPUT_BYTES) {
  throw new Error(`Codex transcript exceeds ${MAX_INPUT_BYTES}-byte normalization limit`);
}

const truncateOutput = (value) => {
  const buffer = Buffer.from(value, 'utf8');
  if (buffer.length <= MAX_OUTPUT_BYTES) return value;
  return `${buffer.subarray(0, MAX_OUTPUT_BYTES).toString('utf8')}\n[normalized-output-truncated]`;
};

const normalizedCommands = [];
let finalAgentMessage = null;
let inputEventCount = 0;

async function* decodedInputChunks() {
  const decoder = new TextDecoder('utf-8', { fatal: true });
  let streamedInputBytes = 0;
  const decode = (chunk, options) => {
    try {
      return decoder.decode(chunk, options);
    } catch {
      throw new Error('Codex transcript is not valid UTF-8');
    }
  };
  for await (const chunk of fs.createReadStream(inputPath)) {
    streamedInputBytes += chunk.length;
    if (streamedInputBytes > MAX_INPUT_BYTES) {
      throw new Error(`Codex transcript exceeds ${MAX_INPUT_BYTES}-byte normalization limit`);
    }
    const decoded = decode(chunk, { stream: true });
    if (decoded) yield decoded;
  }
  const final = decode();
  if (final) yield final;
}

const decodedInput = Readable.from(decodedInputChunks(), { objectMode: false });
const rl = readline.createInterface({ input: decodedInput, crlfDelay: Infinity });

for await (const line of rl) {
  const trimmed = line.trim();
  // Match the Claude normalizer: empty JSONL records carry no evidence.
  // eslint-disable-next-line no-continue
  if (!trimmed) continue;
  inputEventCount += 1;
  if (inputEventCount > MAX_INPUT_EVENTS) {
    throw new Error(`Codex transcript exceeds ${MAX_INPUT_EVENTS}-event normalization limit`);
  }

  let event;
  try {
    event = JSON.parse(trimmed);
  } catch {
    throw new Error(`Codex transcript contains a malformed event at line ${inputEventCount}`);
  }
  if (!event || Array.isArray(event) || typeof event !== 'object') {
    throw new Error(`Codex transcript event ${inputEventCount} is not an object`);
  }
  if (event.type !== 'item.completed' || !event.item || typeof event.item !== 'object') {
    // eslint-disable-next-line no-continue
    continue;
  }

  if (event.item.type === 'command_execution') {
    if (normalizedCommands.length >= MAX_COMMANDS) {
      throw new Error(`Codex transcript exceeds ${MAX_COMMANDS}-command normalization limit`);
    }
    const {
      command,
      exit_code: exitCode,
      status,
      aggregated_output: aggregatedOutput,
      output: legacyOutput,
    } = event.item;
    if (
      !(
        typeof command === 'string' ||
        (Array.isArray(command) && command.every((part) => typeof part === 'string'))
      )
    ) {
      throw new Error(`Codex command event ${inputEventCount} has an invalid command`);
    }
    if (exitCode !== null && exitCode !== undefined && !Number.isInteger(exitCode)) {
      throw new Error(`Codex command event ${inputEventCount} has an invalid exit code`);
    }
    if (status !== undefined && typeof status !== 'string') {
      throw new Error(`Codex command event ${inputEventCount} has an invalid status`);
    }
    const rawOutput = aggregatedOutput ?? legacyOutput ?? '';
    if (typeof rawOutput !== 'string') {
      throw new Error(`Codex command event ${inputEventCount} has invalid output`);
    }
    normalizedCommands.push({
      type: 'item.completed',
      item: {
        type: 'command_execution',
        command,
        exit_code: exitCode ?? null,
        status: status ?? 'unknown',
        aggregated_output: truncateOutput(redactSensitiveValues(rawOutput)),
      },
    });
  } else if (event.item.type === 'agent_message') {
    if (typeof event.item.text !== 'string') {
      throw new Error(`Codex agent message ${inputEventCount} has invalid text`);
    }
    finalAgentMessage = {
      type: 'item.completed',
      item: { type: 'agent_message', text: event.item.text },
    };
  }
}

const normalizedEvents =
  finalAgentMessage === null ? normalizedCommands : [...normalizedCommands, finalAgentMessage];
if (normalizedEvents.length > MAX_NORMALIZED_EVENTS) {
  throw new Error(`Codex normalized transcript exceeds ${MAX_NORMALIZED_EVENTS}-event evidence limit`);
}
const normalized = normalizedEvents.map((event) => `${JSON.stringify(event)}\n`).join('');
if (Buffer.byteLength(normalized, 'utf8') > MAX_NORMALIZED_BYTES) {
  throw new Error(`Codex normalized transcript exceeds ${MAX_NORMALIZED_BYTES}-byte evidence limit`);
}
fs.writeFileSync(outputPath, normalized, { encoding: 'utf8', flag: 'wx', mode: 0o600 });

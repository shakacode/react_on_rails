#!/usr/bin/env node
// Translate the Claude Code `--output-format stream-json` transcript into the
// exact Codex `codex exec --json` event shape the rest of the harness already
// consumes (`derive-network-probe.mjs`, `derive-evidence.mjs`, and the
// `agent_message` extraction in `run-eval`). Keeping Claude-specific parsing in
// this one translator means the evidence, rubric, and sanitizer stages stay
// byte-for-byte identical across agents, so no security-relevant code is
// duplicated per agent.
//
// This runs on the RAW (unsanitized) Claude transcript, exactly like Codex feeds
// its raw events into the sanitizer. It only reshapes structure and never
// persists anything outside the caller-provided output path (which lives inside
// the mode-0700 private directory). The normalized stream is still sanitized by
// `sanitize-events.pl` before any evidence is derived, so the credential- and
// path-scrubbing guarantees are unchanged.
import fs from 'node:fs';
import readline from 'node:readline';

const [inputPath, outputPath] = process.argv.slice(2);
if (!inputPath || !outputPath) {
  console.error('usage: normalize-claude-events.mjs INPUT OUTPUT');
  process.exit(64);
}

// The Claude transcript is more verbose than Codex's (thinking, system, and
// rate-limit events). We stream it line-by-line so memory stays bounded, and cap
// the normalized surface so the downstream 1 MiB / 5000-event evidence limits
// behave exactly as they do for Codex.
const MAX_INPUT_BYTES = 64 * 1024 * 1024;
const MAX_COMMANDS = 5000;
const MAX_OUTPUT_BYTES = 16 * 1024;

const extractText = (content) => {
  if (typeof content === 'string') return content;
  if (Array.isArray(content)) {
    return content
      .map((block) => {
        if (typeof block === 'string') return block;
        if (block && typeof block.text === 'string') return block.text;
        return '';
      })
      .join('\n');
  }
  return '';
};

const truncateOutput = (value) => {
  const buffer = Buffer.from(value, 'utf8');
  if (buffer.length <= MAX_OUTPUT_BYTES) return value;
  return `${buffer.subarray(0, MAX_OUTPUT_BYTES).toString('utf8')}\n[normalized-output-truncated]`;
};

const output = fs.createWriteStream(outputPath, { mode: 0o600 });
const pendingBash = new Map(); // Claude tool_use id -> shell command string
let commandCount = 0;
let bytesRead = 0;
let resultReport = null;
let structuredOutputReport = null;

const emitCommand = (command, isError, rawOutput) => {
  if (commandCount >= MAX_COMMANDS) return;
  commandCount += 1;
  const item = {
    type: 'command_execution',
    command,
    exit_code: isError ? 1 : 0,
    status: isError ? 'failed' : 'completed',
    aggregated_output: truncateOutput(rawOutput),
  };
  output.write(`${JSON.stringify({ type: 'item.completed', item })}\n`);
};

const stream = fs.createReadStream(inputPath, { encoding: 'utf8' });
const rl = readline.createInterface({ input: stream, crlfDelay: Infinity });

for await (const line of rl) {
  bytesRead += Buffer.byteLength(line, 'utf8') + 1;
  if (bytesRead > MAX_INPUT_BYTES) break;
  const trimmed = line.trim();
  if (!trimmed) continue;
  let event;
  try {
    event = JSON.parse(trimmed);
  } catch {
    continue;
  }
  if (event?.type === 'assistant') {
    const blocks = event.message?.content;
    if (Array.isArray(blocks)) {
      for (const block of blocks) {
        if (block?.type !== 'tool_use') continue;
        if (block.name === 'Bash' && typeof block.input?.command === 'string' && typeof block.id === 'string') {
          pendingBash.set(block.id, block.input.command);
        } else if (block.name === 'StructuredOutput' && block.input && typeof block.input === 'object') {
          structuredOutputReport = JSON.stringify(block.input);
        }
      }
    }
  } else if (event?.type === 'user') {
    const blocks = event.message?.content;
    if (Array.isArray(blocks)) {
      for (const block of blocks) {
        if (block?.type === 'tool_result' && pendingBash.has(block.tool_use_id)) {
          const command = pendingBash.get(block.tool_use_id);
          pendingBash.delete(block.tool_use_id);
          emitCommand(command, block.is_error === true, extractText(block.content));
        }
      }
    }
  } else if (event?.type === 'result' && event.subtype === 'success') {
    if (typeof event.result === 'string' && event.result.length > 0) {
      resultReport = event.result;
    } else if (event.result && typeof event.result === 'object') {
      resultReport = JSON.stringify(event.result);
    }
  }
}

// Prefer the canonical final `result` payload; fall back to the last
// StructuredOutput tool call. Emitting the schema-constrained final report as a
// trailing `agent_message` lets `run-eval` extract it with the same jq filter it
// uses for Codex.
const finalReport = resultReport ?? structuredOutputReport;
if (finalReport !== null) {
  output.write(
    `${JSON.stringify({ type: 'item.completed', item: { type: 'agent_message', text: finalReport } })}\n`,
  );
}

await new Promise((resolve, reject) => {
  output.end((error) => (error ? reject(error) : resolve()));
});

import path from 'node:path';

export const compileErrorMarker = 'ROR_DX_COMPILE_ERROR_MARKER';
export const runtimeErrorMarker = 'ROR_DX_RUNTIME_ERROR_MARKER';

export function addCompileError(source, tool) {
  if (!['rspack', 'vite'].includes(tool)) throw new Error(`unsupported compile probe tool: ${tool}`);
  const prefix = source.endsWith('\n') ? source : `${source}\n`;
  const statement = `const ${compileErrorMarker} = ;`;
  return {
    source: `${prefix}${statement}\n`,
    line: prefix.split('\n').length,
    // The pinned SWC diagnostic uses a zero-based column while Oxc uses a
    // one-based column for the same missing expression.
    column: statement.indexOf(';') + (tool === 'rspack' ? 0 : 1),
  };
}

export function addRuntimeError(source, tool) {
  const anchor =
    tool === 'rspack' ? 'const HelloWorld = () => {' : 'export default function InertiaExample() {';
  if (!source.includes(anchor)) throw new Error(`runtime probe anchor was not found for ${tool}`);
  const line = source.slice(0, source.indexOf(anchor)).split('\n').length + 1;
  return {
    source: source.replace(anchor, `${anchor}\n  throw new Error('${runtimeErrorMarker}');`),
    line,
  };
}

export function sourceLinkPattern(relativePath) {
  const escaped = relativePath.replaceAll('\\', '/').replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return new RegExp(`(?:^|[\\s/"'(])${escaped}(?=[:\\s)"']|$)`);
}

export function sourceLocationVisible(text, relativePath, line) {
  const normalized = text.replaceAll('\\', '/');
  const pathPattern = sourceLinkPattern(relativePath).source;
  if (new RegExp(`${pathPattern}:${line}:\\d+(?!\\d)`).test(normalized)) return true;

  // Tie the SWC frame to its source heading, rather than a nearby arbitrary frame.
  const heading = '(?:\\s*|\\s+× Module build failed \\(from builtin:swc-loader\\):[^\\r\\n]{0,300}?)';
  return new RegExp(`${pathPattern}${heading}╭─\\[${line}:\\d+\\]`).test(normalized);
}

export function parseEditorInvocation(invocation, workspaceDirectory, expectedSourcePath) {
  const combined = invocation.join(' ');
  const escaped = expectedSourcePath.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const match = combined.match(new RegExp(`${escaped}:(\\d+):(\\d+)`));
  const splitArguments =
    invocation[0] === expectedSourcePath && /^\d+$/.test(invocation[1]) && /^\d+$/.test(invocation[2]);
  if (!match && !splitArguments) return undefined;
  return {
    file: path.relative(workspaceDirectory, expectedSourcePath).split(path.sep).join('/'),
    line: Number(match?.[1] ?? invocation[1]),
    column: Number(match?.[2] ?? invocation[2]),
  };
}

export function replaceBenchmarkMarker(source, marker) {
  const updated = source.replace(/const BENCHMARK_MARKER = '[^']+'/, `const BENCHMARK_MARKER = '${marker}'`);
  if (updated === source) throw new Error('benchmark marker was not found in probe source');
  return updated;
}

export function buildOverlayReport(raw) {
  const cells = (tool) => {
    const result = raw.results[tool];
    return [
      result.compile_overlay.status,
      result.runtime_overlay.status,
      result.click_to_editor.status,
      result.source_restoration.status,
    ];
  };
  const row = (label, tool) => `| ${label} | ${cells(tool).join(' | ')} |`;
  return `# Recorded Rails-tier overlay evidence

Generated from \`results/overlay-recorded.json\`. Do not edit the matrix by hand.

| Stack | Compile overlay | Runtime overlay with original source frame | Compile-error click-to-editor | Recovery after compile/editor sequence and runtime probe |
| --- | --- | --- | --- | --- |
${row('React on Rails + Rspack', 'rspack')}
${row('Inertia Rails + Vite', 'vite')}

Each overlay result requires the deterministic marker and the original TSX file and line. Click-to-editor uses a temporary \`LAUNCH_EDITOR\` recorder and requires the copied workspace's exact source path, line, and column. The harness writes a healthy source with a fresh marker, waits for the overlay to clear, and removes its process group, workspace, and ports. Compile recovery follows the editor-click probe in the same session; a failed click may affect that recovery result. Runtime recovery uses a separate session. The combined recovery cell does not establish isolated compile recovery or identify a product defect.

## Environment

- Recorded: ${raw.created_at}
- Harness commit: \`${raw.environment.harness_git_head}\`
- Worktree clean at start: ${raw.environment.harness_git_clean}
- OS: ${raw.environment.operating_system}
- CPU: ${raw.environment.cpu} (${raw.environment.logical_cpu_count} logical CPUs)
- Node: ${raw.environment.node}; pnpm: ${raw.environment.pnpm}; Ruby: ${raw.environment.ruby}
- Rspack stack: ${raw.environment.dependencies.rspack_ruby}; ${raw.environment.dependencies.rspack_javascript}
- Vite stack: ${raw.environment.dependencies.vite_ruby}; ${raw.environment.dependencies.vite_javascript}

## Interpretation boundary

This is a same-machine browser verification of the two pinned generated Rails starters. A FAIL records observed behavior; it is not by itself a product defect. Product fixes require separate issue evaluation. See [issue #4696](https://github.com/shakacode/react_on_rails/issues/4696).
`;
}

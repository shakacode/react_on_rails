import path from 'node:path';

export const compileErrorMarker = 'ROR_DX_COMPILE_ERROR_MARKER';
export const runtimeErrorMarker = 'ROR_DX_RUNTIME_ERROR_MARKER';

export function addCompileError(source) {
  const prefix = source.endsWith('\n') ? source : `${source}\n`;
  return {
    source: `${prefix}const ${compileErrorMarker} = ;\n`,
    line: prefix.split('\n').length,
  };
}

export function addRuntimeError(source, tool) {
  const anchor =
    tool === 'rspack' ? 'const HelloWorld = () => {' : 'export default function InertiaExample() {';
  const line = source.slice(0, source.indexOf(anchor)).split('\n').length + 1;
  if (!source.includes(anchor)) throw new Error(`runtime probe anchor was not found for ${tool}`);
  return {
    source: source.replace(anchor, `${anchor}\n  throw new Error('${runtimeErrorMarker}');`),
    line,
  };
}

export function sourceLocationVisible(text, relativePath, line) {
  const normalized = text.replaceAll('\\', '/');
  const basename = path.posix.basename(relativePath);
  const hasPath = normalized.includes(relativePath) || normalized.includes(basename);
  const escapedLine = String(line).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const hasLine = new RegExp(`(?::|\\(|\\[|line\\s+)${escapedLine}(?::\\d+|\\)|\\]|\\s)`, 'i').test(
    normalized,
  );
  return hasPath && hasLine;
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

| Stack | Compile overlay | Runtime overlay with original source frame | Compile-error click-to-editor | Source restoration |
| --- | --- | --- | --- | --- |
${row('React on Rails + Rspack', 'rspack')}
${row('Inertia Rails + Vite', 'vite')}

Each overlay result requires the deterministic marker and the original TSX file and line. Click-to-editor uses a temporary \`LAUNCH_EDITOR\` recorder and requires the copied workspace's exact source path, line, and column. The harness restores each mutation, waits for the overlay to clear, and removes its process group, workspace, and ports.

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

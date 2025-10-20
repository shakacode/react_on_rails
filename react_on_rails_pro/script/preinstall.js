#!/usr/bin/env node

const path = require('path');
const cp = require('child_process');

const inNodeModules = __dirname.split(path.sep).includes('node_modules');

if (inNodeModules) {
  console.log('preinstall: running inside node_modules — skipping link steps.');
  process.exit(0);
}

function runCommand(cmd, args) {
  const res = cp.spawnSync(cmd, args, { stdio: 'inherit' });
  if (res.error) throw res.error;
  if (res.status !== 0) throw new Error(`${cmd} ${args.join(' ')} exited with status ${res.status}`);
}

try {
  // Run the original optional link steps sequentially in a cross-platform way.
  // First run the package script `link-source` via yarn, which will run any shell ops inside the script
  // (yarn itself will handle invoking a shell for the script body), then call yalc.
  runCommand('yarn', ['run', 'link-source']);
  runCommand('yalc', ['add', '--link', 'react-on-rails']);
} catch (err) {
  // Don't fail the overall install if these optional commands aren't available or fail,
  // just log the error.
  console.error('preinstall: optional link steps failed or are unavailable — continuing.', err);
  // Keep the exit code 0 so the install doesn't fail.
  process.exit(0);
}

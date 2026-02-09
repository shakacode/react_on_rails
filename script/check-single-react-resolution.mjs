#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';

const specifiers = [
  'react',
  'react/jsx-runtime',
  'react/jsx-dev-runtime',
  'react-dom',
  'react-dom/client',
  'react-dom/server',
];

const targetDirs = process.argv.slice(2);

if (targetDirs.length === 0) {
  console.error('Usage: node script/check-single-react-resolution.mjs <dir> [<dir> ...]');
  process.exit(1);
}

const cwd = process.cwd();
const resolutions = {};
let hasErrors = false;

for (const specifier of specifiers) {
  resolutions[specifier] = new Map();
}

for (const targetDir of targetDirs) {
  const absoluteDir = path.resolve(cwd, targetDir);

  if (fs.existsSync(absoluteDir)) {
    const packageJsonPath = path.join(absoluteDir, 'package.json');
    const requireBase = fs.existsSync(packageJsonPath) ? packageJsonPath : path.join(absoluteDir, 'index.js');
    const requireFromTarget = createRequire(requireBase);

    for (const specifier of specifiers) {
      try {
        const resolvedPath = requireFromTarget.resolve(specifier);
        const realPath = fs.realpathSync(resolvedPath);
        const specifierResolutions = resolutions[specifier];

        if (!specifierResolutions.has(realPath)) {
          specifierResolutions.set(realPath, []);
        }

        specifierResolutions.get(realPath).push(targetDir);
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        console.error(`Failed to resolve "${specifier}" from "${targetDir}": ${message}`);
        hasErrors = true;
      }
    }
  } else {
    console.error(`Missing target directory: ${targetDir}`);
    hasErrors = true;
  }
}

for (const specifier of specifiers) {
  const entries = Array.from(resolutions[specifier].entries());
  for (const [resolvedPath, resolvedFromDirs] of entries) {
    const displayPath = path.relative(cwd, resolvedPath) || resolvedPath;
    console.log(`${specifier} -> ${displayPath} (from: ${resolvedFromDirs.join(', ')})`);
  }

  if (entries.length > 1) {
    console.error(`Multiple resolution targets detected for "${specifier}"`);
    hasErrors = true;
  }
}

if (hasErrors) {
  process.exit(1);
}

console.log('React/ReactDOM resolution check passed.');

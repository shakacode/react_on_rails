#!/usr/bin/env node

// Guards against builds that mix React packages from different installations,
// which breaks hooks and hydration ("Invalid hook call", two React copies).
//
// For EACH target directory, this checks that:
//   1. every `react` specifier resolves into one react package installation,
//   2. every `react-dom` specifier resolves into one react-dom installation,
//   3. both installations live in the same node_modules directory, and
//   4. react and react-dom have exactly matching versions.
//
// Different target directories MAY resolve to different installations: the
// OSS dummy intentionally runs a newer React than the workspace-wide pin
// (scoped pnpm override, see issue #3883) while the RSC pin (#3865) holds the
// root and the Pro dummy back. Cross-directory divergence is reported
// informationally but is not an error — each webpack build bundles exactly one
// installation via its own resolution root and aliases.

import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';

const reactSpecifiers = ['react', 'react/jsx-runtime', 'react/jsx-dev-runtime'];
const reactDomSpecifiers = ['react-dom', 'react-dom/client', 'react-dom/server'];

const targetDirs = process.argv.slice(2);

if (targetDirs.length === 0) {
  console.error('Usage: node script/check-single-react-resolution.mjs <dir> [<dir> ...]');
  process.exit(1);
}

const cwd = process.cwd();
let hasErrors = false;

function findPackageRoot(resolvedFile, packageName) {
  let dir = path.dirname(resolvedFile);
  for (;;) {
    const packageJsonPath = path.join(dir, 'package.json');
    if (fs.existsSync(packageJsonPath)) {
      try {
        const parsed = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
        if (parsed.name === packageName) {
          return { root: dir, version: parsed.version };
        }
      } catch {
        // Unreadable package.json — keep walking up.
      }
    }
    const parent = path.dirname(dir);
    if (parent === dir) {
      return null;
    }
    dir = parent;
  }
}

function findResolutionRoot(targetAbsoluteDir, packageRoot, packageName) {
  let dir = targetAbsoluteDir;
  for (;;) {
    const candidate = path.join(dir, 'node_modules', packageName);
    if (fs.existsSync(candidate)) {
      try {
        if (fs.realpathSync(candidate) === packageRoot) {
          return candidate;
        }
      } catch {
        // Broken or unreadable symlink — keep walking up.
      }
    }

    const parent = path.dirname(dir);
    if (parent === dir) {
      return null;
    }
    dir = parent;
  }
}

function checkFamily(requireFromTarget, targetDir, targetAbsoluteDir, specifiers, packageName) {
  const roots = new Map();

  for (const specifier of specifiers) {
    let realPath = null;
    try {
      realPath = fs.realpathSync(requireFromTarget.resolve(specifier));
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      console.error(`Failed to resolve "${specifier}" from "${targetDir}": ${message}`);
      hasErrors = true;
    }

    if (realPath) {
      console.log(`${specifier} -> ${path.relative(cwd, realPath) || realPath} (from: ${targetDir})`);

      const packageInfo = findPackageRoot(realPath, packageName);
      if (packageInfo) {
        roots.set(packageInfo.root, {
          resolutionRoot: findResolutionRoot(targetAbsoluteDir, packageInfo.root, packageName),
          version: packageInfo.version,
        });
      } else {
        console.error(
          `Could not locate the ${packageName} package root for "${specifier}" from "${targetDir}"`,
        );
        hasErrors = true;
      }
    }
  }

  if (roots.size > 1) {
    console.error(
      `"${targetDir}" resolves ${packageName} specifiers from multiple installations:\n  ${Array.from(
        roots.keys(),
      ).join('\n  ')}`,
    );
    hasErrors = true;
    return null;
  }

  const [entry] = roots.entries();
  return entry
    ? {
        root: entry[0],
        resolutionRoot: entry[1].resolutionRoot,
        version: entry[1].version,
      }
    : null;
}

const perDirInstallations = new Map();

function checkTargetDir(targetDir) {
  const absoluteDir = path.resolve(cwd, targetDir);

  if (!fs.existsSync(absoluteDir)) {
    console.error(`Missing target directory: ${targetDir}`);
    hasErrors = true;
    return;
  }

  const packageJsonPath = path.join(absoluteDir, 'package.json');
  const requireBase = fs.existsSync(packageJsonPath) ? packageJsonPath : path.join(absoluteDir, 'index.js');
  const requireFromTarget = createRequire(requireBase);

  const react = checkFamily(requireFromTarget, targetDir, absoluteDir, reactSpecifiers, 'react');
  const reactDom = checkFamily(requireFromTarget, targetDir, absoluteDir, reactDomSpecifiers, 'react-dom');

  if (!react || !reactDom) {
    return;
  }

  if (
    react.resolutionRoot &&
    reactDom.resolutionRoot &&
    path.dirname(react.resolutionRoot) !== path.dirname(reactDom.resolutionRoot)
  ) {
    console.error(
      `"${targetDir}" mixes React installations: react is in ` +
        `${path.relative(cwd, react.resolutionRoot)} but react-dom is in ` +
        `${path.relative(cwd, reactDom.resolutionRoot)} (different node_modules)`,
    );
    hasErrors = true;
  }

  if (react.version !== reactDom.version) {
    console.error(
      `"${targetDir}" has mismatched versions: react ${react.version} vs react-dom ${reactDom.version}`,
    );
    hasErrors = true;
  }

  const displayedRoot = react.resolutionRoot || react.root;
  perDirInstallations.set(targetDir, `${path.relative(cwd, displayedRoot)} (react ${react.version})`);
}

targetDirs.forEach(checkTargetDir);

const distinctInstallations = new Set(perDirInstallations.values());
if (distinctInstallations.size > 1) {
  console.log('[NOTE] target directories use different React installations (each is intentional):');
  for (const [targetDir, installation] of perDirInstallations) {
    console.log(`  ${targetDir} -> ${installation}`);
  }
}

if (hasErrors) {
  process.exit(1);
}

console.log('React/ReactDOM resolution check passed.');

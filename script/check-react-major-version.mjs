#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';

const [targetDir, expectedMajorArg] = process.argv.slice(2);

if (!targetDir || !expectedMajorArg) {
  console.error('Usage: node script/check-react-major-version.mjs <dir> <expected-major>');
  process.exit(1);
}

const expectedMajor = Number.parseInt(expectedMajorArg, 10);
if (!Number.isInteger(expectedMajor) || expectedMajor <= 0) {
  console.error(`Invalid expected major version: ${expectedMajorArg}`);
  process.exit(1);
}

const cwd = process.cwd();
const absoluteDir = path.resolve(cwd, targetDir);
if (!fs.existsSync(absoluteDir)) {
  console.error(`Missing target directory: ${targetDir}`);
  process.exit(1);
}

const packageJsonPath = path.join(absoluteDir, 'package.json');
const requireBase = fs.existsSync(packageJsonPath) ? packageJsonPath : path.join(absoluteDir, 'index.js');
const requireFromTarget = createRequire(requireBase);

const getVersion = (packageName) => {
  try {
    const resolvedPackageJson = requireFromTarget.resolve(`${packageName}/package.json`);
    return JSON.parse(fs.readFileSync(resolvedPackageJson, 'utf8')).version;
  } catch (error) {
    console.error(`Failed to resolve ${packageName} in ${targetDir}: ${error.message}`);
    process.exit(1);
  }
};

const assertMajor = (packageName, version) => {
  const actualMajor = Number.parseInt(version.split('.')[0], 10);
  if (actualMajor !== expectedMajor) {
    console.error(`${packageName} resolved to ${version} in ${targetDir}, expected major ${expectedMajor}`);
    process.exit(1);
  }
};

const reactVersion = getVersion('react');
const reactDomVersion = getVersion('react-dom');

assertMajor('react', reactVersion);
assertMajor('react-dom', reactDomVersion);

console.log(`React major check passed for ${targetDir}: react=${reactVersion}, react-dom=${reactDomVersion}`);

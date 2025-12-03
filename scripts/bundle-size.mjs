#!/usr/bin/env node
/**
 * Bundle Size Utilities
 *
 * Commands:
 *   set-limits  - Update .size-limit.json with dynamic limits (base + threshold)
 *
 * Usage:
 *   node scripts/bundle-size.mjs set-limits --base <file> [--config <file>] [--threshold <bytes>]
 *
 * Examples:
 *   node scripts/bundle-size.mjs set-limits --base /tmp/base-sizes.json
 */

import fs from 'fs';

// Default threshold: 0.5 KB (512 bytes)
// Intentionally strict to catch any bundle size changes early.
// For intentional size increases, use bin/skip-bundle-size-check to bypass the CI check.
const DEFAULT_THRESHOLD = 512;
// 20% is a big ration, but the current approach is not accurate enough to detect rations less than that
// Later, we will implement performance tests that will use more accurate mechanisms and can detect smaller performance regressions
const DEFAULT_TIME_PERCENTAGE_THRESHOLD = 0.2;
const DEFAULT_CONFIG = '.size-limit.json';

// ANSI color codes
const colors = {
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  reset: '\x1b[0m',
};

/**
 * Format bytes to human-readable string
 */
function formatSize(bytes) {
  if (bytes >= 1024) {
    return `${(bytes / 1024).toFixed(2)} kB`;
  }
  return `${bytes} B`;
}

/**
 * Format time to human-readable string
 */
function formatTime(ms) {
  if (ms >= 1000) {
    return `${(ms / 1000).toFixed(2)} s`;
  }
  return `${ms.toFixed(0)} ms`;
}

/**
 * Parse command line arguments
 */
function parseArgs(args) {
  const parsed = { _: [] };
  for (let i = 0; i < args.length; i += 1) {
    const arg = args[i];
    if (arg.startsWith('--')) {
      const key = arg.slice(2);
      const next = args[i + 1];
      if (next && !next.startsWith('--')) {
        parsed[key] = next;
        i += 1;
      } else {
        parsed[key] = true;
      }
    } else {
      parsed._.push(arg);
    }
  }
  return parsed;
}

/**
 * Read and parse JSON file
 */
function readJsonFile(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  return JSON.parse(content);
}

/**
 * Try to read and parse JSON file, exit on error
 */
// eslint-disable-next-line consistent-return
function readJsonFileOrExit(filePath) {
  try {
    return readJsonFile(filePath);
  } catch (error) {
    console.error(`${colors.red}Error reading ${filePath}: ${error.message}${colors.reset}`);
    process.exit(1);
  }
}

function createLimitEntry(entry, baseEntry, threshold, timePercentageThreshold) {
  const limit = baseEntry.size + threshold;
  console.log(`${entry.name}:`);
  console.log(`  base size: ${formatSize(baseEntry.size)}`);
  console.log(`  limit:     ${formatSize(limit)}\n`);
  const sizeLimitEntry = { ...entry, limit: `${limit} B` };
  if (!baseEntry.running) {
    return sizeLimitEntry;
  }

  const { loading, running } = baseEntry;
  const loadingMs = loading * 1000;
  const runningMs = running * 1000;
  console.log(`  base loading time: ${formatTime(loadingMs)}`);
  console.log(`  base running time: ${formatTime(runningMs)}`);
  const totalTime = loadingMs + runningMs;
  return [
    sizeLimitEntry,
    {
      ...entry,
      name: `${entry.name} (time)`,
      limit: `${(totalTime * (1 + timePercentageThreshold)).toFixed(0)} ms`,
    },
  ];
}

/**
 * Command: set-limits
 * Updates .size-limit.json with dynamic limits based on base sizes
 */
function setLimits(options) {
  const basePath = options.base;
  const configPath = options.config || DEFAULT_CONFIG;
  const threshold = parseInt(options.threshold, 10) || DEFAULT_THRESHOLD;
  const timePercentageThreshold =
    Number(options.timePercentageThreshold) || DEFAULT_TIME_PERCENTAGE_THRESHOLD;

  if (!basePath) {
    console.error(`${colors.red}Error: --base <file> is required${colors.reset}`);
    process.exit(1);
  }

  const baseSizes = readJsonFileOrExit(basePath);
  const config = readJsonFileOrExit(configPath);

  console.log(`${colors.blue}Setting dynamic limits (base + ${formatSize(threshold)}):${colors.reset}\n`);

  const updatedConfig = config
    .map((entry) => {
      const baseEntry = baseSizes.find((b) => b.name === entry.name);
      if (baseEntry) {
        return createLimitEntry(entry, baseEntry, threshold, timePercentageThreshold);
      }
      console.log(
        `${colors.yellow}${entry.name}: No base entry found, keeping original limit${colors.reset}`,
      );
      return entry;
    })
    .flat();

  fs.writeFileSync(configPath, `${JSON.stringify(updatedConfig, null, 2)}\n`);
  console.log(`${colors.green}Updated ${configPath}${colors.reset}`);
}

/**
 * Print usage help
 */
function printHelp() {
  console.log(`
${colors.blue}Bundle Size Utilities${colors.reset}

${colors.yellow}Commands:${colors.reset}
  set-limits    Update .size-limit.json with dynamic limits

${colors.yellow}Usage:${colors.reset}
  node scripts/bundle-size.mjs set-limits --base <file> [options]

${colors.yellow}Options for set-limits:${colors.reset}
  --base <file>       Path to base sizes JSON (required)
  --config <file>     Path to .size-limit.json (default: .size-limit.json)
  --threshold <bytes> Size threshold in bytes (default: 512)
  --timePercentageThreshold <ratio between 0 and 1> Acceptable increase percentage in total time

${colors.yellow}Examples:${colors.reset}
  # Set dynamic limits from base sizes
  node scripts/bundle-size.mjs set-limits --base /tmp/base-sizes.json
`);
}

// Main
const args = parseArgs(process.argv.slice(2));
const command = args._[0];

switch (command) {
  case 'set-limits':
    setLimits(args);
    break;
  case 'help':
  case '--help':
  case '-h':
    printHelp();
    break;
  default:
    if (command) {
      console.error(`${colors.red}Unknown command: ${command}${colors.reset}\n`);
    }
    printHelp();
    process.exit(command ? 1 : 0);
}

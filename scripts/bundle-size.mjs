#!/usr/bin/env node
/**
 * Bundle Size Utilities
 *
 * Commands:
 *   set-limits  - Update .size-limit.json with dynamic limits (base + threshold)
 *   compare     - Compare two size measurements and print a report
 *
 * Usage:
 *   node scripts/bundle-size.mjs set-limits --base <file> [--config <file>] [--threshold <bytes>]
 *   node scripts/bundle-size.mjs compare --base <file> --current <file> [--threshold <bytes>]
 *
 * Examples:
 *   node scripts/bundle-size.mjs set-limits --base /tmp/base-sizes.json
 *   node scripts/bundle-size.mjs compare --base /tmp/base-sizes.json --current /tmp/current-sizes.json
 */

import fs from 'fs';

// Default threshold: 0.5 KB
const DEFAULT_THRESHOLD = 512;
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
 * Format size difference with percentage
 */
function formatDiff(diff, percent) {
  if (diff === 0) return '0%';
  const sign = diff > 0 ? '+' : '';
  return `${sign}${formatSize(Math.abs(diff))} (${sign}${percent.toFixed(2)}%)`;
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

/**
 * Command: set-limits
 * Updates .size-limit.json with dynamic limits based on base sizes
 */
function setLimits(options) {
  const basePath = options.base;
  const configPath = options.config || DEFAULT_CONFIG;
  const threshold = parseInt(options.threshold, 10) || DEFAULT_THRESHOLD;

  if (!basePath) {
    console.error(`${colors.red}Error: --base <file> is required${colors.reset}`);
    process.exit(1);
  }

  const baseSizes = readJsonFileOrExit(basePath);
  const config = readJsonFileOrExit(configPath);

  console.log(`${colors.blue}Setting dynamic limits (base + ${formatSize(threshold)}):${colors.reset}\n`);

  const updatedConfig = config.map((entry) => {
    const baseEntry = baseSizes.find((b) => b.name === entry.name);
    if (baseEntry) {
      const limit = baseEntry.size + threshold;
      console.log(`${entry.name}:`);
      console.log(`  base size: ${formatSize(baseEntry.size)}`);
      console.log(`  limit:     ${formatSize(limit)}\n`);
      return { ...entry, limit: `${limit} B` };
    }
    console.log(`${colors.yellow}${entry.name}: No base entry found, keeping original limit${colors.reset}`);
    return entry;
  });

  fs.writeFileSync(configPath, `${JSON.stringify(updatedConfig, null, 2)}\n`);
  console.log(`${colors.green}Updated ${configPath}${colors.reset}`);
}

/**
 * Get diff color based on threshold
 */
function getDiffColor(diff, threshold) {
  if (diff > threshold) return colors.red;
  if (diff > 0) return colors.yellow;
  return colors.green;
}

/**
 * Print a single result row
 */
function printResultRow(result, maxNameLen, threshold) {
  const status = result.exceeded
    ? `${colors.red}❌ EXCEEDED${colors.reset}`
    : `${colors.green}✅ OK${colors.reset}`;

  const diffColor = getDiffColor(result.diff, threshold);
  const diffStr = `${diffColor}${formatDiff(result.diff, result.percent)}${colors.reset}`;

  const namePart = result.name.padEnd(maxNameLen + 2);
  const basePart = formatSize(result.baseSize).padStart(12);
  const currentPart = formatSize(result.currentSize).padStart(12);
  const diffPart = diffStr.padStart(20 + 9);

  console.log(`${namePart}${basePart}${currentPart}${diffPart}  ${status}`);
}

/**
 * Command: compare
 * Compares two size measurements and prints a report
 */
function compare(options) {
  const basePath = options.base;
  const currentPath = options.current;
  const threshold = parseInt(options.threshold, 10) || DEFAULT_THRESHOLD;
  const json = options.json === true || options.json === 'true';

  if (!basePath || !currentPath) {
    console.error(`${colors.red}Error: --base <file> and --current <file> are required${colors.reset}`);
    process.exit(1);
  }

  const baseSizes = readJsonFileOrExit(basePath);
  const currentSizes = readJsonFileOrExit(currentPath);

  const results = currentSizes.map((current) => {
    const base = baseSizes.find((b) => b.name === current.name) || { size: 0 };
    const diff = current.size - base.size;
    const percent = base.size > 0 ? (diff / base.size) * 100 : 0;
    const exceeded = diff > threshold;

    return {
      name: current.name,
      baseSize: base.size,
      currentSize: current.size,
      diff,
      percent,
      exceeded,
    };
  });

  const hasExceeded = results.some((r) => r.exceeded);

  if (json) {
    // JSON output for programmatic use
    console.log(
      JSON.stringify(
        {
          threshold,
          hasExceeded,
          results: results.map((r) => ({
            name: r.name,
            baseSize: r.baseSize,
            currentSize: r.currentSize,
            diff: r.diff,
            percentChange: r.percent,
            exceeded: r.exceeded,
          })),
        },
        null,
        2,
      ),
    );
  } else {
    // Pretty table output
    const maxNameLen = Math.max(...results.map((r) => r.name.length));
    const separator = '━'.repeat(76);
    const thinSeparator = '─'.repeat(maxNameLen + 2 + 12 + 12 + 20 + 12);

    console.log('');
    console.log(`${colors.blue}${separator}${colors.reset}`);
    console.log(`${colors.blue}Bundle Size Report${colors.reset}`);
    console.log(`${colors.blue}${separator}${colors.reset}`);
    console.log('');

    const header = `${'Package'.padEnd(maxNameLen + 2)}${'Base'.padStart(12)}${'Current'.padStart(
      12,
    )}${'Diff'.padStart(20)}  Status`;
    console.log(header);
    console.log(thinSeparator);

    results.forEach((r) => printResultRow(r, maxNameLen, threshold));

    console.log('');
    console.log(thinSeparator);
    console.log(`Threshold: ${formatSize(threshold)} (base + ${formatSize(threshold)})`);
    console.log('');

    if (hasExceeded) {
      console.log(`${colors.red}❌ Some packages exceeded the size threshold!${colors.reset}`);
    } else {
      console.log(`${colors.green}✅ All packages within threshold.${colors.reset}`);
    }
  }

  if (hasExceeded) {
    process.exit(1);
  }
}

/**
 * Print usage help
 */
function printHelp() {
  console.log(`
${colors.blue}Bundle Size Utilities${colors.reset}

${colors.yellow}Commands:${colors.reset}
  set-limits    Update .size-limit.json with dynamic limits
  compare       Compare two size measurements and print report

${colors.yellow}Usage:${colors.reset}
  node scripts/bundle-size.mjs set-limits --base <file> [options]
  node scripts/bundle-size.mjs compare --base <file> --current <file> [options]

${colors.yellow}Options for set-limits:${colors.reset}
  --base <file>       Path to base sizes JSON (required)
  --config <file>     Path to .size-limit.json (default: .size-limit.json)
  --threshold <bytes> Size threshold in bytes (default: 512)

${colors.yellow}Options for compare:${colors.reset}
  --base <file>       Path to base sizes JSON (required)
  --current <file>    Path to current sizes JSON (required)
  --threshold <bytes> Size threshold in bytes (default: 512)
  --json              Output results as JSON

${colors.yellow}Examples:${colors.reset}
  # Set dynamic limits from base sizes
  node scripts/bundle-size.mjs set-limits --base /tmp/base-sizes.json

  # Compare sizes with custom threshold (1KB)
  node scripts/bundle-size.mjs compare --base base.json --current current.json --threshold 1024

  # Get comparison as JSON
  node scripts/bundle-size.mjs compare --base base.json --current current.json --json
`);
}

// Main
const args = parseArgs(process.argv.slice(2));
const command = args._[0];

switch (command) {
  case 'set-limits':
    setLimits(args);
    break;
  case 'compare':
    compare(args);
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

#!/usr/bin/env node

// Validates that .docs-config.yml matches the actual folder structure.
// Usage: node scripts/validate-docs-config.cjs <docs-directory>
// Example: node scripts/validate-docs-config.cjs docs
//          node scripts/validate-docs-config.cjs react_on_rails_pro/docs

const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');
const micromatch = require('micromatch');

const docsDir = process.argv[2];
if (!docsDir) {
  console.error('Usage: node scripts/validate-docs-config.cjs <docs-directory>');
  process.exit(1);
}

const absDocsDir = path.resolve(docsDir);
const configPath = path.join(absDocsDir, '.docs-config.yml');

if (!fs.existsSync(configPath)) {
  console.error(`ERROR: ${configPath} not found`);
  process.exit(1);
}

let config;
try {
  config = yaml.load(fs.readFileSync(configPath, 'utf8'));
} catch (e) {
  console.error(`ERROR: Failed to parse ${configPath}: ${e.message}`);
  process.exit(1);
}
const errors = [];
const warnings = [];

// --- Schema validation ---

if (!config || typeof config !== 'object') {
  console.error('ERROR: .docs-config.yml must be a YAML object');
  process.exit(1);
}

if (!Array.isArray(config.exclude)) {
  errors.push('Missing or invalid "exclude" (must be an array)');
}

if (!Array.isArray(config.categoryOrder)) {
  errors.push('Missing or invalid "categoryOrder" (must be an array)');
}

if (config.fileOrder === undefined || config.fileOrder === null) {
  config.fileOrder = {};
} else if (typeof config.fileOrder !== 'object' || Array.isArray(config.fileOrder)) {
  errors.push('Invalid "fileOrder" (must be an object, not an array)');
}

if (errors.length > 0) {
  errors.forEach((e) => { console.error(`ERROR: ${e}`); });
  process.exit(1);
}

const { exclude, categoryOrder, fileOrder } = config;

// --- Check for duplicates ---

const categoryDups = categoryOrder.filter((c, i) => categoryOrder.indexOf(c) !== i);
if (categoryDups.length > 0) {
  errors.push(`Duplicate entries in categoryOrder: ${[...new Set(categoryDups)].join(', ')}`);
}

for (const [folderKey, files] of Object.entries(fileOrder)) {
  if (Array.isArray(files)) {
    const fileDups = files.filter((f, i) => files.indexOf(f) !== i);
    if (fileDups.length > 0) {
      errors.push(`Duplicate entries in fileOrder.${folderKey}: ${[...new Set(fileDups)].join(', ')}`);
    }
  }
}

// --- Helper: check if a relative path is excluded ---

/** Returns true if relativePath matches any pattern in the exclude list. */
function isExcluded(relativePath) {
  return micromatch.isMatch(relativePath, exclude);
}

// --- Helper: recursively check for doc files ---

/** Recursively checks whether dirPath contains any .md/.mdx files. Skips symlinks. */
function hasDocFiles(dirPath) {
  const entries = fs.readdirSync(dirPath, { withFileTypes: true });
  for (const entry of entries) {
    if (!entry.isSymbolicLink()) {
      if (entry.isFile() && /\.(md|mdx)$/i.test(entry.name)) return true;
      if (entry.isDirectory()) {
        if (hasDocFiles(path.join(dirPath, entry.name))) return true;
      }
    }
  }
  return false;
}

// --- Helper: list first-level directories with doc files ---

/** Returns names of top-level directories under absDocsDir that contain .md/.mdx files. */
function getDocDirectories() {
  const entries = fs.readdirSync(absDocsDir, { withFileTypes: true });
  const dirs = [];

  for (const entry of entries) {
    if (entry.isDirectory() && !entry.name.startsWith('.')) {
      // Check if this directory (or any subdirectory) contains .md/.mdx files
      if (hasDocFiles(path.join(absDocsDir, entry.name))) {
        dirs.push(entry.name);
      }
    }
  }

  return dirs;
}

// --- Helper: list doc files in a directory (non-recursive) ---

/**
 * Returns doc files in dirPath as objects with stem (name without extension)
 * and filename (original name with extension) to allow precise exclusion checks.
 */
function getDocFiles(dirPath) {
  if (!fs.existsSync(dirPath)) return [];
  return fs
    .readdirSync(dirPath, { withFileTypes: true })
    .filter((e) => e.isFile() && /\.(md|mdx)$/i.test(e.name))
    .map((e) => ({ stem: e.name.replace(/\.(md|mdx)$/i, ''), filename: e.name }));
}

// --- Helper: recursively list all relative paths ---

/** Recursively lists all relative paths under baseDir. Skips dotfiles and symlinks. */
function listAllRelativePaths(baseDir, prefix = '') {
  const results = [];
  const entries = fs.readdirSync(baseDir, { withFileTypes: true });
  for (const entry of entries) {
    if (!entry.name.startsWith('.') && !entry.isSymbolicLink()) {
      const rel = prefix ? `${prefix}/${entry.name}` : entry.name;
      results.push(rel);
      if (entry.isDirectory()) {
        results.push(...listAllRelativePaths(path.join(baseDir, entry.name), rel));
      }
    }
  }
  return results;
}

// --- Check 1: Category completeness ---

const allDirs = getDocDirectories();
const categoryFolders = categoryOrder.filter((c) => c !== '');

for (const dir of allDirs) {
  // Check if entire directory is excluded (bare name, trailing slash, or glob)
  if (!isExcluded(dir) && !isExcluded(`${dir}/`) && !isExcluded(`${dir}/**`)) {
    // Check if all doc files in this directory are individually excluded
    const dirFiles = getDocFiles(path.join(absDocsDir, dir));
    const nonExcludedFiles = dirFiles.filter((f) => !isExcluded(`${dir}/${f.filename}`));
    if (nonExcludedFiles.length > 0 && !categoryFolders.includes(dir)) {
      errors.push(
        `Directory "${dir}" has docs but is not in categoryOrder or exclude.\n` +
          `       Add it to categoryOrder or exclude in ${docsDir}/.docs-config.yml`,
      );
    }
  }
}

// --- Check 2: Stale categories ---

for (const folder of categoryFolders) {
  const dirPath = path.join(absDocsDir, folder);
  if (!fs.existsSync(dirPath) || !fs.statSync(dirPath).isDirectory()) {
    warnings.push(`Category "${folder}" in categoryOrder does not exist as a directory`);
  }
}

// --- Check 3: File existence in fileOrder ---

for (const [folderKey, files] of Object.entries(fileOrder)) {
  if (!Array.isArray(files)) {
    errors.push(`fileOrder.${folderKey} must be an array`);
  } else {
    for (const fileName of files) {
      const inFolderMd = path.join(absDocsDir, folderKey, `${fileName}.md`);
      const inFolderMdx = path.join(absDocsDir, folderKey, `${fileName}.mdx`);
      const existsInFolder = fs.existsSync(inFolderMd) || fs.existsSync(inFolderMdx);

      if (!existsInFolder) {
        // Root-level files can be listed under a category
        // (e.g., introduction.md is at root but appears under getting-started)
        const atRootMd = path.join(absDocsDir, `${fileName}.md`);
        const atRootMdx = path.join(absDocsDir, `${fileName}.mdx`);
        const existsAtRoot = fs.existsSync(atRootMd) || fs.existsSync(atRootMdx);

        if (existsAtRoot) {
          warnings.push(
            `File "${fileName}" in fileOrder.${folderKey} exists at root, not in ${folderKey}/. ` +
              `Verify this is intentional (e.g., a cross-category mapping).`,
          );
        } else {
          errors.push(`File "${fileName}" in fileOrder.${folderKey} does not exist`);
        }
      }
    }
  }
}

// --- Check 4: Stale exclusions ---

const allEntries = listAllRelativePaths(absDocsDir);
for (const pattern of exclude) {
  const matches = micromatch(allEntries, [pattern]);
  if (matches.length === 0) {
    warnings.push(`Exclusion "${pattern}" matches no files`);
  }
}

// --- Check 5: Root-level doc files ---
// Root-level .md files should either be in the "" category implicitly
// or be excluded. Warn if a root-level file exists but is not excluded
// and "" is not in categoryOrder.

if (!categoryOrder.includes('')) {
  const rootFiles = getDocFiles(absDocsDir);
  const nonExcludedRootFiles = rootFiles.filter((f) => !isExcluded(f.filename));
  if (nonExcludedRootFiles.length > 0) {
    errors.push(
      `Root-level doc files exist (${nonExcludedRootFiles.map((f) => f.stem).join(', ')}) but "" is not in categoryOrder.\n` +
        `       Add "" to categoryOrder to display root-level files.`,
    );
  }
}

// --- Output ---

if (warnings.length > 0) {
  warnings.forEach((w) => { console.warn(`WARNING: ${w}`); });
}

if (errors.length > 0) {
  console.error('');
  errors.forEach((e) => { console.error(`ERROR: ${e}`); });
  console.error(`\n${errors.length} error(s) found in ${docsDir}/.docs-config.yml`);
  process.exit(1);
}

console.log(
  `✓ ${docsDir}/.docs-config.yml is valid (${categoryFolders.length} categories, ${Object.keys(fileOrder).length} file orderings, ${exclude.length} exclusions)`,
);

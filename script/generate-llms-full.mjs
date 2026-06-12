#!/usr/bin/env node
/**
 * Generates llms-full.txt: the curated preamble (docs/llms-full-preamble.md)
 * followed by the full content of every published doc under docs/oss and
 * docs/pro, in sidebar order, with canonical reactonrails.com URLs.
 *
 * Also validates that every reactonrails.com/docs URL referenced from
 * llms.txt and the preamble resolves to a published doc or docs directory,
 * and that llms.txt represents every sidebar top-level section.
 *
 * Usage:
 *   node script/generate-llms-full.mjs           # regenerate llms-full.txt
 *   node script/generate-llms-full.mjs --check   # CI mode: fail on drift
 *
 * Doc ID rules mirror script/check-docs-sidebar:
 *   docs/oss/getting-started/quick-start.md → getting-started/quick-start
 *   docs/pro/installation.md                → pro/installation
 * URL rules (Docusaurus conventions; see llms.txt for examples):
 *   <id>                                    → https://reactonrails.com/docs/<id>
 *   <dir>/index, <dir>/README               → https://reactonrails.com/docs/<dir>
 *   front-matter `slug: <name>` (relative)  → replaces the last path segment
 *   front-matter `slug: /<path>` (absolute) → replaces the whole path
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const DOCS_DIR = path.join(ROOT, 'docs');
const PREAMBLE_FILE = path.join(DOCS_DIR, 'llms-full-preamble.md');
const EXCLUSIONS_FILE = path.join(DOCS_DIR, '.llms-exclusions');
const KNOWN_REDIRECTS_FILE = path.join(DOCS_DIR, '.llms-known-redirects');
const SIDEBARS_FILE = path.join(DOCS_DIR, 'sidebars.ts');
const LLMS_FILE = path.join(ROOT, 'llms.txt');
const OUTPUT_FILE = path.join(ROOT, 'llms-full.txt');
const SITE_DOCS_URL = 'https://reactonrails.com/docs';
const SPLIT_THRESHOLD_KIB = 2048;

const checkMode = process.argv.includes('--check');

function fail(message) {
  console.error(`✗ ${message}`);
  process.exitCode = 1;
}

function walkMarkdownFiles(dir) {
  const results = [];
  for (const entry of fs
    .readdirSync(dir, { withFileTypes: true })
    .sort((a, b) => a.name.localeCompare(b.name))) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      results.push(...walkMarkdownFiles(fullPath));
    } else if (/\.(md|mdx)$/.test(entry.name)) {
      results.push(fullPath);
    }
  }
  return results;
}

function docIdForFile(relPath) {
  // relPath is relative to docs/, e.g. oss/getting-started/quick-start.md
  const withoutExt = relPath.replace(/\.(md|mdx)$/, '');
  return withoutExt.startsWith('oss/') ? withoutExt.slice('oss/'.length) : withoutExt;
}

// Split optional YAML front matter off a doc body; only `slug:` is read.
// CRLF-tolerant in case a checkout bypasses the repo's LF normalization.
function splitFrontMatter(content) {
  const match = content.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n/);
  if (!match) return { slug: undefined, body: content };
  const slugMatch = match[1].match(/^slug:\s*(\S+)\s*$/m);
  return { slug: slugMatch ? slugMatch[1] : undefined, body: content.slice(match[0].length) };
}

function urlPathForDoc(docId, slug) {
  if (slug) {
    if (slug.startsWith('/')) return slug.replace(/^\/+/, '');
    const dir = path.posix.dirname(docId);
    return dir === '.' ? slug : `${dir}/${slug}`;
  }
  return docId.replace(/\/(index|README)$/, '');
}

function urlForDoc(docId, slug) {
  const base = urlPathForDoc(docId, slug);
  return base === '' ? `${SITE_DOCS_URL}/` : `${SITE_DOCS_URL}/${base}`;
}

function loadIdList(file) {
  if (!fs.existsSync(file)) return new Set();
  const ids = fs
    .readFileSync(file, 'utf8')
    .split('\n')
    .map((line) => line.replace(/#.*$/, '').trim())
    .filter(Boolean);
  return new Set(ids);
}

function stripSidebarsComments(content) {
  return content
    .split('\n')
    .filter((line) => !/^\s*\/\//.test(line))
    .map((line) => line.replace(/\s\/\/.*$/, ''))
    .join('\n');
}

function collectDocs() {
  const exclusions = loadIdList(EXCLUSIONS_FILE);
  const docs = new Map(); // docId → { relPath, content }
  for (const subdir of ['oss', 'pro']) {
    for (const file of walkMarkdownFiles(path.join(DOCS_DIR, subdir))) {
      const relPath = path.relative(DOCS_DIR, file);
      const docId = docIdForFile(relPath);
      if (!exclusions.has(docId)) {
        const { slug, body } = splitFrontMatter(fs.readFileSync(file, 'utf8'));
        docs.set(docId, { relPath: `docs/${relPath}`, slug, content: body });
      }
    }
  }
  return docs;
}

function sidebarOrderedIds(docs) {
  // Mirror script/check-docs-sidebar: strip full-line and inline `//` comments,
  // then read quoted strings in order of appearance.
  const content = stripSidebarsComments(fs.readFileSync(SIDEBARS_FILE, 'utf8'));
  const ordered = [];
  const seen = new Set();
  for (const match of content.matchAll(/'([^'\n]+)'|"([^"\n]+)"/g)) {
    const candidate = match[1] ?? match[2];
    if (docs.has(candidate) && !seen.has(candidate)) {
      seen.add(candidate);
      ordered.push(candidate);
    }
  }
  const rest = [...docs.keys()].filter((id) => !seen.has(id)).sort();
  return [...ordered, ...rest];
}

function matchingDelimiterIndex(content, openIndex, openChar, closeChar) {
  let depth = 0;
  let quote;
  let escaped = false;

  for (let index = openIndex; index < content.length; index += 1) {
    const char = content[index];
    if (quote) {
      if (escaped) {
        escaped = false;
      } else if (char === '\\') {
        escaped = true;
      } else if (char === quote) {
        quote = undefined;
      }
      continue;
    }

    if (char === "'" || char === '"' || char === '`') {
      quote = char;
    } else if (char === openChar) {
      depth += 1;
    } else if (char === closeChar) {
      depth -= 1;
      if (depth === 0) return index;
    }
  }

  throw new Error(`Could not find matching ${closeChar} in ${path.relative(ROOT, SIDEBARS_FILE)}`);
}

function docsSidebarArrayBody() {
  const content = stripSidebarsComments(fs.readFileSync(SIDEBARS_FILE, 'utf8'));
  const docsSidebarIndex = content.indexOf('docsSidebar');
  if (docsSidebarIndex === -1) {
    throw new Error(`Could not find docsSidebar in ${path.relative(ROOT, SIDEBARS_FILE)}`);
  }
  const openIndex = content.indexOf('[', docsSidebarIndex);
  if (openIndex === -1) {
    throw new Error(`Could not find docsSidebar array in ${path.relative(ROOT, SIDEBARS_FILE)}`);
  }
  const closeIndex = matchingDelimiterIndex(content, openIndex, '[', ']');
  return content.slice(openIndex + 1, closeIndex);
}

function splitTopLevelSidebarEntries(arrayBody) {
  const entries = [];
  let start = 0;
  let depth = 0;
  let quote;
  let escaped = false;

  for (let index = 0; index < arrayBody.length; index += 1) {
    const char = arrayBody[index];
    if (quote) {
      if (escaped) {
        escaped = false;
      } else if (char === '\\') {
        escaped = true;
      } else if (char === quote) {
        quote = undefined;
      }
      continue;
    }

    if (char === "'" || char === '"' || char === '`') {
      quote = char;
    } else if (char === '{' || char === '[' || char === '(') {
      depth += 1;
    } else if (char === '}' || char === ']' || char === ')') {
      depth -= 1;
    } else if (char === ',' && depth === 0) {
      entries.push(arrayBody.slice(start, index).trim());
      start = index + 1;
    }
  }

  const lastEntry = arrayBody.slice(start).trim();
  if (lastEntry) entries.push(lastEntry);
  return entries;
}

function quotedStrings(content) {
  return [...content.matchAll(/'([^'\n]+)'|"([^"\n]+)"/g)].map((match) => match[1] ?? match[2]);
}

function sidebarTopLevelSections(docs) {
  return splitTopLevelSidebarEntries(docsSidebarArrayBody())
    .map((entry) => {
      const docIds = [];
      const seen = new Set();
      for (const candidate of quotedStrings(entry)) {
        if (docs.has(candidate) && !seen.has(candidate)) {
          seen.add(candidate);
          docIds.push(candidate);
        }
      }
      if (docIds.length === 0) return undefined;

      const labelMatch = entry.match(/\blabel\s*:\s*(['"])(.*?)\1/);
      const directDocId = entry.match(/^\s*(['"])(.*?)\1\s*$/)?.[2];
      return { label: labelMatch?.[2] ?? directDocId ?? docIds[0], docIds };
    })
    .filter(Boolean);
}

function generate(docs, orderedIds) {
  const preamble = fs.readFileSync(PREAMBLE_FILE, 'utf8').trimEnd();
  const parts = [
    '<!-- GENERATED FILE — DO NOT EDIT DIRECTLY. -->',
    '<!-- Regenerate with: node script/generate-llms-full.mjs -->',
    '<!-- Sources: docs/llms-full-preamble.md plus the published docs under docs/oss and docs/pro. -->',
    '',
    preamble,
    '',
    '',
    '# Full documentation content',
    '',
    'Every published documentation page follows, in sidebar order. Each page begins',
    'with a `PAGE:` line holding its canonical URL and a `SOURCE:` line holding its',
    'repository path.',
    '',
  ];
  for (const docId of orderedIds) {
    const { relPath, slug, content } = docs.get(docId);
    parts.push(
      '================================================================================',
      `PAGE: ${urlForDoc(docId, slug)}`,
      `SOURCE: ${relPath}`,
      '================================================================================',
      '',
      content.trim(),
      '',
    );
  }
  return `${parts.join('\n')}\n`;
}

function validateDocUrls(docs) {
  const urlPattern = /https:\/\/reactonrails\.com\/docs[^\s)\]'"`>]*/g;
  // Only the published route counts: a slugged doc's file-path route and a
  // README/index file's literal path are not live URLs and must not validate.
  // Intentional references to redirect URLs go in docs/.llms-known-redirects.
  const resolvableIds = loadIdList(KNOWN_REDIRECTS_FILE);
  for (const [docId, { slug }] of docs.entries()) {
    resolvableIds.add(urlPathForDoc(docId, slug));
  }
  // Category/hub URLs resolve to a docs DIRECTORY (generated index pages);
  // plain files under docs/ (configs, this script's inputs) must not count.
  const isDocsDirectory = (candidate) => {
    try {
      return fs.statSync(candidate).isDirectory();
    } catch {
      return false;
    }
  };
  const resolves = (docPath) =>
    docPath === '' ||
    resolvableIds.has(docPath) ||
    isDocsDirectory(path.join(DOCS_DIR, 'oss', docPath)) ||
    isDocsDirectory(path.join(DOCS_DIR, docPath));

  let validated = 0;
  for (const file of [LLMS_FILE, PREAMBLE_FILE]) {
    const text = fs.readFileSync(file, 'utf8');
    for (const match of text.matchAll(urlPattern)) {
      const url = match[0].replace(/[.,;:]+$/, '');
      // Anchors are stripped: validation is page-level only. Anchor-level
      // checking would need heading extraction across all docs — if a linked
      // section heading is renamed, this check will not catch it.
      const docPath = url
        .slice(SITE_DOCS_URL.length)
        .replace(/^\//, '')
        .replace(/#.*$/, '')
        .replace(/\/$/, '');
      validated += 1;
      if (!resolves(docPath)) {
        fail(
          `${path.relative(ROOT, file)} references ${url}, which does not match any published doc or docs directory`,
        );
      }
    }
  }
  return validated;
}

function docsUrlsFromFile(file) {
  const urlPattern = /https:\/\/reactonrails\.com\/docs[^\s)\]'"`>]*/g;
  const text = fs.readFileSync(file, 'utf8');
  return [...text.matchAll(urlPattern)].map((match) => {
    const url = match[0].replace(/[.,;:]+$/, '');
    const docPath = url.slice(SITE_DOCS_URL.length).replace(/^\//, '').replace(/#.*$/, '').replace(/\/$/, '');
    return { url, docPath };
  });
}

function validateSidebarTopLevelSections(docs) {
  const llmsDocPaths = new Set(docsUrlsFromFile(LLMS_FILE).map(({ docPath }) => docPath));
  const sections = sidebarTopLevelSections(docs);

  for (const { label, docIds } of sections) {
    const sectionDocPaths = docIds.map((docId) => {
      const { slug } = docs.get(docId);
      return urlPathForDoc(docId, slug);
    });
    const representativePaths = new Set(sectionDocPaths);
    const firstSegments = sectionDocPaths.map((docPath) => docPath.split('/')[0]).filter(Boolean);
    if (firstSegments.length > 0 && firstSegments.every((segment) => segment === firstSegments[0])) {
      representativePaths.add(firstSegments[0]);
    }

    if (![...representativePaths].some((docPath) => llmsDocPaths.has(docPath))) {
      fail(
        `llms.txt does not represent sidebar top-level section "${label}". ` +
          `Add at least one reactonrails.com/docs URL for one of: ${sectionDocPaths.slice(0, 5).join(', ')}`,
      );
    }
  }

  return sections.length;
}

function validateSplitThreshold(output) {
  const outputSizeKib = Buffer.byteLength(output) / 1024;
  if (outputSizeKib > SPLIT_THRESHOLD_KIB) {
    fail(
      `llms-full.txt is ${outputSizeKib.toFixed(0)} KiB, above the ${SPLIT_THRESHOLD_KIB} KiB split threshold. ` +
        'Split the generated reference into OSS and Pro files before shipping this size.',
    );
  }
  return outputSizeKib;
}

const docs = collectDocs();
const orderedIds = sidebarOrderedIds(docs);
const output = generate(docs, orderedIds);
const validatedUrlCount = validateDocUrls(docs);
const validatedSidebarSectionCount = validateSidebarTopLevelSections(docs);
const outputSizeKib = validateSplitThreshold(output);

if (checkMode) {
  const existing = fs.existsSync(OUTPUT_FILE) ? fs.readFileSync(OUTPUT_FILE, 'utf8') : '';
  if (existing !== output) {
    fail('llms-full.txt is stale. Run `node script/generate-llms-full.mjs` and commit the result.');
  }
} else if (process.exitCode === 1) {
  console.error('✗ Not writing llms-full.txt while URL validation is failing; fix the URLs above first.');
} else {
  fs.writeFileSync(OUTPUT_FILE, output);
}

if (process.exitCode !== 1) {
  console.log(
    `✓ llms-full.txt ${checkMode ? 'is current' : 'generated'}: ${orderedIds.length} pages, ` +
      `${outputSizeKib.toFixed(0)} KiB ` +
      `(split threshold ${SPLIT_THRESHOLD_KIB} KiB); ${validatedUrlCount} docs URLs and ` +
      `${validatedSidebarSectionCount} sidebar top-level sections validated.`,
  );
}

const fs = require('fs');
const path = require('path');
const { config } = require('shakapacker');

const DEFAULT_CLIENT_REFERENCES = [
  { directory: './client/app', recursive: true, include: /\.(js|ts|jsx|tsx)$/ },
];

// Resolve relative to process.cwd() (the Rails root at webpack build time), matching the
// generated template's `resolve('ssr-generated/rsc-client-references.json')` convention rather
// than coupling to this file's location in the tree.
const DEFAULT_REFERENCES_JSON = path.resolve('ssr-generated/rsc-client-references.json');
const SERVER_COMPONENT_REGISTRATION_ENTRY = path.resolve(
  config.source_path,
  config.source_entry_path,
  '../generated/server-component-registration-entry.js',
);

function readManifestReferences(refsJson) {
  const payload = JSON.parse(fs.readFileSync(refsJson, 'utf8'));
  if (!Array.isArray(payload.refs)) {
    throw new Error(`Expected ${refsJson} to contain a refs array`);
  }

  return payload.refs;
}

function rscManifestClientReferences() {
  const configuredRefsJson = process.env.RSC_MANIFEST_CLIENT_REFERENCES_JSON;
  if (configuredRefsJson) {
    return readManifestReferences(path.resolve(configuredRefsJson));
  }

  if (fs.existsSync(DEFAULT_REFERENCES_JSON)) {
    return readManifestReferences(DEFAULT_REFERENCES_JSON);
  }

  if (process.env.RSC_REFERENCE_DISCOVERY_BUILD === 'true' || process.env.RSC_BUNDLE_ONLY === 'true') {
    return DEFAULT_CLIENT_REFERENCES;
  }

  if (fs.existsSync(SERVER_COMPONENT_REGISTRATION_ENTRY)) {
    throw new Error(
      `Missing ${DEFAULT_REFERENCES_JSON}. Run bin/shakapacker-precompile-hook before bin/shakapacker.`,
    );
  }

  return DEFAULT_CLIENT_REFERENCES;
}

module.exports = rscManifestClientReferences;

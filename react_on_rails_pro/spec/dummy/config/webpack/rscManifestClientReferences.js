const fs = require('fs');
const path = require('path');
const { config } = require('shakapacker');

// Resolves the RSC client-reference manifest for the client and server webpack builds.
//
// This intentionally mirrors the resolution contract the react_on_rails RSC setup generator emits
// inline (`rsc_client_references_js` in
// react_on_rails/lib/generators/react_on_rails/rsc_setup/client_references.rb). The shared contract
// that must stay in sync on both sides:
//   - override env var:   RSC_MANIFEST_CLIENT_REFERENCES_JSON
//   - default manifest:   ssr-generated/rsc-client-references.json (resolved against the Rails root)
//   - manifest shape:     { refs: [...] }, else throw "... to contain a refs array"
//   - fallback ordering:  configured JSON -> default JSON -> (discovery/bundle-only build -> broad
//     fallback) -> (registration entry present -> throw the precompile-hook hint) -> broad fallback
//   - precompile hint:    "Run bin/shakapacker-precompile-hook before bin/shakapacker."
// Both sides are pinned by contract tests so drift on either side fails CI: this resolver by the
// dummy-root tests/rsc-manifest-client-references.test.js (run by the Pro `package-js-tests` CI
// job), and the generator by react_on_rails/spec/react_on_rails/generators/rsc_generator_spec.rb.
// The fallback `directory`/`include` below is intentionally app-specific.
const DEFAULT_CLIENT_REFERENCES = [
  { directory: './client/app', recursive: true, include: /\.(js|mjs|cjs|ts|mts|cts|jsx|tsx)$/ },
];

// cwd-relative (the Rails root at webpack build time), matching the generated template's
// `resolve('ssr-generated/rsc-client-references.json')` rather than coupling to this file's location.
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

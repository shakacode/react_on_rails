// Contract test for config/webpack/rscManifestClientReferences.js.
//
// This pins the dummy's RSC manifest resolution behavior so it cannot silently drift from the
// contract that react_on_rails's RSC setup generator emits inline (`rsc_client_references_js` in
// react_on_rails/lib/generators/react_on_rails/rsc_setup/client_references.rb), which is pinned on
// the generator side by spec/react_on_rails/generators/rsc_generator_spec.rb. If the override env
// var, default manifest path, manifest shape, fallback ordering, or error messages change here,
// these tests fail.
const path = require('path');

jest.mock('shakapacker', () => ({
  config: { source_path: 'client', source_entry_path: 'packs' },
}));

jest.mock('fs', () => {
  const actual = jest.requireActual('fs');
  return { ...actual, existsSync: jest.fn(), readFileSync: jest.fn() };
});

const fs = require('fs');
const rscManifestClientReferences = require('../config/webpack/rscManifestClientReferences');

const DEFAULT_MANIFEST = path.resolve('ssr-generated/rsc-client-references.json');
const REGISTRATION_ENTRY = path.resolve(
  'client',
  'packs',
  '../generated/server-component-registration-entry.js',
);

describe('rscManifestClientReferences (Pro dummy) mirrors the generator resolution contract', () => {
  const originalEnv = process.env;

  beforeEach(() => {
    process.env = { ...originalEnv };
    delete process.env.RSC_MANIFEST_CLIENT_REFERENCES_JSON;
    delete process.env.RSC_REFERENCE_DISCOVERY_BUILD;
    delete process.env.RSC_BUNDLE_ONLY;
    fs.existsSync.mockReset();
    fs.readFileSync.mockReset();
  });

  afterAll(() => {
    process.env = originalEnv;
  });

  it('reads the RSC_MANIFEST_CLIENT_REFERENCES_JSON override when set', () => {
    process.env.RSC_MANIFEST_CLIENT_REFERENCES_JSON = 'tmp/custom-refs.json';
    fs.readFileSync.mockReturnValue(JSON.stringify({ refs: ['client/app/A.jsx'] }));

    expect(rscManifestClientReferences()).toEqual(['client/app/A.jsx']);
    expect(fs.readFileSync).toHaveBeenCalledWith(path.resolve('tmp/custom-refs.json'), 'utf8');
  });

  it('prefers the default discovered manifest when it exists', () => {
    fs.existsSync.mockImplementation((p) => p === DEFAULT_MANIFEST);
    fs.readFileSync.mockReturnValue(JSON.stringify({ refs: ['client/app/B.jsx', 'client/app/C.jsx'] }));

    expect(rscManifestClientReferences()).toEqual(['client/app/B.jsx', 'client/app/C.jsx']);
    expect(fs.readFileSync).toHaveBeenCalledWith(DEFAULT_MANIFEST, 'utf8');
  });

  it('throws when the manifest payload has no refs array', () => {
    fs.existsSync.mockImplementation((p) => p === DEFAULT_MANIFEST);
    fs.readFileSync.mockReturnValue(JSON.stringify({ notRefs: true }));

    expect(() => rscManifestClientReferences()).toThrow(/to contain a refs array/);
  });

  it('falls back to a broad scan during a discovery build with no manifest', () => {
    process.env.RSC_REFERENCE_DISCOVERY_BUILD = 'true';
    fs.existsSync.mockReturnValue(false);

    const refs = rscManifestClientReferences();
    expect(Array.isArray(refs)).toBe(true);
    expect(refs[0]).toMatchObject({ directory: './client/app', recursive: true });
    // Locks the include extensions in lockstep with the generator template.
    expect(refs[0].include.test('Foo.mjs')).toBe(true);
    expect(refs[0].include.test('Foo.cts')).toBe(true);
  });

  it('falls back to a broad scan during a bundle-only build with no manifest', () => {
    process.env.RSC_BUNDLE_ONLY = 'true';
    fs.existsSync.mockReturnValue(false);

    const refs = rscManifestClientReferences();
    expect(Array.isArray(refs)).toBe(true);
    expect(refs[0]).toMatchObject({ directory: './client/app', recursive: true });
  });

  it('lets a missing configured override file throw loudly rather than silently falling back', () => {
    process.env.RSC_MANIFEST_CLIENT_REFERENCES_JSON = 'tmp/does-not-exist.json';
    fs.readFileSync.mockImplementation(() => {
      throw Object.assign(new Error('ENOENT: no such file or directory'), { code: 'ENOENT' });
    });

    expect(() => rscManifestClientReferences()).toThrow(/ENOENT/);
  });

  it('throws the precompile-hook hint when the registration entry exists but the manifest is missing', () => {
    fs.existsSync.mockImplementation((p) => p === REGISTRATION_ENTRY);

    expect(() => rscManifestClientReferences()).toThrow(
      /Run bin\/shakapacker-precompile-hook before bin\/shakapacker/,
    );
  });

  it('falls back to a broad scan when neither manifest nor registration entry exists', () => {
    fs.existsSync.mockReturnValue(false);

    const refs = rscManifestClientReferences();
    expect(Array.isArray(refs)).toBe(true);
    expect(refs[0]).toMatchObject({ directory: './client/app', recursive: true });
  });
});

// Contract test for config/webpack/rscManifestClientReferences.js.
//
// This pins the dummy's RSC manifest resolution behavior so it cannot silently drift from the
// contract that react_on_rails's RSC setup generator emits inline (`rsc_client_references_js` in
// react_on_rails/lib/generators/react_on_rails/rsc_setup/client_references.rb), which is pinned on
// the generator side by spec/react_on_rails/generators/rsc_generator_spec.rb. If the override env
// var, default manifest path, manifest shape, fallback ordering, discovery-compatibility fallback,
// or error messages change here, these tests fail.
const path = require('path');

jest.mock('shakapacker', () => ({
  config: { source_path: 'client', source_entry_path: 'packs' },
}));

jest.mock('fs', () => {
  const actual = jest.requireActual('fs');
  return { ...actual, existsSync: jest.fn(), readFileSync: jest.fn(), statSync: jest.fn() };
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
    fs.statSync.mockReset();
  });

  afterAll(() => {
    process.env = originalEnv;
  });

  it('reads the RSC_MANIFEST_CLIENT_REFERENCES_JSON override when set', () => {
    process.env.RSC_MANIFEST_CLIENT_REFERENCES_JSON = 'tmp/custom-refs.json';
    fs.existsSync.mockReturnValue(true);
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

  it('throws with the manifest path when the manifest JSON is malformed', () => {
    fs.existsSync.mockImplementation((p) => p === DEFAULT_MANIFEST);
    fs.readFileSync.mockReturnValue('{ not valid json');

    expect(() => rscManifestClientReferences()).toThrow(/Failed to parse RSC client references manifest/);
  });

  it('falls back to a broad scan during a discovery build with no manifest', () => {
    process.env.RSC_REFERENCE_DISCOVERY_BUILD = 'true';
    fs.existsSync.mockReturnValue(false);

    const refs = rscManifestClientReferences();
    expect(Array.isArray(refs)).toBe(true);
    expect(refs[0]).toMatchObject({ directory: './client/app', recursive: true });
    // Locks the include extensions byte-for-byte in lockstep with the generator template's
    // `fallbackRscClientReferences` (asserted on the generator side in rsc_generator_spec.rb).
    expect(refs[0].include.source).toBe('\\.(js|mjs|cjs|ts|mts|cts|jsx|tsx)$');
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

  it('throws a clear error when the configured override file does not exist', () => {
    process.env.RSC_MANIFEST_CLIENT_REFERENCES_JSON = 'tmp/does-not-exist.json';
    fs.existsSync.mockReturnValue(false);

    expect(() => rscManifestClientReferences()).toThrow(
      /RSC_MANIFEST_CLIENT_REFERENCES_JSON is set but the file does not exist/,
    );
  });

  it('throws the precompile-hook hint when the registration entry exists but the manifest is missing', () => {
    fs.existsSync.mockImplementation(
      (p) =>
        p === REGISTRATION_ENTRY ||
        p === path.resolve('config/webpack/rscWebpackConfig.js') ||
        p === path.resolve('bin/shakapacker-precompile-hook'),
    );
    fs.readFileSync.mockImplementation((p) => {
      if (p === path.resolve('config/webpack/rscWebpackConfig.js')) {
        return 'process.env.RSC_REFERENCE_DISCOVERY_BUILD; RSCReferenceDiscoveryPlugin';
      }
      if (p === path.resolve('bin/shakapacker-precompile-hook')) {
        return 'generate_rsc_manifest_client_references_if_needed RSC_REFERENCE_DISCOVERY_BUILD';
      }
      return '';
    });

    expect(() => rscManifestClientReferences()).toThrow(
      /Run bin\/shakapacker-precompile-hook before bin\/shakapacker/,
    );
  });

  it('falls back with a warning when existing RSC configs cannot produce the discovery manifest', () => {
    fs.existsSync.mockImplementation((p) => p === REGISTRATION_ENTRY);
    const warnSpy = jest.spyOn(console, 'warn').mockImplementation(() => {});

    try {
      const refs = rscManifestClientReferences();
      expect(Array.isArray(refs)).toBe(true);
      expect(refs[0]).toMatchObject({ directory: './client/app', recursive: true });
      expect(warnSpy).toHaveBeenCalledWith(
        expect.stringMatching(/falling back to broad client reference scan/),
      );
    } finally {
      warnSpy.mockRestore();
    }
  });

  it('falls back to a broad scan when neither manifest nor registration entry exists', () => {
    fs.existsSync.mockReturnValue(false);

    const refs = rscManifestClientReferences();
    expect(Array.isArray(refs)).toBe(true);
    expect(refs[0]).toMatchObject({ directory: './client/app', recursive: true });
  });

  it('warns (but still uses the manifest) when it is older than the registration entry', () => {
    fs.existsSync.mockImplementation((p) => p === DEFAULT_MANIFEST || p === REGISTRATION_ENTRY);
    fs.readFileSync.mockReturnValue(JSON.stringify({ refs: ['client/app/A.jsx'] }));
    fs.statSync.mockImplementation((p) => ({ mtimeMs: p === REGISTRATION_ENTRY ? 2000 : 1000 }));
    const warnSpy = jest.spyOn(console, 'warn').mockImplementation(() => {});

    try {
      expect(rscManifestClientReferences()).toEqual(['client/app/A.jsx']);
      expect(warnSpy).toHaveBeenCalledWith(expect.stringMatching(/may be stale/));
    } finally {
      warnSpy.mockRestore();
    }
  });

  it('warns when the configured override manifest is older than the registration entry', () => {
    process.env.RSC_MANIFEST_CLIENT_REFERENCES_JSON = 'tmp/custom-refs.json';
    const overrideManifest = path.resolve('tmp/custom-refs.json');
    fs.existsSync.mockImplementation((p) => p === overrideManifest || p === REGISTRATION_ENTRY);
    fs.readFileSync.mockReturnValue(JSON.stringify({ refs: ['client/app/A.jsx'] }));
    fs.statSync.mockImplementation((p) => ({ mtimeMs: p === REGISTRATION_ENTRY ? 2000 : 1000 }));
    const warnSpy = jest.spyOn(console, 'warn').mockImplementation(() => {});

    try {
      expect(rscManifestClientReferences()).toEqual(['client/app/A.jsx']);
      expect(warnSpy).toHaveBeenCalledWith(expect.stringMatching(/may be stale/));
    } finally {
      warnSpy.mockRestore();
    }
  });

  it('skips the non-fatal staleness warning when the manifest disappears before stat', () => {
    fs.existsSync.mockImplementation((p) => p === DEFAULT_MANIFEST || p === REGISTRATION_ENTRY);
    fs.readFileSync.mockReturnValue(JSON.stringify({ refs: ['client/app/A.jsx'] }));
    fs.statSync.mockImplementation((p) => {
      if (p === DEFAULT_MANIFEST) throw Object.assign(new Error('ENOENT'), { code: 'ENOENT' });
      return { mtimeMs: 2000 };
    });
    const warnSpy = jest.spyOn(console, 'warn').mockImplementation(() => {});

    try {
      expect(rscManifestClientReferences()).toEqual(['client/app/A.jsx']);
      expect(warnSpy).not.toHaveBeenCalled();
    } finally {
      warnSpy.mockRestore();
    }
  });

  it('does not warn when the manifest is newer than the registration entry', () => {
    fs.existsSync.mockImplementation((p) => p === DEFAULT_MANIFEST || p === REGISTRATION_ENTRY);
    fs.readFileSync.mockReturnValue(JSON.stringify({ refs: ['client/app/A.jsx'] }));
    fs.statSync.mockImplementation((p) => ({ mtimeMs: p === REGISTRATION_ENTRY ? 1000 : 2000 }));
    const warnSpy = jest.spyOn(console, 'warn').mockImplementation(() => {});

    try {
      expect(rscManifestClientReferences()).toEqual(['client/app/A.jsx']);
      expect(warnSpy).not.toHaveBeenCalled();
    } finally {
      warnSpy.mockRestore();
    }
  });

  it('does not warn or stat when the registration entry is absent', () => {
    fs.existsSync.mockImplementation((p) => p === DEFAULT_MANIFEST);
    fs.readFileSync.mockReturnValue(JSON.stringify({ refs: ['client/app/A.jsx'] }));
    const warnSpy = jest.spyOn(console, 'warn').mockImplementation(() => {});

    try {
      expect(rscManifestClientReferences()).toEqual(['client/app/A.jsx']);
      expect(warnSpy).not.toHaveBeenCalled();
      expect(fs.statSync).not.toHaveBeenCalled();
    } finally {
      warnSpy.mockRestore();
    }
  });

  it('still returns the manifest if statSync races a deleted file during the staleness check', () => {
    fs.existsSync.mockImplementation((p) => p === DEFAULT_MANIFEST || p === REGISTRATION_ENTRY);
    fs.readFileSync.mockReturnValue(JSON.stringify({ refs: ['client/app/A.jsx'] }));
    fs.statSync.mockImplementation(() => {
      throw Object.assign(new Error('ENOENT: no such file or directory'), { code: 'ENOENT' });
    });
    const warnSpy = jest.spyOn(console, 'warn').mockImplementation(() => {});

    try {
      expect(rscManifestClientReferences()).toEqual(['client/app/A.jsx']);
      expect(warnSpy).not.toHaveBeenCalled();
    } finally {
      warnSpy.mockRestore();
    }
  });
});

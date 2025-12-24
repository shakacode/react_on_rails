import * as fs from 'fs';
import * as path from 'path';
import {
  readCache,
  writeCache,
  getCachedToken,
  getFetchedAt,
  getExpiresAt,
} from '../src/shared/licenseCache';

jest.mock('fs');

describe('LicenseCache', () => {
  const mockCacheDir = '/mock/project/tmp';
  const mockCachePath = '/mock/project/tmp/react_on_rails_pro_license.cache';

  beforeEach(() => {
    // Clear environment
    delete process.env.REACT_ON_RAILS_PRO_LICENSE_KEY;

    // Mock process.cwd
    jest.spyOn(process, 'cwd').mockReturnValue('/mock/project');

    // Reset fs mocks
    jest.mocked(fs.existsSync).mockReturnValue(false);
    jest.mocked(fs.readFileSync).mockReturnValue('');
    jest.mocked(fs.writeFileSync).mockImplementation(() => {});
    jest.mocked(fs.mkdirSync).mockImplementation(() => undefined);
    jest.mocked(fs.chmodSync).mockImplementation(() => {});

    // Suppress console output
    jest.spyOn(console, 'warn').mockImplementation(() => {});
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('readCache', () => {
    it('returns null when cache file does not exist', () => {
      jest.mocked(fs.existsSync).mockReturnValue(false);

      expect(readCache()).toBeNull();
    });

    it('returns null when cache is for different license key', () => {
      process.env.REACT_ON_RAILS_PRO_LICENSE_KEY = 'lic_current';

      const cachedData = {
        token: 'eyJhbGciOiJSUzI1NiJ9...',
        expires_at: '2026-12-09T00:00:00Z',
        fetched_at: '2025-12-24T00:00:00Z',
        license_key_hash: 'differenthash12345', // Wrong hash
      };

      jest.mocked(fs.existsSync).mockReturnValue(true);
      jest.mocked(fs.readFileSync).mockReturnValue(JSON.stringify(cachedData));

      expect(readCache()).toBeNull();
    });

    it('returns cache data when valid for current license key', () => {
      process.env.REACT_ON_RAILS_PRO_LICENSE_KEY = 'lic_test123';

      // Compute expected hash (first 16 chars of SHA256)
      const crypto = require('crypto');
      const expectedHash = crypto.createHash('sha256').update('lic_test123').digest('hex').substring(0, 16);

      const cachedData = {
        token: 'eyJhbGciOiJSUzI1NiJ9...',
        expires_at: '2026-12-09T00:00:00Z',
        fetched_at: '2025-12-24T00:00:00Z',
        license_key_hash: expectedHash,
      };

      jest.mocked(fs.existsSync).mockReturnValue(true);
      jest.mocked(fs.readFileSync).mockReturnValue(JSON.stringify(cachedData));

      const result = readCache();
      expect(result).toEqual(cachedData);
    });

    it('returns null on JSON parse error', () => {
      jest.mocked(fs.existsSync).mockReturnValue(true);
      jest.mocked(fs.readFileSync).mockReturnValue('invalid json');

      expect(readCache()).toBeNull();
    });
  });

  describe('writeCache', () => {
    it('creates cache directory if it does not exist', () => {
      process.env.REACT_ON_RAILS_PRO_LICENSE_KEY = 'lic_test123';
      jest.mocked(fs.existsSync).mockReturnValue(false);

      writeCache({
        token: 'test-token',
        expires_at: '2026-12-09T00:00:00Z',
      });

      expect(fs.mkdirSync).toHaveBeenCalledWith(expect.stringContaining('tmp'), { recursive: true });
    });

    it('writes cache with correct data', () => {
      process.env.REACT_ON_RAILS_PRO_LICENSE_KEY = 'lic_test123';
      jest.mocked(fs.existsSync).mockReturnValue(true);

      const testData = {
        token: 'test-token',
        expires_at: '2026-12-09T00:00:00Z',
      };

      writeCache(testData);

      expect(fs.writeFileSync).toHaveBeenCalled();

      // Get the written data
      const writeCall = jest.mocked(fs.writeFileSync).mock.calls[0];
      const writtenData = JSON.parse(writeCall[1] as string);

      expect(writtenData.token).toBe('test-token');
      expect(writtenData.expires_at).toBe('2026-12-09T00:00:00Z');
      expect(writtenData.fetched_at).toBeDefined();
      expect(writtenData.license_key_hash).toBeDefined();
    });

    it('sets file permissions to 0600', () => {
      process.env.REACT_ON_RAILS_PRO_LICENSE_KEY = 'lic_test123';
      jest.mocked(fs.existsSync).mockReturnValue(true);

      writeCache({
        token: 'test-token',
        expires_at: '2026-12-09T00:00:00Z',
      });

      expect(fs.chmodSync).toHaveBeenCalledWith(
        expect.stringContaining('react_on_rails_pro_license.cache'),
        0o600,
      );
    });

    it('does not write when no license key is configured', () => {
      // No LICENSE_KEY set
      writeCache({
        token: 'test-token',
        expires_at: '2026-12-09T00:00:00Z',
      });

      expect(fs.writeFileSync).not.toHaveBeenCalled();
    });
  });

  describe('getCachedToken', () => {
    it('returns token from valid cache', () => {
      process.env.REACT_ON_RAILS_PRO_LICENSE_KEY = 'lic_test123';

      const crypto = require('crypto');
      const expectedHash = crypto.createHash('sha256').update('lic_test123').digest('hex').substring(0, 16);

      const cachedData = {
        token: 'cached-token-value',
        expires_at: '2026-12-09T00:00:00Z',
        fetched_at: '2025-12-24T00:00:00Z',
        license_key_hash: expectedHash,
      };

      jest.mocked(fs.existsSync).mockReturnValue(true);
      jest.mocked(fs.readFileSync).mockReturnValue(JSON.stringify(cachedData));

      expect(getCachedToken()).toBe('cached-token-value');
    });

    it('returns null when cache is invalid', () => {
      jest.mocked(fs.existsSync).mockReturnValue(false);

      expect(getCachedToken()).toBeNull();
    });
  });

  describe('getFetchedAt', () => {
    it('returns Date from valid cache', () => {
      process.env.REACT_ON_RAILS_PRO_LICENSE_KEY = 'lic_test123';

      const crypto = require('crypto');
      const expectedHash = crypto.createHash('sha256').update('lic_test123').digest('hex').substring(0, 16);

      const cachedData = {
        token: 'test-token',
        expires_at: '2026-12-09T00:00:00Z',
        fetched_at: '2025-12-24T12:00:00Z',
        license_key_hash: expectedHash,
      };

      jest.mocked(fs.existsSync).mockReturnValue(true);
      jest.mocked(fs.readFileSync).mockReturnValue(JSON.stringify(cachedData));

      const result = getFetchedAt();
      expect(result).toBeInstanceOf(Date);
      expect(result?.toISOString()).toBe('2025-12-24T12:00:00.000Z');
    });

    it('returns null when cache is invalid', () => {
      jest.mocked(fs.existsSync).mockReturnValue(false);

      expect(getFetchedAt()).toBeNull();
    });
  });

  describe('getExpiresAt', () => {
    it('returns Date from valid cache', () => {
      process.env.REACT_ON_RAILS_PRO_LICENSE_KEY = 'lic_test123';

      const crypto = require('crypto');
      const expectedHash = crypto.createHash('sha256').update('lic_test123').digest('hex').substring(0, 16);

      const cachedData = {
        token: 'test-token',
        expires_at: '2026-12-09T00:00:00Z',
        fetched_at: '2025-12-24T12:00:00Z',
        license_key_hash: expectedHash,
      };

      jest.mocked(fs.existsSync).mockReturnValue(true);
      jest.mocked(fs.readFileSync).mockReturnValue(JSON.stringify(cachedData));

      const result = getExpiresAt();
      expect(result).toBeInstanceOf(Date);
      expect(result?.toISOString()).toBe('2026-12-09T00:00:00.000Z');
    });

    it('returns null when cache is invalid', () => {
      jest.mocked(fs.existsSync).mockReturnValue(false);

      expect(getExpiresAt()).toBeNull();
    });
  });
});

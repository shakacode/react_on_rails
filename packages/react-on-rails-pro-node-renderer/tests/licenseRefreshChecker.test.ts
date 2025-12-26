import * as fs from 'fs';

// Mock dependencies before importing the module under test
jest.mock('fs');
jest.mock('../src/shared/licenseFetcher');
jest.mock('../src/shared/licenseCache');

import {
  shouldCheckForRefresh,
  maybeRefreshLicense,
  seedCacheIfNeeded,
} from '../src/shared/licenseRefreshChecker';
import { isAutoRefreshEnabled, fetchLicense } from '../src/shared/licenseFetcher';
import { getCachedToken, getFetchedAt, getExpiresAt, writeCache } from '../src/shared/licenseCache';

describe('LicenseRefreshChecker', () => {
  const ONE_DAY_MS = 24 * 60 * 60 * 1000;

  beforeEach(() => {
    // Clear environment
    delete process.env.REACT_ON_RAILS_PRO_LICENSE;
    delete process.env.REACT_ON_RAILS_PRO_LICENSE_KEY;

    // Reset mocks
    jest.mocked(isAutoRefreshEnabled).mockReturnValue(false);
    jest.mocked(fetchLicense).mockResolvedValue(null);
    jest.mocked(getCachedToken).mockReturnValue(null);
    jest.mocked(getFetchedAt).mockReturnValue(null);
    jest.mocked(getExpiresAt).mockReturnValue(null);
    jest.mocked(writeCache).mockImplementation(() => {});

    jest.mocked(fs.existsSync).mockReturnValue(false);
    jest.mocked(fs.readFileSync).mockReturnValue('');

    // Mock process.cwd
    jest.spyOn(process, 'cwd').mockReturnValue('/mock/project');

    // Suppress console output
    jest.spyOn(console, 'log').mockImplementation(() => {});
    jest.spyOn(console, 'warn').mockImplementation(() => {});
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('shouldCheckForRefresh', () => {
    it('returns false when no expires_at in cache', () => {
      jest.mocked(getExpiresAt).mockReturnValue(null);

      expect(shouldCheckForRefresh()).toBe(false);
    });

    it('returns false when more than 30 days until expiry', () => {
      const expiresAt = new Date(Date.now() + 60 * ONE_DAY_MS); // 60 days from now
      jest.mocked(getExpiresAt).mockReturnValue(expiresAt);

      expect(shouldCheckForRefresh()).toBe(false);
    });

    it('returns true when within 30 days and last fetch older than 7 days', () => {
      const expiresAt = new Date(Date.now() + 20 * ONE_DAY_MS); // 20 days from now
      const fetchedAt = new Date(Date.now() - 8 * ONE_DAY_MS); // 8 days ago

      jest.mocked(getExpiresAt).mockReturnValue(expiresAt);
      jest.mocked(getFetchedAt).mockReturnValue(fetchedAt);

      expect(shouldCheckForRefresh()).toBe(true);
    });

    it('returns false when within 30 days but last fetch less than 7 days ago', () => {
      const expiresAt = new Date(Date.now() + 20 * ONE_DAY_MS); // 20 days from now
      const fetchedAt = new Date(Date.now() - 3 * ONE_DAY_MS); // 3 days ago

      jest.mocked(getExpiresAt).mockReturnValue(expiresAt);
      jest.mocked(getFetchedAt).mockReturnValue(fetchedAt);

      expect(shouldCheckForRefresh()).toBe(false);
    });

    it('returns true when within 7 days and last fetch older than 1 day', () => {
      const expiresAt = new Date(Date.now() + 5 * ONE_DAY_MS); // 5 days from now
      const fetchedAt = new Date(Date.now() - 2 * ONE_DAY_MS); // 2 days ago

      jest.mocked(getExpiresAt).mockReturnValue(expiresAt);
      jest.mocked(getFetchedAt).mockReturnValue(fetchedAt);

      expect(shouldCheckForRefresh()).toBe(true);
    });

    it('returns false when within 7 days but last fetch less than 1 day ago', () => {
      const expiresAt = new Date(Date.now() + 5 * ONE_DAY_MS); // 5 days from now
      const fetchedAt = new Date(Date.now() - 0.5 * ONE_DAY_MS); // 12 hours ago

      jest.mocked(getExpiresAt).mockReturnValue(expiresAt);
      jest.mocked(getFetchedAt).mockReturnValue(fetchedAt);

      expect(shouldCheckForRefresh()).toBe(false);
    });

    it('returns true when within 7 days and never fetched', () => {
      const expiresAt = new Date(Date.now() + 5 * ONE_DAY_MS); // 5 days from now

      jest.mocked(getExpiresAt).mockReturnValue(expiresAt);
      jest.mocked(getFetchedAt).mockReturnValue(null);

      expect(shouldCheckForRefresh()).toBe(true);
    });
  });

  describe('maybeRefreshLicense', () => {
    it('does nothing when auto-refresh is disabled', async () => {
      jest.mocked(isAutoRefreshEnabled).mockReturnValue(false);

      await maybeRefreshLicense();

      expect(fetchLicense).not.toHaveBeenCalled();
      expect(writeCache).not.toHaveBeenCalled();
    });

    it('does nothing when refresh is not needed', async () => {
      jest.mocked(isAutoRefreshEnabled).mockReturnValue(true);
      jest.mocked(getExpiresAt).mockReturnValue(new Date(Date.now() + 60 * ONE_DAY_MS)); // Far in future

      await maybeRefreshLicense();

      expect(fetchLicense).not.toHaveBeenCalled();
      expect(writeCache).not.toHaveBeenCalled();
    });

    it('fetches and caches new token when refresh is needed', async () => {
      jest.mocked(isAutoRefreshEnabled).mockReturnValue(true);
      jest.mocked(getExpiresAt).mockReturnValue(new Date(Date.now() + 5 * ONE_DAY_MS)); // 5 days
      jest.mocked(getFetchedAt).mockReturnValue(null); // Never fetched

      const mockResponse = {
        token: 'new-token',
        expires_at: '2026-12-09T00:00:00Z',
        plan: 'paid_annual',
      };
      jest.mocked(fetchLicense).mockResolvedValue(mockResponse);

      await maybeRefreshLicense();

      expect(fetchLicense).toHaveBeenCalled();
      expect(writeCache).toHaveBeenCalledWith({
        token: 'new-token',
        expires_at: '2026-12-09T00:00:00Z',
      });
    });

    it('does not write cache when fetch fails', async () => {
      jest.mocked(isAutoRefreshEnabled).mockReturnValue(true);
      jest.mocked(getExpiresAt).mockReturnValue(new Date(Date.now() + 5 * ONE_DAY_MS));
      jest.mocked(getFetchedAt).mockReturnValue(null);
      jest.mocked(fetchLicense).mockResolvedValue(null);

      await maybeRefreshLicense();

      expect(fetchLicense).toHaveBeenCalled();
      expect(writeCache).not.toHaveBeenCalled();
    });
  });

  describe('seedCacheIfNeeded', () => {
    it('does nothing when auto-refresh is disabled', () => {
      jest.mocked(isAutoRefreshEnabled).mockReturnValue(false);

      seedCacheIfNeeded(Math.floor(Date.now() / 1000) + 86400);

      expect(writeCache).not.toHaveBeenCalled();
    });

    it('does nothing when cache already exists', () => {
      jest.mocked(isAutoRefreshEnabled).mockReturnValue(true);
      jest.mocked(getCachedToken).mockReturnValue('existing-token');

      seedCacheIfNeeded(Math.floor(Date.now() / 1000) + 86400);

      expect(writeCache).not.toHaveBeenCalled();
    });

    it('seeds cache from ENV when cache is empty', () => {
      jest.mocked(isAutoRefreshEnabled).mockReturnValue(true);
      jest.mocked(getCachedToken).mockReturnValue(null);
      process.env.REACT_ON_RAILS_PRO_LICENSE = 'env-token';

      const expTimestamp = Math.floor(Date.now() / 1000) + 86400; // 1 day from now
      seedCacheIfNeeded(expTimestamp);

      expect(writeCache).toHaveBeenCalledWith({
        token: 'env-token',
        expires_at: expect.stringMatching(/^\d{4}-\d{2}-\d{2}T/), // ISO date format
      });
    });

    it('seeds cache from config file when ENV is not set', () => {
      jest.mocked(isAutoRefreshEnabled).mockReturnValue(true);
      jest.mocked(getCachedToken).mockReturnValue(null);
      jest.mocked(fs.existsSync).mockReturnValue(true);
      jest.mocked(fs.readFileSync).mockReturnValue('file-token\n');

      const expTimestamp = Math.floor(Date.now() / 1000) + 86400;
      seedCacheIfNeeded(expTimestamp);

      expect(writeCache).toHaveBeenCalledWith({
        token: 'file-token',
        expires_at: expect.stringMatching(/^\d{4}-\d{2}-\d{2}T/),
      });
    });

    it('does nothing when neither ENV nor file has token', () => {
      jest.mocked(isAutoRefreshEnabled).mockReturnValue(true);
      jest.mocked(getCachedToken).mockReturnValue(null);
      jest.mocked(fs.existsSync).mockReturnValue(false);

      seedCacheIfNeeded(Math.floor(Date.now() / 1000) + 86400);

      expect(writeCache).not.toHaveBeenCalled();
    });
  });
});

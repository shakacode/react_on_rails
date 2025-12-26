import { isAutoRefreshEnabled, fetchLicense } from '../src/shared/licenseFetcher';

describe('LicenseFetcher', () => {
  let fetchSpy: jest.SpyInstance;

  beforeEach(() => {
    jest.restoreAllMocks();

    delete process.env.REACT_ON_RAILS_PRO_LICENSE_KEY;
    delete process.env.REACT_ON_RAILS_PRO_AUTO_REFRESH_LICENSE;
    delete process.env.REACT_ON_RAILS_PRO_LICENSE_API_URL;

    fetchSpy = jest.spyOn(global, 'fetch').mockImplementation();
    jest.spyOn(console, 'log').mockImplementation(() => {});
    jest.spyOn(console, 'warn').mockImplementation(() => {});
  });

  afterEach(() => {
    // Clear any pending retry timers to prevent "Cannot log after tests are done" errors.
    // This is safe to call regardless of whether fake timers are active (no-op with real timers).
    // See: https://github.com/jestjs/jest/issues/10487
    jest.clearAllTimers();
    jest.useRealTimers();
    jest.restoreAllMocks();
  });

  describe('isAutoRefreshEnabled', () => {
    it('returns false when LICENSE_KEY is not set', () => {
      expect(isAutoRefreshEnabled()).toBe(false);
    });

    it('returns true when LICENSE_KEY is set', () => {
      process.env.REACT_ON_RAILS_PRO_LICENSE_KEY = 'lic_test123';
      expect(isAutoRefreshEnabled()).toBe(true);
    });

    it('returns false when LICENSE_KEY is set but AUTO_REFRESH is explicitly false', () => {
      process.env.REACT_ON_RAILS_PRO_LICENSE_KEY = 'lic_test123';
      process.env.REACT_ON_RAILS_PRO_AUTO_REFRESH_LICENSE = 'false';
      expect(isAutoRefreshEnabled()).toBe(false);
    });

    it('returns true when LICENSE_KEY is set and AUTO_REFRESH is true', () => {
      process.env.REACT_ON_RAILS_PRO_LICENSE_KEY = 'lic_test123';
      process.env.REACT_ON_RAILS_PRO_AUTO_REFRESH_LICENSE = 'true';
      expect(isAutoRefreshEnabled()).toBe(true);
    });

    it('handles case-insensitive AUTO_REFRESH values', () => {
      process.env.REACT_ON_RAILS_PRO_LICENSE_KEY = 'lic_test123';
      process.env.REACT_ON_RAILS_PRO_AUTO_REFRESH_LICENSE = 'FALSE';
      expect(isAutoRefreshEnabled()).toBe(false);
    });
  });

  describe('fetchLicense', () => {
    it('returns null when auto-refresh is disabled', async () => {
      const result = await fetchLicense();
      expect(result).toBeNull();
      expect(fetchSpy).not.toHaveBeenCalled();
    });

    it('fetches license from API when enabled', async () => {
      process.env.REACT_ON_RAILS_PRO_LICENSE_KEY = 'lic_test123';

      const mockResponse = {
        token: 'eyJhbGciOiJSUzI1NiJ9...',
        expires_at: '2026-12-09T00:00:00Z',
        plan: 'paid_annual',
      };

      fetchSpy.mockResolvedValueOnce({
        status: 200,
        json: () => Promise.resolve(mockResponse),
      });

      const result = await fetchLicense();

      expect(fetchSpy).toHaveBeenCalledWith(
        'https://licenses.shakacode.com/api/license',
        expect.objectContaining({
          method: 'GET',
          headers: expect.objectContaining({
            Authorization: 'Bearer lic_test123',
          }),
        }),
      );
      expect(result).toEqual(mockResponse);
    });

    it('sends User-Agent header with requests', async () => {
      process.env.REACT_ON_RAILS_PRO_LICENSE_KEY = 'lic_test123';

      fetchSpy.mockResolvedValueOnce({
        status: 200,
        json: () => Promise.resolve({ token: 'test', expires_at: '2026-01-01' }),
      });

      await fetchLicense();

      expect(fetchSpy).toHaveBeenCalledWith(
        expect.any(String),
        expect.objectContaining({
          headers: expect.objectContaining({
            'User-Agent': 'ReactOnRailsPro-NodeRenderer',
          }),
        }),
      );
    });

    it('returns null on invalid JSON response', async () => {
      jest.useFakeTimers();
      process.env.REACT_ON_RAILS_PRO_LICENSE_KEY = 'lic_test123';

      fetchSpy.mockResolvedValue({
        status: 200,
        json: () => Promise.reject(new SyntaxError('Unexpected token')),
      });

      const resultPromise = fetchLicense();
      await jest.runAllTimersAsync();
      const result = await resultPromise;

      expect(result).toBeNull();
    });

    it('uses custom API URL when set', async () => {
      process.env.REACT_ON_RAILS_PRO_LICENSE_KEY = 'lic_test123';
      process.env.REACT_ON_RAILS_PRO_LICENSE_API_URL = 'http://localhost:3000';

      fetchSpy.mockResolvedValueOnce({
        status: 200,
        json: () => Promise.resolve({ token: 'test', expires_at: '2026-01-01' }),
      });

      await fetchLicense();

      expect(fetchSpy).toHaveBeenCalledWith('http://localhost:3000/api/license', expect.anything());
    });

    it('returns null on 401 unauthorized', async () => {
      process.env.REACT_ON_RAILS_PRO_LICENSE_KEY = 'lic_invalid';

      fetchSpy.mockResolvedValueOnce({
        status: 401,
      });

      const result = await fetchLicense();
      expect(result).toBeNull();
      expect(fetchSpy).toHaveBeenCalledTimes(1);
    });

    it('returns null on network error after retries', async () => {
      jest.useFakeTimers();
      process.env.REACT_ON_RAILS_PRO_LICENSE_KEY = 'lic_test123';

      fetchSpy.mockRejectedValue(new Error('Network error'));

      const resultPromise = fetchLicense();
      await jest.runAllTimersAsync();
      const result = await resultPromise;

      expect(result).toBeNull();
      expect(fetchSpy).toHaveBeenCalledTimes(3);
    });

    it('returns null on non-200 status after retries', async () => {
      jest.useFakeTimers();
      process.env.REACT_ON_RAILS_PRO_LICENSE_KEY = 'lic_test123';

      fetchSpy.mockResolvedValue({ status: 500 });

      const resultPromise = fetchLicense();
      await jest.runAllTimersAsync();
      const result = await resultPromise;

      expect(result).toBeNull();
      expect(fetchSpy).toHaveBeenCalledTimes(3);
    });

    it('succeeds after retry', async () => {
      jest.useFakeTimers();
      process.env.REACT_ON_RAILS_PRO_LICENSE_KEY = 'lic_test123';

      const mockResponse = {
        token: 'eyJhbGciOiJSUzI1NiJ9...',
        expires_at: '2026-12-09T00:00:00Z',
      };

      fetchSpy.mockRejectedValueOnce(new Error('Temporary error')).mockResolvedValueOnce({
        status: 200,
        json: () => Promise.resolve(mockResponse),
      });

      const resultPromise = fetchLicense();
      await jest.runAllTimersAsync();
      const result = await resultPromise;

      expect(result).toEqual(mockResponse);
      expect(fetchSpy).toHaveBeenCalledTimes(2);
    });
  });
});

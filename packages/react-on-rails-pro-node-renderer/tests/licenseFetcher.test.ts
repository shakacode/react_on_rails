import { isAutoRefreshEnabled, fetchLicense } from '../src/shared/licenseFetcher';

// Store original fetch
const originalFetch = global.fetch;

describe('LicenseFetcher', () => {
  let mockFetch: jest.Mock;

  beforeEach(() => {
    // Clear environment
    delete process.env.REACT_ON_RAILS_PRO_LICENSE_KEY;
    delete process.env.REACT_ON_RAILS_PRO_AUTO_REFRESH_LICENSE;
    delete process.env.REACT_ON_RAILS_PRO_LICENSE_API_URL;

    // Mock fetch
    mockFetch = jest.fn();
    global.fetch = mockFetch;

    // Suppress console output
    jest.spyOn(console, 'log').mockImplementation(() => {});
    jest.spyOn(console, 'warn').mockImplementation(() => {});
  });

  afterEach(() => {
    global.fetch = originalFetch;
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
      // No LICENSE_KEY set
      const result = await fetchLicense();
      expect(result).toBeNull();
      expect(mockFetch).not.toHaveBeenCalled();
    });

    it('fetches license from API when enabled', async () => {
      process.env.REACT_ON_RAILS_PRO_LICENSE_KEY = 'lic_test123';

      const mockResponse = {
        token: 'eyJhbGciOiJSUzI1NiJ9...',
        expires_at: '2026-12-09T00:00:00Z',
        plan: 'paid_annual',
      };

      mockFetch.mockResolvedValueOnce({
        status: 200,
        json: () => Promise.resolve(mockResponse),
      });

      const result = await fetchLicense();

      expect(mockFetch).toHaveBeenCalledWith(
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

    it('uses custom API URL when set', async () => {
      process.env.REACT_ON_RAILS_PRO_LICENSE_KEY = 'lic_test123';
      process.env.REACT_ON_RAILS_PRO_LICENSE_API_URL = 'http://localhost:3000';

      mockFetch.mockResolvedValueOnce({
        status: 200,
        json: () => Promise.resolve({ token: 'test', expires_at: '2026-01-01' }),
      });

      await fetchLicense();

      expect(mockFetch).toHaveBeenCalledWith('http://localhost:3000/api/license', expect.anything());
    });

    it('returns null on 401 unauthorized', async () => {
      process.env.REACT_ON_RAILS_PRO_LICENSE_KEY = 'lic_invalid';

      mockFetch.mockResolvedValueOnce({
        status: 401,
      });

      const result = await fetchLicense();
      expect(result).toBeNull();
    });

    it('returns null on network error after retries', async () => {
      process.env.REACT_ON_RAILS_PRO_LICENSE_KEY = 'lic_test123';

      // async-retry will attempt initial + retries times
      mockFetch.mockRejectedValue(new Error('Network error'));

      const result = await fetchLicense();
      expect(result).toBeNull();
      expect(mockFetch).toHaveBeenCalled();
    }, 15000);

    it('returns null on non-200 status after retries', async () => {
      process.env.REACT_ON_RAILS_PRO_LICENSE_KEY = 'lic_test123';

      // async-retry will retry on non-200 status
      mockFetch.mockResolvedValue({ status: 500 });

      const result = await fetchLicense();
      expect(result).toBeNull();
      expect(mockFetch).toHaveBeenCalled();
    }, 15000);

    it('succeeds after retry', async () => {
      process.env.REACT_ON_RAILS_PRO_LICENSE_KEY = 'lic_test123';

      const mockResponse = {
        token: 'eyJhbGciOiJSUzI1NiJ9...',
        expires_at: '2026-12-09T00:00:00Z',
      };

      mockFetch.mockRejectedValueOnce(new Error('Temporary error')).mockResolvedValueOnce({
        status: 200,
        json: () => Promise.resolve(mockResponse),
      });

      const result = await fetchLicense();
      expect(result).toEqual(mockResponse);
      expect(mockFetch).toHaveBeenCalledTimes(2);
    });
  });
});

/**
 * @jest-environment jsdom
 */

import { hydrateForceLoadedStores } from '../src/pro/ClientSideRenderer.ts';
import { getRailsContext } from '../src/context.ts';

// Mock the getRailsContext function
jest.mock('../src/context.ts', () => ({
  getRailsContext: jest.fn(),
}));

describe('Pro License Validation', () => {
  let consoleSpy;

  beforeEach(() => {
    consoleSpy = jest.spyOn(console, 'warn').mockImplementation(() => {});
    document.body.innerHTML = '';
  });

  afterEach(() => {
    consoleSpy.mockRestore();
  });

  describe('hydrateForceLoadedStores', () => {
    it('should warn and return early when no Pro license is detected', async () => {
      getRailsContext.mockReturnValue({ rorPro: false });

      const result = await hydrateForceLoadedStores();

      expect(consoleSpy).toHaveBeenCalledWith(
        "[REACT ON RAILS] The 'force_loading' feature requires a React on Rails Pro license. " +
          'Please visit https://shakacode.com/react-on-rails-pro to get a license.',
      );
      expect(result).toBeUndefined();
    });

    it('should proceed normally when Pro license is detected', () => {
      getRailsContext.mockReturnValue({ rorPro: true });

      // Test that it doesn't warn when license is valid (no force-load elements present)
      const result = hydrateForceLoadedStores();

      expect(consoleSpy).not.toHaveBeenCalled();
      expect(result).toBeDefined();
    });

    it('should return early when no rails context is available', async () => {
      getRailsContext.mockReturnValue(null);

      const result = await hydrateForceLoadedStores();

      expect(consoleSpy).toHaveBeenCalledWith(
        "[REACT ON RAILS] The 'force_loading' feature requires a React on Rails Pro license. " +
          'Please visit https://shakacode.com/react-on-rails-pro to get a license.',
      );
      expect(result).toBeUndefined();
    });
  });
});

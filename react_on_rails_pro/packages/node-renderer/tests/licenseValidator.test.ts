import * as jwt from 'jsonwebtoken';
import * as fs from 'fs';
import * as crypto from 'crypto';

// Mock modules
jest.mock('fs');
jest.mock('../src/shared/licensePublicKey', () => ({
  PUBLIC_KEY: '',
}));

interface LicenseValidatorModule {
  validateLicense: () => boolean;
  getLicenseData: () => { sub?: string; customField?: string } | undefined;
  getValidationError: () => string | undefined;
  reset: () => void;
}

describe('LicenseValidator', () => {
  let testPrivateKey: string;
  let testPublicKey: string;
  let mockProcessExit: jest.SpyInstance;
  let mockConsoleError: jest.SpyInstance;
  let originalEnv: NodeJS.ProcessEnv;

  beforeEach(() => {
    // Store original environment
    originalEnv = { ...process.env };

    // Clear the module cache to get a fresh instance
    jest.resetModules();

    // Mock process.exit globally to prevent tests from actually exiting
    mockProcessExit = jest.spyOn(process, 'exit').mockImplementation(() => {
      // Do nothing - let tests continue
      return undefined as never;
    });

    // Mock console methods to suppress logs during tests
    mockConsoleError = jest.spyOn(console, 'error').mockImplementation(() => {});
    jest.spyOn(console, 'log').mockImplementation(() => {});

    // Reset fs mocks to default (no file exists)
    jest.mocked(fs.existsSync).mockReturnValue(false);
    jest.mocked(fs.readFileSync).mockReturnValue('');

    // Generate test RSA key pair
    const { publicKey, privateKey } = crypto.generateKeyPairSync('rsa', {
      modulusLength: 2048,
      publicKeyEncoding: {
        type: 'spki',
        format: 'pem',
      },
      privateKeyEncoding: {
        type: 'pkcs8',
        format: 'pem',
      },
    });

    testPrivateKey = privateKey;
    testPublicKey = publicKey;

    // Mock the public key module
    jest.doMock('../src/shared/licensePublicKey', () => ({
      PUBLIC_KEY: testPublicKey,
    }));

    // Clear environment variable
    delete process.env.REACT_ON_RAILS_PRO_LICENSE;

    // Import after mocking and reset the validator state
    const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
    module.reset();
  });

  afterEach(() => {
    // Restore original environment
    process.env = originalEnv;
    jest.restoreAllMocks();
  });

  /**
   * Helper function to mock the REACT_ON_RAILS_PRO_LICENSE environment variable
   */
  const mockLicenseEnv = (token: string | undefined) => {
    if (token === undefined) {
      delete process.env.REACT_ON_RAILS_PRO_LICENSE;
    } else {
      process.env.REACT_ON_RAILS_PRO_LICENSE = token;
    }
  };

  describe('validateLicense', () => {
    it('validates successfully for valid license in ENV', () => {
      const validPayload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600, // Valid for 1 hour
      };

      const validToken = jwt.sign(validPayload, testPrivateKey, { algorithm: 'RS256' });
      mockLicenseEnv(validToken);

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      expect(module.validateLicense()).toBe(true);
    });

    it('calls process.exit for expired license', () => {
      const expiredPayload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000) - 7200,
        exp: Math.floor(Date.now() / 1000) - 3600, // Expired 1 hour ago
      };

      const expiredToken = jwt.sign(expiredPayload, testPrivateKey, { algorithm: 'RS256' });
      mockLicenseEnv(expiredToken);

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');

      // Call validateLicense which should trigger process.exit
      module.validateLicense();

      // Verify process.exit was called with code 1
      expect(mockProcessExit).toHaveBeenCalledWith(1);
      expect(mockConsoleError).toHaveBeenCalledWith(expect.stringContaining('License has expired'));
      expect(mockConsoleError).toHaveBeenCalledWith(expect.stringContaining('FREE evaluation license'));
    });

    it('calls process.exit for license missing exp field', () => {
      const payloadWithoutExp = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        // exp field is missing
      };

      const tokenWithoutExp = jwt.sign(payloadWithoutExp, testPrivateKey, { algorithm: 'RS256' });
      mockLicenseEnv(tokenWithoutExp);

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');

      module.validateLicense();

      expect(mockProcessExit).toHaveBeenCalledWith(1);
      expect(mockConsoleError).toHaveBeenCalledWith(
        expect.stringContaining('License is missing required expiration field'),
      );
      expect(mockConsoleError).toHaveBeenCalledWith(expect.stringContaining('FREE evaluation license'));
    });

    it('calls process.exit for invalid signature', () => {
      // Generate a different key pair for invalid signature
      const wrongKeyPair = crypto.generateKeyPairSync('rsa', {
        modulusLength: 2048,
        publicKeyEncoding: {
          type: 'spki',
          format: 'pem',
        },
        privateKeyEncoding: {
          type: 'pkcs8',
          format: 'pem',
        },
      });
      const wrongKey = wrongKeyPair.privateKey;

      const validPayload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
      };

      const invalidToken = jwt.sign(validPayload, wrongKey, { algorithm: 'RS256' });
      mockLicenseEnv(invalidToken);

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');

      module.validateLicense();

      expect(mockProcessExit).toHaveBeenCalledWith(1);
      expect(mockConsoleError).toHaveBeenCalledWith(expect.stringContaining('Invalid license signature'));
      expect(mockConsoleError).toHaveBeenCalledWith(expect.stringContaining('FREE evaluation license'));
    });

    it('calls process.exit for missing license', () => {
      mockLicenseEnv(undefined);

      // Mock fs.existsSync to return false (no config file)
      jest.mocked(fs.existsSync).mockReturnValue(false);

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');

      module.validateLicense();

      expect(mockProcessExit).toHaveBeenCalledWith(1);
      expect(mockConsoleError).toHaveBeenCalledWith(expect.stringContaining('No license found'));
      expect(mockConsoleError).toHaveBeenCalledWith(expect.stringContaining('FREE evaluation license'));
    });

    it('validates license from ENV variable after reset', () => {
      const validPayload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
      };

      const validToken = jwt.sign(validPayload, testPrivateKey, { algorithm: 'RS256' });

      // Set the license in ENV variable instead of file
      // (file-based testing is complex due to module caching)
      mockLicenseEnv(validToken);

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');

      // Reset to pick up the new ENV variable
      module.reset();

      expect(() => module.validateLicense()).not.toThrow();
      expect(mockProcessExit).not.toHaveBeenCalled();
    });

    it('caches validation result', () => {
      const validPayload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
      };

      const validToken = jwt.sign(validPayload, testPrivateKey, { algorithm: 'RS256' });
      mockLicenseEnv(validToken);

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');

      // First call
      expect(module.validateLicense()).toBe(true);

      // Change ENV (shouldn't affect cached result)
      mockLicenseEnv(undefined);

      // Second call should use cache
      expect(module.validateLicense()).toBe(true);
    });
  });

  describe('getLicenseData', () => {
    it('returns decoded license data', () => {
      const payload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
        customField: 'customValue',
      };

      const validToken = jwt.sign(payload, testPrivateKey, { algorithm: 'RS256' });
      mockLicenseEnv(validToken);

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      const data = module.getLicenseData();

      expect(data).toBeDefined();
      expect(data?.sub).toBe('test@example.com');
      expect(data?.customField).toBe('customValue');
    });
  });

  describe('getValidationError', () => {
    it('returns error message for expired license', () => {
      const expiredPayload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000) - 7200,
        exp: Math.floor(Date.now() / 1000) - 3600,
      };

      const expiredToken = jwt.sign(expiredPayload, testPrivateKey, { algorithm: 'RS256' });
      mockLicenseEnv(expiredToken);

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');

      module.validateLicense();

      expect(mockProcessExit).toHaveBeenCalledWith(1);
      const error = module.getValidationError();
      expect(error).toBeDefined();
      expect(error).toContain('License has expired');
    });
  });
});

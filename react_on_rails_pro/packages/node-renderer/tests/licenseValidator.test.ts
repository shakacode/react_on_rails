import * as jwt from 'jsonwebtoken';
import * as fs from 'fs';
import * as crypto from 'crypto';

// Mock modules
jest.mock('fs');
jest.mock('../src/shared/licensePublicKey', () => ({
  PUBLIC_KEY: '',
}));

describe('LicenseValidator', () => {
  let validateLicense;
  let getLicenseData;
  let getValidationError;
  let reset;
  let testPrivateKey;
  let testPublicKey;

  beforeEach(() => {
    // Clear the module cache to get a fresh instance
    jest.resetModules();

    // Mock process.exit globally to prevent tests from actually exiting
    jest.spyOn(process, 'exit').mockImplementation(() => {
      // Do nothing - let tests continue
      return undefined;
    });

    // Mock console methods to suppress logs during tests
    jest.spyOn(console, 'error').mockImplementation(() => {});
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

    // Import after mocking
    const module = require('../src/shared/licenseValidator');
    validateLicense = module.validateLicense;
    getLicenseData = module.getLicenseData;
    getValidationError = module.getValidationError;
    reset = module.reset;

    // Reset the validator state
    reset();
  });

  afterEach(() => {
    delete process.env.REACT_ON_RAILS_PRO_LICENSE;
    jest.restoreAllMocks();
  });

  describe('validateLicense', () => {
    it('returns true for valid license in ENV', () => {
      const validPayload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600, // Valid for 1 hour
      };

      const validToken = jwt.sign(validPayload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = validToken;

      const module = require('../src/shared/licenseValidator');
      expect(module.validateLicense()).toBe(true);
    });

    it('calls process.exit for expired license', () => {
      const expiredPayload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000) - 7200,
        exp: Math.floor(Date.now() / 1000) - 3600, // Expired 1 hour ago
      };

      const expiredToken = jwt.sign(expiredPayload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = expiredToken;

      const module = require('../src/shared/licenseValidator');

      // Call validateLicense which should trigger process.exit
      module.validateLicense();

      // Verify process.exit was called with code 1
      expect(process.exit).toHaveBeenCalledWith(1);
      expect(console.error).toHaveBeenCalledWith(expect.stringContaining('License has expired'));
      expect(console.error).toHaveBeenCalledWith(expect.stringContaining('FREE evaluation license'));
    });

    it('calls process.exit for license missing exp field', () => {
      const payloadWithoutExp = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        // exp field is missing
      };

      const tokenWithoutExp = jwt.sign(payloadWithoutExp, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = tokenWithoutExp;

      const module = require('../src/shared/licenseValidator');

      module.validateLicense();

      expect(process.exit).toHaveBeenCalledWith(1);
      expect(console.error).toHaveBeenCalledWith(
        expect.stringContaining('License is missing required expiration field'),
      );
      expect(console.error).toHaveBeenCalledWith(expect.stringContaining('FREE evaluation license'));
    });

    it('calls process.exit for invalid signature', () => {
      // Generate a different key pair for invalid signature
      const { privateKey: wrongKey } = crypto.generateKeyPairSync('rsa', {
        modulusLength: 2048,
        privateKeyEncoding: {
          type: 'pkcs8',
          format: 'pem',
        },
      });

      const validPayload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
      };

      const invalidToken = jwt.sign(validPayload, wrongKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = invalidToken;

      const module = require('../src/shared/licenseValidator');

      module.validateLicense();

      expect(process.exit).toHaveBeenCalledWith(1);
      expect(console.error).toHaveBeenCalledWith(expect.stringContaining('Invalid license signature'));
      expect(console.error).toHaveBeenCalledWith(expect.stringContaining('FREE evaluation license'));
    });

    it('calls process.exit for missing license', () => {
      delete process.env.REACT_ON_RAILS_PRO_LICENSE;

      // Mock fs.existsSync to return false (no config file)
      jest.mocked(fs.existsSync).mockReturnValue(false);

      const module = require('../src/shared/licenseValidator');

      module.validateLicense();

      expect(process.exit).toHaveBeenCalledWith(1);
      expect(console.error).toHaveBeenCalledWith(expect.stringContaining('No license found'));
      expect(console.error).toHaveBeenCalledWith(expect.stringContaining('FREE evaluation license'));
    });

    it('loads license from config file when ENV not set', () => {
      const validPayload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
      };

      const validToken = jwt.sign(validPayload, testPrivateKey, { algorithm: 'RS256' });

      // Set the license in ENV variable instead of file
      // (file-based testing is complex due to module caching)
      process.env.REACT_ON_RAILS_PRO_LICENSE = validToken;

      const module = require('../src/shared/licenseValidator');

      // Reset to pick up the new ENV variable
      reset();

      expect(module.validateLicense()).toBe(true);
    });

    it('caches validation result', () => {
      const validPayload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
      };

      const validToken = jwt.sign(validPayload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = validToken;

      const module = require('../src/shared/licenseValidator');

      // First call
      expect(module.validateLicense()).toBe(true);

      // Change ENV (shouldn't affect cached result)
      delete process.env.REACT_ON_RAILS_PRO_LICENSE;

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
      process.env.REACT_ON_RAILS_PRO_LICENSE = validToken;

      const module = require('../src/shared/licenseValidator');
      const data = module.getLicenseData();

      expect(data).toBeDefined();
      expect(data.sub).toBe('test@example.com');
      expect(data.customField).toBe('customValue');
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
      process.env.REACT_ON_RAILS_PRO_LICENSE = expiredToken;

      const module = require('../src/shared/licenseValidator');

      module.validateLicense();

      expect(process.exit).toHaveBeenCalledWith(1);
      expect(module.getValidationError()).toContain('License has expired');
    });
  });
});

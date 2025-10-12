import * as jwt from 'jsonwebtoken';
import * as fs from 'fs';
import * as crypto from 'crypto';

// Mock modules
jest.mock('fs');
jest.mock('../src/shared/licensePublicKey', () => ({
  PUBLIC_KEY: ''
}));

describe('LicenseValidator', () => {
  let licenseValidator: any;
  let testPrivateKey: string;
  let testPublicKey: string;

  beforeEach(() => {
    // Clear the module cache to get a fresh instance
    jest.resetModules();

    // Generate test RSA key pair
    const { publicKey, privateKey } = crypto.generateKeyPairSync('rsa', {
      modulusLength: 2048,
      publicKeyEncoding: {
        type: 'spki',
        format: 'pem'
      },
      privateKeyEncoding: {
        type: 'pkcs8',
        format: 'pem'
      }
    });

    testPrivateKey = privateKey;
    testPublicKey = publicKey;

    // Mock the public key module
    jest.doMock('../src/shared/licensePublicKey', () => ({
      PUBLIC_KEY: testPublicKey
    }));

    // Clear environment variable
    delete process.env.REACT_ON_RAILS_PRO_LICENSE;

    // Import after mocking
    const module = require('../src/shared/licenseValidator');
    licenseValidator = module.licenseValidator;

    // Reset the validator state
    licenseValidator.reset();
  });

  afterEach(() => {
    delete process.env.REACT_ON_RAILS_PRO_LICENSE;
    jest.restoreAllMocks();
  });

  describe('isLicenseValid', () => {
    it('returns true for valid license in ENV', () => {
      const validPayload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600 // Valid for 1 hour
      };

      const validToken = jwt.sign(validPayload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = validToken;

      const module = require('../src/shared/licenseValidator');
      expect(module.isLicenseValid()).toBe(true);
    });

    it('returns false for expired license in production', () => {
      const expiredPayload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000) - 7200,
        exp: Math.floor(Date.now() / 1000) - 3600 // Expired 1 hour ago
      };

      const expiredToken = jwt.sign(expiredPayload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = expiredToken;
      process.env.NODE_ENV = 'production';

      const module = require('../src/shared/licenseValidator');
      const consoleSpy = jest.spyOn(console, 'error').mockImplementation();

      expect(module.isLicenseValid()).toBe(false);
      expect(consoleSpy).toHaveBeenCalledWith(expect.stringContaining('License has expired'));

      consoleSpy.mockRestore();
    });

    it('returns true for expired license in development with warning', () => {
      const expiredPayload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000) - 7200,
        exp: Math.floor(Date.now() / 1000) - 3600 // Expired 1 hour ago
      };

      const expiredToken = jwt.sign(expiredPayload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = expiredToken;
      process.env.NODE_ENV = 'development';

      const module = require('../src/shared/licenseValidator');
      const consoleSpy = jest.spyOn(console, 'warn').mockImplementation();

      expect(module.isLicenseValid()).toBe(true);
      expect(consoleSpy).toHaveBeenCalledWith(
        expect.any(String),
        expect.stringContaining('License has expired')
      );

      consoleSpy.mockRestore();
    });

    it('returns false for license missing exp field in production', () => {
      const payloadWithoutExp = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000)
        // exp field is missing
      };

      const tokenWithoutExp = jwt.sign(payloadWithoutExp, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = tokenWithoutExp;
      process.env.NODE_ENV = 'production';

      const module = require('../src/shared/licenseValidator');
      const consoleSpy = jest.spyOn(console, 'error').mockImplementation();

      expect(module.isLicenseValid()).toBe(false);
      expect(consoleSpy).toHaveBeenCalledWith(expect.stringContaining('License is missing required expiration field'));

      consoleSpy.mockRestore();
    });

    it('returns true for license missing exp field in development with warning', () => {
      const payloadWithoutExp = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000)
        // exp field is missing
      };

      const tokenWithoutExp = jwt.sign(payloadWithoutExp, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = tokenWithoutExp;
      process.env.NODE_ENV = 'development';

      const module = require('../src/shared/licenseValidator');
      const consoleSpy = jest.spyOn(console, 'warn').mockImplementation();

      expect(module.isLicenseValid()).toBe(true);
      expect(consoleSpy).toHaveBeenCalledWith(
        expect.any(String),
        expect.stringContaining('License is missing required expiration field')
      );

      consoleSpy.mockRestore();
    });

    it('returns false for invalid signature', () => {
      // Generate a different key pair for invalid signature
      const { privateKey: wrongKey } = crypto.generateKeyPairSync('rsa', {
        modulusLength: 2048,
        privateKeyEncoding: {
          type: 'pkcs8',
          format: 'pem'
        }
      });

      const validPayload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600
      };

      const invalidToken = jwt.sign(validPayload, wrongKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = invalidToken;
      process.env.NODE_ENV = 'production';

      const module = require('../src/shared/licenseValidator');
      const consoleSpy = jest.spyOn(console, 'error').mockImplementation();

      expect(module.isLicenseValid()).toBe(false);
      expect(consoleSpy).toHaveBeenCalledWith(expect.stringContaining('Invalid license signature'));

      consoleSpy.mockRestore();
    });

    it('returns false for missing license', () => {
      delete process.env.REACT_ON_RAILS_PRO_LICENSE;
      process.env.NODE_ENV = 'production';

      // Mock fs.existsSync to return false (no config file)
      (fs.existsSync as jest.Mock).mockReturnValue(false);

      const module = require('../src/shared/licenseValidator');
      const consoleSpy = jest.spyOn(console, 'error').mockImplementation();

      expect(module.isLicenseValid()).toBe(false);
      expect(consoleSpy).toHaveBeenCalledWith(expect.stringContaining('No license found'));

      consoleSpy.mockRestore();
    });

    it('loads license from config file when ENV not set', () => {
      const validPayload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600
      };

      const validToken = jwt.sign(validPayload, testPrivateKey, { algorithm: 'RS256' });

      delete process.env.REACT_ON_RAILS_PRO_LICENSE;

      // Mock fs.existsSync and fs.readFileSync
      (fs.existsSync as jest.Mock).mockReturnValue(true);
      (fs.readFileSync as jest.Mock).mockReturnValue(validToken);

      const module = require('../src/shared/licenseValidator');
      expect(module.isLicenseValid()).toBe(true);

      expect(fs.readFileSync).toHaveBeenCalledWith(
        expect.stringContaining('config/react_on_rails_pro_license.key'),
        'utf8'
      );
    });

    it('caches validation result', () => {
      const validPayload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600
      };

      const validToken = jwt.sign(validPayload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = validToken;

      const module = require('../src/shared/licenseValidator');

      // First call
      expect(module.isLicenseValid()).toBe(true);

      // Change ENV (shouldn't affect cached result)
      delete process.env.REACT_ON_RAILS_PRO_LICENSE;

      // Second call should use cache
      expect(module.isLicenseValid()).toBe(true);
    });
  });

  describe('getLicenseData', () => {
    it('returns decoded license data', () => {
      const payload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
        customField: 'customValue'
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

  describe('getLicenseValidationError', () => {
    it('returns error message for expired license', () => {
      const expiredPayload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000) - 7200,
        exp: Math.floor(Date.now() / 1000) - 3600
      };

      const expiredToken = jwt.sign(expiredPayload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = expiredToken;
      process.env.NODE_ENV = 'production';

      const module = require('../src/shared/licenseValidator');
      const consoleSpy = jest.spyOn(console, 'error').mockImplementation();

      module.isLicenseValid();
      expect(module.getLicenseValidationError()).toBe('License has expired');

      consoleSpy.mockRestore();
    });
  });
});

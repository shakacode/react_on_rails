import * as jwt from 'jsonwebtoken';
import * as fs from 'fs';
import * as crypto from 'crypto';

// Mock modules
jest.mock('fs');
jest.mock('../src/shared/licensePublicKey', () => ({
  PUBLIC_KEY: '',
}));

import type { LicenseStatus } from '../src/shared/licenseValidator';

interface LicenseValidatorModule {
  getLicenseStatus: () => LicenseStatus;
  isLicensed: () => boolean;
  getLicenseData: () => Record<string, unknown> | undefined;
  reset: () => void;
}

describe('LicenseValidator', () => {
  let testPrivateKey: string;
  let testPublicKey: string;
  let mockConsoleWarn: jest.SpyInstance;

  beforeEach(() => {
    // Clear the module cache to get a fresh instance
    jest.resetModules();

    // Mock console methods to suppress logs during tests
    mockConsoleWarn = jest.spyOn(console, 'warn').mockImplementation(() => {});
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
    delete process.env.REACT_ON_RAILS_PRO_LICENSE;
    jest.restoreAllMocks();
  });

  describe('getLicenseStatus', () => {
    it('returns valid for a valid license in ENV', () => {
      const validPayload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600, // Valid for 1 hour
      };

      const validToken = jwt.sign(validPayload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = validToken;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      expect(module.getLicenseStatus()).toBe('valid');
    });

    it('returns expired for an expired license', () => {
      const expiredPayload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000) - 7200,
        exp: Math.floor(Date.now() / 1000) - 3600, // Expired 1 hour ago
      };

      const expiredToken = jwt.sign(expiredPayload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = expiredToken;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      expect(module.getLicenseStatus()).toBe('expired');
    });

    it('logs a warning for expired license', () => {
      const expiredPayload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000) - 7200,
        exp: Math.floor(Date.now() / 1000) - 3600,
      };

      const expiredToken = jwt.sign(expiredPayload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = expiredToken;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      module.getLicenseStatus();

      expect(mockConsoleWarn).toHaveBeenCalledWith(expect.stringContaining('License expired'));
    });

    it('returns invalid for license missing exp field', () => {
      const payloadWithoutExp = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        // exp field is missing
      };

      const tokenWithoutExp = jwt.sign(payloadWithoutExp, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = tokenWithoutExp;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      expect(module.getLicenseStatus()).toBe('invalid');
    });

    it('returns invalid for invalid signature', () => {
      const wrongKeyPair = crypto.generateKeyPairSync('rsa', {
        modulusLength: 2048,
        publicKeyEncoding: { type: 'spki', format: 'pem' },
        privateKeyEncoding: { type: 'pkcs8', format: 'pem' },
      });

      const validPayload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
      };

      const invalidToken = jwt.sign(validPayload, wrongKeyPair.privateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = invalidToken;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      expect(module.getLicenseStatus()).toBe('invalid');
    });

    it('returns missing when no license is found', () => {
      delete process.env.REACT_ON_RAILS_PRO_LICENSE;
      jest.mocked(fs.existsSync).mockReturnValue(false);

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      expect(module.getLicenseStatus()).toBe('missing');
    });

    it('caches the result', () => {
      const validPayload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
      };

      const validToken = jwt.sign(validPayload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = validToken;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');

      expect(module.getLicenseStatus()).toBe('valid');

      // Change ENV (shouldn't affect cached result)
      delete process.env.REACT_ON_RAILS_PRO_LICENSE;

      expect(module.getLicenseStatus()).toBe('valid');
    });
  });

  describe('isLicensed', () => {
    it('returns true for valid license', () => {
      const validPayload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
      };

      const validToken = jwt.sign(validPayload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = validToken;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      expect(module.isLicensed()).toBe(true);
    });

    it('returns false for missing license', () => {
      delete process.env.REACT_ON_RAILS_PRO_LICENSE;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      expect(module.isLicensed()).toBe(false);
    });

    it('returns false for expired license', () => {
      const expiredPayload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000) - 7200,
        exp: Math.floor(Date.now() / 1000) - 3600,
      };

      const expiredToken = jwt.sign(expiredPayload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = expiredToken;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      expect(module.isLicensed()).toBe(false);
    });
  });

  describe('getLicenseData', () => {
    it('returns license data for valid license', () => {
      const validPayload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
        plan: 'paid',
      };

      const validToken = jwt.sign(validPayload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = validToken;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      const data = module.getLicenseData();
      expect(data).toBeDefined();
      expect(data!.sub).toBe('test@example.com');
      expect(data!.plan).toBe('paid');
    });

    it('returns undefined for missing license', () => {
      delete process.env.REACT_ON_RAILS_PRO_LICENSE;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      expect(module.getLicenseData()).toBeUndefined();
    });

    it('returns undefined for invalid license', () => {
      const wrongKeyPair = crypto.generateKeyPairSync('rsa', {
        modulusLength: 2048,
        publicKeyEncoding: { type: 'spki', format: 'pem' },
        privateKeyEncoding: { type: 'pkcs8', format: 'pem' },
      });

      const validPayload = {
        sub: 'test@example.com',
        exp: Math.floor(Date.now() / 1000) + 3600,
      };

      const invalidToken = jwt.sign(validPayload, wrongKeyPair.privateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = invalidToken;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      expect(module.getLicenseData()).toBeUndefined();
    });
  });

  describe('reset', () => {
    it('clears cached state so status is re-evaluated', () => {
      const validPayload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
      };

      const validToken = jwt.sign(validPayload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = validToken;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');

      // Validate once to cache
      expect(module.getLicenseStatus()).toBe('valid');

      // Reset and remove license
      module.reset();
      delete process.env.REACT_ON_RAILS_PRO_LICENSE;

      // Should return missing now since cache was cleared
      expect(module.getLicenseStatus()).toBe('missing');
    });
  });
});

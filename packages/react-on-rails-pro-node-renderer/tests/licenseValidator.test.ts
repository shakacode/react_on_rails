import * as jwt from 'jsonwebtoken';
import * as fs from 'fs';
import * as crypto from 'crypto';

// Mock modules
jest.mock('fs');
jest.mock('../src/shared/licensePublicKey', () => ({
  PUBLIC_KEY: '',
}));

const mockLogWarn = jest.fn();
jest.mock('../src/shared/log', () => ({
  __esModule: true,
  default: {
    warn: mockLogWarn,
    info: jest.fn(),
    error: jest.fn(),
    debug: jest.fn(),
  },
}));

import type { LicenseStatus } from '../src/shared/licenseValidator';

interface LicenseValidatorModule {
  getLicenseStatus: () => LicenseStatus;
  reset: () => void;
}

describe('LicenseValidator', () => {
  let testPrivateKey: string;
  let testPublicKey: string;

  beforeEach(() => {
    // Clear the module cache to get a fresh instance
    jest.resetModules();

    // Clear log mock
    mockLogWarn.mockClear();

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

      expect(mockLogWarn).toHaveBeenCalledWith(expect.stringContaining('License expired'));
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

  describe('getLicenseStatus with plan field', () => {
    it("returns valid for plan 'paid'", () => {
      const payload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
        plan: 'paid',
      };

      const token = jwt.sign(payload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = token;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      expect(module.getLicenseStatus()).toBe('valid');
    });

    it("returns invalid for plan 'free'", () => {
      const payload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
        plan: 'free',
      };

      const token = jwt.sign(payload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = token;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      expect(module.getLicenseStatus()).toBe('invalid');
    });

    it("returns invalid for plan 'unknown'", () => {
      const payload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
        plan: 'unknown',
      };

      const token = jwt.sign(payload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = token;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      expect(module.getLicenseStatus()).toBe('invalid');
    });

    it('returns valid when plan field is absent (backwards compatibility)', () => {
      const payload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
        // No plan field
      };

      const token = jwt.sign(payload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = token;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      expect(module.getLicenseStatus()).toBe('valid');
    });

    it("logs a warning for invalid plan 'free'", () => {
      const payload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
        plan: 'free',
      };

      const token = jwt.sign(payload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = token;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      module.getLicenseStatus();

      expect(mockLogWarn).toHaveBeenCalledWith(
        expect.stringContaining("License plan 'free' is not valid for production use"),
      );
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

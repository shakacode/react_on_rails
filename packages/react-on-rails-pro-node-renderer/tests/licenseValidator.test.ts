import * as jwt from 'jsonwebtoken';
import * as crypto from 'crypto';

// Mock modules
jest.mock('../src/shared/licensePublicKey', () => ({
  PUBLIC_KEY: '',
}));

import type { LicenseStatus, ValidPlan } from '../src/shared/licenseValidator';

interface LicenseValidatorModule {
  getLicenseStatus: () => LicenseStatus;
  getLicenseOrganization: () => string | undefined;
  getLicensePlan: () => ValidPlan | undefined;
  reset: () => void;
}

describe('LicenseValidator', () => {
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
        org: 'Acme Corp',
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
        org: 'Acme Corp',
      };

      const expiredToken = jwt.sign(expiredPayload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = expiredToken;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      expect(module.getLicenseStatus()).toBe('expired');
    });

    it('returns invalid for license missing exp field', () => {
      const payloadWithoutExp = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        org: 'Acme Corp',
        // exp field is missing
      };

      const tokenWithoutExp = jwt.sign(payloadWithoutExp, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = tokenWithoutExp;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      expect(module.getLicenseStatus()).toBe('invalid');
    });

    // NOTE: Test for non-numeric exp field is not included because the jsonwebtoken
    // library validates that exp must be numeric at sign time. Any hand-crafted token
    // with non-numeric exp would fail signature verification in decodeLicense
    // before checkExpiration is reached. The defensive code in checkExpiration
    // is kept as defense-in-depth but is unreachable with valid signed JWTs.

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
        org: 'Acme Corp',
      };

      const invalidToken = jwt.sign(validPayload, wrongKeyPair.privateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = invalidToken;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      expect(module.getLicenseStatus()).toBe('invalid');
    });

    it('returns missing when no license is found', () => {
      delete process.env.REACT_ON_RAILS_PRO_LICENSE;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      expect(module.getLicenseStatus()).toBe('missing');
    });

    it('caches the result', () => {
      const validPayload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
        org: 'Acme Corp',
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
        org: 'Acme Corp',
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
        org: 'Acme Corp',
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
        org: 'Acme Corp',
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
        org: 'Acme Corp',
        // No plan field
      };

      const token = jwt.sign(payload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = token;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      expect(module.getLicenseStatus()).toBe('valid');
    });

    it('returns valid for empty string plan (treated as absent for backwards compat)', () => {
      const payload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
        plan: '',
        org: 'Acme Corp',
      };

      const token = jwt.sign(payload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = token;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      expect(module.getLicenseStatus()).toBe('valid');
    });

    it('returns valid for null plan (treated as absent)', () => {
      const payload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
        plan: null,
        org: 'Acme Corp',
      };

      const token = jwt.sign(payload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = token;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      expect(module.getLicenseStatus()).toBe('valid');
    });
  });

  describe('getLicenseStatus with org field', () => {
    it('returns valid when org is present', () => {
      const payload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
        plan: 'paid',
        org: 'Acme Corp',
      };

      const token = jwt.sign(payload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = token;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      expect(module.getLicenseStatus()).toBe('valid');
    });

    it('returns invalid when org field is absent', () => {
      const payload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
        plan: 'paid',
        // No org field
      };

      const token = jwt.sign(payload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = token;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      expect(module.getLicenseStatus()).toBe('invalid');
    });

    it('returns invalid when org is empty string', () => {
      const payload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
        plan: 'paid',
        org: '',
      };

      const token = jwt.sign(payload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = token;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      expect(module.getLicenseStatus()).toBe('invalid');
    });

    it('returns invalid when org is whitespace only', () => {
      const payload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
        plan: 'paid',
        org: '   ',
      };

      const token = jwt.sign(payload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = token;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      expect(module.getLicenseStatus()).toBe('invalid');
    });
  });

  describe('getLicenseOrganization', () => {
    it('returns organization name for valid license', () => {
      const payload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
        plan: 'paid',
        org: 'Acme Corp',
      };

      const token = jwt.sign(payload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = token;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      expect(module.getLicenseOrganization()).toBe('Acme Corp');
    });

    it('returns trimmed organization name', () => {
      const payload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
        plan: 'paid',
        org: '  Acme Corp  ',
      };

      const token = jwt.sign(payload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = token;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      expect(module.getLicenseOrganization()).toBe('Acme Corp');
    });

    it('returns undefined when org field is absent', () => {
      const payload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
        plan: 'paid',
        // No org field
      };

      const token = jwt.sign(payload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = token;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      expect(module.getLicenseOrganization()).toBeUndefined();
    });

    it('returns undefined when license is missing', () => {
      delete process.env.REACT_ON_RAILS_PRO_LICENSE;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      expect(module.getLicenseOrganization()).toBeUndefined();
    });

    it('caches the result', () => {
      const payload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
        plan: 'paid',
        org: 'Acme Corp',
      };

      const token = jwt.sign(payload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = token;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');

      expect(module.getLicenseOrganization()).toBe('Acme Corp');

      // Change ENV (shouldn't affect cached result)
      delete process.env.REACT_ON_RAILS_PRO_LICENSE;

      expect(module.getLicenseOrganization()).toBe('Acme Corp');
    });
  });

  describe('getLicensePlan', () => {
    it.each(['paid', 'startup', 'nonprofit', 'education', 'oss', 'partner'] as const)(
      "returns '%s' for valid plan type",
      (planType) => {
        const payload = {
          sub: 'test@example.com',
          iat: Math.floor(Date.now() / 1000),
          exp: Math.floor(Date.now() / 1000) + 3600,
          plan: planType,
          org: 'Acme Corp',
        };

        const token = jwt.sign(payload, testPrivateKey, { algorithm: 'RS256' });
        process.env.REACT_ON_RAILS_PRO_LICENSE = token;

        const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
        expect(module.getLicensePlan()).toBe(planType);
      },
    );

    it('returns undefined when plan field is absent', () => {
      const payload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
        org: 'Acme Corp',
        // No plan field
      };

      const token = jwt.sign(payload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = token;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      expect(module.getLicensePlan()).toBeUndefined();
    });

    it('returns undefined for invalid plan type', () => {
      const payload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
        plan: 'free',
        org: 'Acme Corp',
      };

      const token = jwt.sign(payload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = token;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      expect(module.getLicensePlan()).toBeUndefined();
    });

    it('returns undefined when license is missing', () => {
      delete process.env.REACT_ON_RAILS_PRO_LICENSE;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      expect(module.getLicensePlan()).toBeUndefined();
    });

    it('returns undefined when license has invalid signature', () => {
      const wrongKeyPair = crypto.generateKeyPairSync('rsa', {
        modulusLength: 2048,
        publicKeyEncoding: { type: 'spki', format: 'pem' },
        privateKeyEncoding: { type: 'pkcs8', format: 'pem' },
      });

      const payload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
        plan: 'paid',
        org: 'Acme Corp',
      };

      const invalidToken = jwt.sign(payload, wrongKeyPair.privateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = invalidToken;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      expect(module.getLicensePlan()).toBeUndefined();
    });

    it('caches the result', () => {
      const payload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
        plan: 'startup',
        org: 'Acme Corp',
      };

      const token = jwt.sign(payload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = token;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');

      expect(module.getLicensePlan()).toBe('startup');

      // Change ENV (shouldn't affect cached result)
      delete process.env.REACT_ON_RAILS_PRO_LICENSE;

      expect(module.getLicensePlan()).toBe('startup');
    });
  });

  describe('reset', () => {
    it('clears cached state so status is re-evaluated', () => {
      const validPayload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
        org: 'Acme Corp',
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

    it('clears cached organization so it is re-evaluated', () => {
      const validPayload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
        org: 'Acme Corp',
      };

      const validToken = jwt.sign(validPayload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = validToken;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');

      // Get organization once to cache
      expect(module.getLicenseOrganization()).toBe('Acme Corp');

      // Reset and remove license
      module.reset();
      delete process.env.REACT_ON_RAILS_PRO_LICENSE;

      // Should return undefined now since cache was cleared
      expect(module.getLicenseOrganization()).toBeUndefined();
    });

    it('clears cached plan so it is re-evaluated', () => {
      const validPayload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
        plan: 'startup',
        org: 'Acme Corp',
      };

      const validToken = jwt.sign(validPayload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = validToken;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');

      // Get plan once to cache
      expect(module.getLicensePlan()).toBe('startup');

      // Reset and remove license
      module.reset();
      delete process.env.REACT_ON_RAILS_PRO_LICENSE;

      // Should return undefined now since cache was cleared
      expect(module.getLicensePlan()).toBeUndefined();
    });
  });
});

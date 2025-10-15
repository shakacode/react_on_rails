import * as jwt from 'jsonwebtoken';
import * as fs from 'fs';
import * as crypto from 'crypto';

// Mock modules
jest.mock('fs');
jest.mock('../src/shared/licensePublicKey', () => ({
  PUBLIC_KEY: '',
}));

interface LicenseData {
  sub?: string;
  exp: number;
  plan?: string;
  iss?: string;
  [key: string]: unknown;
}

interface LicenseValidatorModule {
  getValidatedLicenseData: () => LicenseData;
  isEvaluation: () => boolean;
  getGraceDaysRemaining: () => number | undefined;
  reset: () => void;
}

describe('LicenseValidator', () => {
  let testPrivateKey: string;
  let testPublicKey: string;
  let mockProcessExit: jest.SpyInstance;
  let mockConsoleError: jest.SpyInstance;

  beforeEach(() => {
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
    delete process.env.REACT_ON_RAILS_PRO_LICENSE;
    jest.restoreAllMocks();
  });

  describe('getValidatedLicenseData', () => {
    it('returns valid license data for valid license in ENV', () => {
      const validPayload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600, // Valid for 1 hour
      };

      const validToken = jwt.sign(validPayload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = validToken;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      const data = module.getValidatedLicenseData();
      expect(data).toBeDefined();
      expect(data.sub).toBe('test@example.com');
      expect(data.exp).toBe(validPayload.exp);
    });

    it('calls process.exit for expired license in non-production', () => {
      const expiredPayload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000) - 7200,
        exp: Math.floor(Date.now() / 1000) - 3600, // Expired 1 hour ago
      };

      const expiredToken = jwt.sign(expiredPayload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = expiredToken;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');

      // Call getValidatedLicenseData which should trigger process.exit
      module.getValidatedLicenseData();

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
      process.env.REACT_ON_RAILS_PRO_LICENSE = tokenWithoutExp;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');

      module.getValidatedLicenseData();

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
      process.env.REACT_ON_RAILS_PRO_LICENSE = invalidToken;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');

      module.getValidatedLicenseData();

      expect(mockProcessExit).toHaveBeenCalledWith(1);
      expect(mockConsoleError).toHaveBeenCalledWith(expect.stringContaining('Invalid license signature'));
      expect(mockConsoleError).toHaveBeenCalledWith(expect.stringContaining('FREE evaluation license'));
    });

    it('calls process.exit for missing license', () => {
      delete process.env.REACT_ON_RAILS_PRO_LICENSE;

      // Mock fs.existsSync to return false (no config file)
      jest.mocked(fs.existsSync).mockReturnValue(false);

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');

      module.getValidatedLicenseData();

      expect(mockProcessExit).toHaveBeenCalledWith(1);
      expect(mockConsoleError).toHaveBeenCalledWith(expect.stringContaining('No license found'));
      expect(mockConsoleError).toHaveBeenCalledWith(expect.stringContaining('FREE evaluation license'));
    });

    it('caches validation result', () => {
      const validPayload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
      };

      const validToken = jwt.sign(validPayload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = validToken;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');

      // First call
      const data1 = module.getValidatedLicenseData();
      expect(data1.sub).toBe('test@example.com');

      // Change ENV (shouldn't affect cached result)
      delete process.env.REACT_ON_RAILS_PRO_LICENSE;

      // Second call should use cache
      const data2 = module.getValidatedLicenseData();
      expect(data2.sub).toBe('test@example.com');
    });
  });

  describe('isEvaluation', () => {
    it('returns true for free license', () => {
      const freePayload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
        plan: 'free',
      };

      const validToken = jwt.sign(freePayload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = validToken;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      expect(module.isEvaluation()).toBe(true);
    });

    it('returns false for paid license', () => {
      const paidPayload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
        plan: 'paid',
      };

      const validToken = jwt.sign(paidPayload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = validToken;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');
      expect(module.isEvaluation()).toBe(false);
    });
  });

  describe('reset', () => {
    it('clears cached validation data', () => {
      const validPayload = {
        sub: 'test@example.com',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
      };

      const validToken = jwt.sign(validPayload, testPrivateKey, { algorithm: 'RS256' });
      process.env.REACT_ON_RAILS_PRO_LICENSE = validToken;

      const module = jest.requireActual<LicenseValidatorModule>('../src/shared/licenseValidator');

      // Validate once to cache
      module.getValidatedLicenseData();

      // Reset and change license
      module.reset();
      delete process.env.REACT_ON_RAILS_PRO_LICENSE;

      // Should fail now since license is missing and cache was cleared
      module.getValidatedLicenseData();
      expect(mockProcessExit).toHaveBeenCalledWith(1);
    });
  });
});

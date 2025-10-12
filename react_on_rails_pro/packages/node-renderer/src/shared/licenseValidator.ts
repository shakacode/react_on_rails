import * as jwt from 'jsonwebtoken';
import * as fs from 'fs';
import * as path from 'path';
import { PUBLIC_KEY } from './licensePublicKey';

interface LicenseData {
  sub?: string;
  iat?: number;
  exp: number; // Required: expiration timestamp
  [key: string]: any;
}

class LicenseValidator {
  private static instance: LicenseValidator;
  private valid?: boolean;
  private licenseData?: LicenseData;
  private validationError?: string;

  private constructor() {}

  public static getInstance(): LicenseValidator {
    if (!LicenseValidator.instance) {
      LicenseValidator.instance = new LicenseValidator();
    }
    return LicenseValidator.instance;
  }

  public isValid(): boolean {
    if (this.valid !== undefined) {
      return this.valid;
    }

    this.valid = this.validateLicense();
    return this.valid;
  }

  public getLicenseData(): LicenseData | undefined {
    if (!this.licenseData) {
      this.loadAndDecodeLicense();
    }
    return this.licenseData;
  }

  public getValidationError(): string | undefined {
    return this.validationError;
  }

  public reset(): void {
    this.valid = undefined;
    this.licenseData = undefined;
    this.validationError = undefined;
  }

  private validateLicense(): boolean {
    const isDevelopment = process.env.NODE_ENV === 'development' || process.env.NODE_ENV === 'test';

    try {
      const license = this.loadAndDecodeLicense();
      if (!license) {
        return false;
      }

      // Check that exp field exists
      if (!license.exp) {
        this.validationError = 'License is missing required expiration field';
        this.handleInvalidLicense(isDevelopment, this.validationError);
        return isDevelopment;
      }

      // Check expiry
      if (Date.now() / 1000 > license.exp) {
        this.validationError = 'License has expired';
        this.handleInvalidLicense(isDevelopment, this.validationError);
        return isDevelopment;
      }

      return true;
    } catch (error: any) {
      if (error.name === 'JsonWebTokenError') {
        this.validationError = `Invalid license signature: ${error.message}`;
      } else {
        this.validationError = `License validation error: ${error.message}`;
      }
      this.handleInvalidLicense(isDevelopment, this.validationError);
      return isDevelopment;
    }
  }

  private loadAndDecodeLicense(): LicenseData | undefined {
    const licenseString = this.loadLicenseString();
    if (!licenseString) {
      return undefined;
    }

    try {
      const decoded = jwt.verify(licenseString, PUBLIC_KEY, {
        algorithms: ['RS256']
      }) as LicenseData;

      this.licenseData = decoded;
      return decoded;
    } catch (error) {
      throw error;
    }
  }

  private loadLicenseString(): string | undefined {
    // First try environment variable
    const envLicense = process.env.REACT_ON_RAILS_PRO_LICENSE;
    if (envLicense) {
      return envLicense;
    }

    // Then try config file (relative to project root)
    try {
      const configPath = path.join(process.cwd(), 'config', 'react_on_rails_pro_license.key');
      if (fs.existsSync(configPath)) {
        return fs.readFileSync(configPath, 'utf8').trim();
      }
    } catch (error) {
      // File doesn't exist or can't be read
    }

    this.validationError =
      'No license found. Please set REACT_ON_RAILS_PRO_LICENSE environment variable ' +
      'or create config/react_on_rails_pro_license.key file. ' +
      'Visit https://shakacode.com/react-on-rails-pro to obtain a license.';

    const isDevelopment = process.env.NODE_ENV === 'development' || process.env.NODE_ENV === 'test';
    this.handleInvalidLicense(isDevelopment, this.validationError);

    return undefined;
  }

  private handleInvalidLicense(isDevelopment: boolean, message: string): void {
    const fullMessage = `[React on Rails Pro] ${message}`;

    if (isDevelopment) {
      console.warn('\x1b[33m%s\x1b[0m', fullMessage); // Yellow warning
    } else {
      console.error(fullMessage);
      // In production, we'll exit the process later in the startup code
    }
  }
}

export const licenseValidator = LicenseValidator.getInstance();

export function isLicenseValid(): boolean {
  return licenseValidator.isValid();
}

export function getLicenseData(): LicenseData | undefined {
  return licenseValidator.getLicenseData();
}

export function getLicenseValidationError(): string | undefined {
  return licenseValidator.getValidationError();
}

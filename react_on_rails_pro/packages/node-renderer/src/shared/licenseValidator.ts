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
    try {
      const license = this.loadAndDecodeLicense();
      if (!license) {
        return false;
      }

      // Check that exp field exists
      if (!license.exp) {
        this.validationError = 'License is missing required expiration field. ' +
                               'Your license may be from an older version. ' +
                               'Get a FREE evaluation license at https://shakacode.com/react-on-rails-pro';
        this.handleInvalidLicense(this.validationError);
        return false;
      }

      // Check expiry
      if (Date.now() / 1000 > license.exp) {
        this.validationError = 'License has expired. ' +
                               'Get a FREE evaluation license (3 months) at https://shakacode.com/react-on-rails-pro ' +
                               'or upgrade to a paid license for production use.';
        this.handleInvalidLicense(this.validationError);
        return false;
      }

      // Log license type if present (for analytics)
      this.logLicenseInfo(license);

      return true;
    } catch (error: any) {
      if (error.name === 'JsonWebTokenError') {
        this.validationError = `Invalid license signature: ${error.message}. ` +
                               'Your license file may be corrupted. ' +
                               'Get a FREE evaluation license at https://shakacode.com/react-on-rails-pro';
      } else {
        this.validationError = `License validation error: ${error.message}. ` +
                               'Get a FREE evaluation license at https://shakacode.com/react-on-rails-pro';
      }
      this.handleInvalidLicense(this.validationError);
      return false;
    }
  }

  private loadAndDecodeLicense(): LicenseData | undefined {
    const licenseString = this.loadLicenseString();
    if (!licenseString) {
      return undefined;
    }

    try {
      const decoded = jwt.verify(licenseString, PUBLIC_KEY, {
        algorithms: ['RS256'],
        // Disable automatic expiration verification so we can handle it manually with custom logic
        ignoreExpiration: true
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
      'Get a FREE evaluation license at https://shakacode.com/react-on-rails-pro';

    this.handleInvalidLicense(this.validationError);

    return undefined;
  }

  private handleInvalidLicense(message: string): void {
    const fullMessage = `[React on Rails Pro] ${message}`;
    console.error(fullMessage);
    // Validation errors should prevent the application from starting
    process.exit(1);
  }

  private logLicenseInfo(license: LicenseData): void {
    const plan = (license as any).plan;
    const issuedBy = (license as any).issued_by;

    if (plan) {
      console.log(`[React on Rails Pro] License plan: ${plan}`);
    }
    if (issuedBy) {
      console.log(`[React on Rails Pro] Issued by: ${issuedBy}`);
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

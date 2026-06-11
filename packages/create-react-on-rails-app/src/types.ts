export interface CliOptions {
  template: 'javascript' | 'typescript';
  packageManager: 'npm' | 'pnpm';
  rspack: boolean;
  pro: boolean;
  rsc: boolean;
  cliVersion?: string;
}

export interface ValidationResult {
  valid: boolean;
  message: string;
}

export interface CliOptions {
  template: 'javascript' | 'typescript';
  packageManager: 'npm' | 'pnpm';
  rspack: boolean;
}

export interface ValidationResult {
  valid: boolean;
  message: string;
}

export interface StepResult {
  success: boolean;
  error?: string;
}

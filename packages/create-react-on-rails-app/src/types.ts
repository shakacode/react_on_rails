export interface CliOptions {
  template: 'javascript' | 'typescript';
  packageManager: 'npm' | 'pnpm';
  rspack: boolean;
  pro: boolean;
  rsc: boolean;
  // Emit AI-agent guidance files (AGENTS.md + editor pointers) into the generated app.
  // Default true; --no-agent-files turns it off. Forwarded to the install generator.
  agentFiles: boolean;
  cliVersion?: string;
}

export interface ValidationResult {
  valid: boolean;
  message: string;
}

import { ValidationResult } from './types.js';
import { getCommandVersion } from './utils.js';

const MIN_NODE_VERSION = 18;
const MIN_RUBY_MAJOR = 3;
const MIN_RUBY_MINOR = 0;

export function validateNode(): ValidationResult {
  const version = process.versions.node;
  const major = parseInt(version.split('.')[0], 10);

  if (major < MIN_NODE_VERSION) {
    return {
      valid: false,
      message:
        `Node.js ${version} detected. React on Rails requires Node.js ${MIN_NODE_VERSION}+.\n` +
        'Please update your version of Node.js: https://nodejs.org/',
    };
  }

  return { valid: true, message: `Node.js ${version}` };
}

export function validateRuby(): ValidationResult {
  const rubyVersion = getCommandVersion('ruby');

  if (!rubyVersion) {
    return {
      valid: false,
      message:
        'Ruby is not installed or not found in PATH.\n\n' +
        'React on Rails requires Ruby 3.0+.\n\n' +
        'Popular installation options:\n' +
        '  - mise:   https://mise.jdx.dev/ (recommended)\n' +
        '  - rbenv:  https://github.com/rbenv/rbenv\n' +
        '  - asdf:   https://asdf-vm.com/\n' +
        '  - rvm:    https://rvm.io/\n\n' +
        'After installing Ruby, restart your terminal and try again.',
    };
  }

  const match = rubyVersion.match(/ruby\s+(\d+)\.(\d+)/);
  if (!match) {
    return {
      valid: false,
      message: `Could not parse Ruby version from: "${rubyVersion.split('\n')[0].trim()}". Please ensure Ruby ${MIN_RUBY_MAJOR}.${MIN_RUBY_MINOR}+ is installed.`,
    };
  }

  const major = parseInt(match[1], 10);
  const minor = parseInt(match[2], 10);
  if (major < MIN_RUBY_MAJOR || (major === MIN_RUBY_MAJOR && minor < MIN_RUBY_MINOR)) {
    return {
      valid: false,
      message: `Ruby ${major}.${minor} detected. React on Rails requires Ruby ${MIN_RUBY_MAJOR}.${MIN_RUBY_MINOR}+.`,
    };
  }

  return { valid: true, message: rubyVersion.split('\n')[0].trim() };
}

export function validateRails(): ValidationResult {
  const railsVersion = getCommandVersion('rails');

  if (!railsVersion) {
    return {
      valid: false,
      message:
        'Rails is not installed or not found in PATH.\n\n' +
        'Install Rails:\n' +
        '  gem install rails\n\n' +
        'Then try again.',
    };
  }

  return { valid: true, message: railsVersion.split('\n')[0].trim() };
}

export function validatePackageManager(pm: 'npm' | 'pnpm'): ValidationResult {
  const version = getCommandVersion(pm);

  if (!version) {
    return {
      valid: false,
      message: `${pm} is not installed or not found in PATH.`,
    };
  }

  return { valid: true, message: `${pm} ${version.split('\n')[0].trim()}` };
}

export interface PrerequisiteResults {
  allValid: boolean;
  results: { name: string; result: ValidationResult }[];
}

export function validateAll(packageManager: 'npm' | 'pnpm'): PrerequisiteResults {
  const results = [
    { name: 'Node.js', result: validateNode() },
    { name: 'Ruby', result: validateRuby() },
    { name: 'Rails', result: validateRails() },
    { name: 'Package Manager', result: validatePackageManager(packageManager) },
  ];

  const allValid = results.every((r) => r.result.valid);

  return { allValid, results };
}

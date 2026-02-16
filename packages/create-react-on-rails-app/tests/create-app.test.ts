import { validateAppName, buildGeneratorArgs } from '../src/create-app';
import fs from 'fs';
import { CliOptions } from '../src/types';

jest.mock('fs');
const mockedFs = jest.mocked(fs);

describe('validateAppName', () => {
  beforeEach(() => {
    mockedFs.existsSync.mockReturnValue(false);
  });

  it('rejects empty name', () => {
    const result = validateAppName('');
    expect(result.success).toBe(false);
    expect(result.error).toContain('required');
  });

  it('rejects whitespace-only name', () => {
    const result = validateAppName('   ');
    expect(result.success).toBe(false);
  });

  it('rejects names with spaces', () => {
    const result = validateAppName('my app');
    expect(result.success).toBe(false);
    expect(result.error).toContain('letters, numbers, hyphens, and underscores');
  });

  it('rejects names with special characters', () => {
    const result = validateAppName('my@app');
    expect(result.success).toBe(false);
  });

  it('rejects names with dots', () => {
    const result = validateAppName('my.app');
    expect(result.success).toBe(false);
  });

  it('accepts valid names with letters', () => {
    const result = validateAppName('myapp');
    expect(result.success).toBe(true);
  });

  it('accepts valid names with hyphens', () => {
    const result = validateAppName('my-app');
    expect(result.success).toBe(true);
  });

  it('accepts valid names with underscores', () => {
    const result = validateAppName('my_app');
    expect(result.success).toBe(true);
  });

  it('accepts valid names with numbers', () => {
    const result = validateAppName('my-app-2');
    expect(result.success).toBe(true);
  });

  it('rejects when directory already exists', () => {
    mockedFs.existsSync.mockReturnValue(true);
    const result = validateAppName('existing-app');
    expect(result.success).toBe(false);
    expect(result.error).toContain('already exists');
  });
});

describe('buildGeneratorArgs', () => {
  const baseOptions: CliOptions = {
    template: 'javascript',
    packageManager: 'npm',
    rspack: false,
    rsc: false,
  };

  it('includes ignore-warnings by default', () => {
    expect(buildGeneratorArgs(baseOptions)).toEqual(['--ignore-warnings']);
  });

  it('adds typescript flag when template is typescript', () => {
    expect(buildGeneratorArgs({ ...baseOptions, template: 'typescript' })).toEqual([
      '--typescript',
      '--ignore-warnings',
    ]);
  });

  it('adds rspack flag when enabled', () => {
    expect(buildGeneratorArgs({ ...baseOptions, rspack: true })).toEqual([
      '--rspack',
      '--ignore-warnings',
    ]);
  });

  it('adds rsc flag when enabled', () => {
    expect(buildGeneratorArgs({ ...baseOptions, rsc: true })).toEqual(['--rsc', '--ignore-warnings']);
  });

  it('combines all enabled flags in order', () => {
    expect(
      buildGeneratorArgs({
        ...baseOptions,
        template: 'typescript',
        rspack: true,
        rsc: true,
      }),
    ).toEqual(['--typescript', '--rspack', '--rsc', '--ignore-warnings']);
  });
});

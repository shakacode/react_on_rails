import { validateAppName } from '../src/create-app';
import fs from 'fs';

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

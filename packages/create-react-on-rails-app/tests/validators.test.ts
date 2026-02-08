import {
  validateNode,
  validateRuby,
  validateRails,
  validatePackageManager,
  validateAll,
} from '../src/validators';
import * as utils from '../src/utils';

jest.mock('../src/utils');
const mockedGetCommandVersion = jest.mocked(utils.getCommandVersion);

describe('validateNode', () => {
  it('returns valid for the current Node version (18+)', () => {
    const result = validateNode();
    expect(result.valid).toBe(true);
    expect(result.message).toContain('Node.js');
  });
});

describe('validateRuby', () => {
  it('returns invalid when ruby is not found', () => {
    mockedGetCommandVersion.mockReturnValue(null);
    const result = validateRuby();
    expect(result.valid).toBe(false);
    expect(result.message).toContain('Ruby is not installed');
  });

  it('returns valid for Ruby 3.0+', () => {
    mockedGetCommandVersion.mockReturnValue('ruby 3.3.4 (2024-07-09 revision be1089c8ec) [arm64-darwin23]');
    const result = validateRuby();
    expect(result.valid).toBe(true);
    expect(result.message).toContain('ruby 3.3.4');
  });

  it('returns valid for Ruby 3.0.0', () => {
    mockedGetCommandVersion.mockReturnValue('ruby 3.0.0 (2020-12-25 revision 95aff21468)');
    const result = validateRuby();
    expect(result.valid).toBe(true);
  });

  it('returns invalid for Ruby 2.7', () => {
    mockedGetCommandVersion.mockReturnValue('ruby 2.7.8 (2023-03-30 revision 1f4d455848)');
    const result = validateRuby();
    expect(result.valid).toBe(false);
    expect(result.message).toContain('Ruby 2.7');
  });
});

describe('validateRails', () => {
  it('returns invalid when rails is not found', () => {
    mockedGetCommandVersion.mockReturnValue(null);
    const result = validateRails();
    expect(result.valid).toBe(false);
    expect(result.message).toContain('Rails is not installed');
  });

  it('returns valid when rails is available', () => {
    mockedGetCommandVersion.mockReturnValue('Rails 7.2.1');
    const result = validateRails();
    expect(result.valid).toBe(true);
    expect(result.message).toBe('Rails 7.2.1');
  });
});

describe('validatePackageManager', () => {
  it('returns invalid when package manager is not found', () => {
    mockedGetCommandVersion.mockReturnValue(null);
    const result = validatePackageManager('pnpm');
    expect(result.valid).toBe(false);
    expect(result.message).toContain('pnpm is not installed');
  });

  it('returns valid when npm is available', () => {
    mockedGetCommandVersion.mockReturnValue('10.8.2');
    const result = validatePackageManager('npm');
    expect(result.valid).toBe(true);
    expect(result.message).toBe('npm 10.8.2');
  });

  it('returns valid when pnpm is available', () => {
    mockedGetCommandVersion.mockReturnValue('9.14.2');
    const result = validatePackageManager('pnpm');
    expect(result.valid).toBe(true);
    expect(result.message).toBe('pnpm 9.14.2');
  });
});

describe('validateAll', () => {
  it('returns allValid false when any validator fails', () => {
    mockedGetCommandVersion.mockReturnValue(null);
    const { allValid } = validateAll('npm');
    expect(allValid).toBe(false);
  });

  it('checks all four prerequisites', () => {
    mockedGetCommandVersion.mockReturnValue('some-version');
    const { results } = validateAll('npm');
    expect(results).toHaveLength(4);
    expect(results.map((r) => r.name)).toEqual(['Node.js', 'Ruby', 'Rails', 'Package Manager']);
  });
});

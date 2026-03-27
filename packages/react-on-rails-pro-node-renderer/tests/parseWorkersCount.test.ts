import { parseWorkersCount } from '../src/ReactOnRailsProNodeRenderer';

describe('parseWorkersCount', () => {
  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('returns null for missing and blank values', () => {
    expect(parseWorkersCount(undefined)).toBeNull();
    expect(parseWorkersCount(null)).toBeNull();
    expect(parseWorkersCount('')).toBeNull();
    expect(parseWorkersCount('   ')).toBeNull();
  });

  it('parses non-negative integers', () => {
    expect(parseWorkersCount('0')).toBe(0);
    expect(parseWorkersCount('3')).toBe(3);
    expect(parseWorkersCount(' 4 ')).toBe(4);
  });

  it('warns and returns null for invalid values', () => {
    const warnSpy = jest.spyOn(console, 'warn').mockImplementation(() => undefined);

    expect(parseWorkersCount('workers')).toBeNull();
    expect(parseWorkersCount('3.5')).toBeNull();
    expect(parseWorkersCount('-1')).toBeNull();

    expect(warnSpy).toHaveBeenCalledTimes(3);
    expect(warnSpy.mock.calls[0][0]).toContain('Ignoring invalid worker count');
  });
});

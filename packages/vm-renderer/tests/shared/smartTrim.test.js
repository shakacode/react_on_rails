import { smartTrim, TRUNCATION_FILLER } from '../../src/shared/utils';

test('If gem has posted updated bundle', () => {
  const s = '1234567890';

  expect(smartTrim(s, -1)).toBe('1234567890');
  expect(smartTrim(s, 0)).toBe('1234567890');
  expect(smartTrim(s, 1)).toBe(`1${TRUNCATION_FILLER}`);
  expect(smartTrim(s, 2)).toBe(`1${TRUNCATION_FILLER}0`);
  expect(smartTrim(s, 3)).toBe(`1${TRUNCATION_FILLER}90`);
  expect(smartTrim(s, 4)).toBe(`12${TRUNCATION_FILLER}90`);
  expect(smartTrim(s, 5)).toBe(`12${TRUNCATION_FILLER}890`);
  expect(smartTrim(s, 6)).toBe(`123${TRUNCATION_FILLER}890`);
  expect(smartTrim(s, 7)).toBe(`123${TRUNCATION_FILLER}7890`);
  expect(smartTrim(s, 8)).toBe(`1234${TRUNCATION_FILLER}7890`);
  expect(smartTrim(s, 9)).toBe(`1234${TRUNCATION_FILLER}67890`);
  expect(smartTrim(s, 10)).toBe('1234567890');
  expect(smartTrim(s, 11)).toBe('1234567890');
});

import test from 'tape';

import smartTrim, { TRUNCATION_FILLER } from '../../src/shared/smartTrim';

test('If gem has posted updated bundle', (assert) => {
  assert.plan(13);

  // setConfig();

  const s = '1234567890';

  assert.equal(smartTrim(s, -1), '1234567890');
  assert.equal(smartTrim(s, 0), '1234567890');
  assert.equal(smartTrim(s, 1), `1${TRUNCATION_FILLER}`);
  assert.equal(smartTrim(s, 2), `1${TRUNCATION_FILLER}0`);
  assert.equal(smartTrim(s, 3), `1${TRUNCATION_FILLER}90`);
  assert.equal(smartTrim(s, 4), `12${TRUNCATION_FILLER}90`);
  assert.equal(smartTrim(s, 5), `12${TRUNCATION_FILLER}890`);
  assert.equal(smartTrim(s, 6), `123${TRUNCATION_FILLER}890`);
  assert.equal(smartTrim(s, 7), `123${TRUNCATION_FILLER}7890`);
  assert.equal(smartTrim(s, 8), `1234${TRUNCATION_FILLER}7890`);
  assert.equal(smartTrim(s, 9), `1234${TRUNCATION_FILLER}67890`);
  assert.equal(smartTrim(s, 10), '1234567890');
  assert.equal(smartTrim(s, 11), '1234567890');
});

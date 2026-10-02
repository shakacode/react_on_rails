const assert = require('node:assert/strict');
const { test } = require('node:test');
const { getLastResult, assertReviewCompleted } = require('./verify.cjs');

const headSha = '1570449e8ff1c04846a05c81212ddc609387ad5b';
const startedAt = '2026-10-02T04:50:00Z';
const context = { headSha, startedAt, runId: '36966141444', runAttempt: '2' };
const result = { type: 'result', is_error: false, num_turns: 6, permission_denials_count: 13 };
const report = {
  id: 123,
  user: { login: 'claude[bot]' },
  updated_at: '2026-10-02T04:58:05Z',
  body: `Review summary\n\nREVIEWED ${headSha} BY anthropic/claude\nCI run: 36966141444/2\n\nNo findings.`,
};

test('reads the last result from arrays and newline-delimited execution records', () => {
  assert.equal(getLastResult(JSON.stringify([{ type: 'system' }, result])).num_turns, 6);
  assert.equal(
    getLastResult(`${JSON.stringify(result)}\n${JSON.stringify({ ...result, num_turns: 3 })}`).num_turns,
    3,
  );
});

for (const [turns, denials] of [
  [6, 13],
  [3, 20],
]) {
  test(`rejects the observed green run with ${denials} denials and no report`, () => {
    // Native metadata captured from PR #5133, run 36966141444, attempts 1 and 2.
    assert.throws(
      () =>
        assertReviewCompleted(
          { ...result, num_turns: turns, permission_denials_count: denials },
          [],
          context,
        ),
      /No completed Claude review report/,
    );
  });
}

test('accepts a published zero-findings review despite unrelated permission denials', () => {
  assert.equal(assertReviewCompleted(result, [report], context).commentId, 123);
});

test('rejects a report for another commit', () => {
  assert.throws(
    () =>
      assertReviewCompleted(
        result,
        [{ ...report, body: report.body.replace(headSha, 'a'.repeat(40)) }],
        context,
      ),
    /No completed Claude review report/,
  );
});

test('rejects an old report, including an earlier run of the same head', () => {
  assert.throws(
    () => assertReviewCompleted(result, [{ ...report, updated_at: '2026-10-01T05:11:18Z' }], context),
    /No completed Claude review report/,
  );
});

test('rejects another CI run or attempt even when head and timestamp match', () => {
  assert.throws(
    () => assertReviewCompleted(result, [report], { ...context, runAttempt: '1' }),
    /No completed Claude review report/,
  );
  assert.throws(
    () => assertReviewCompleted(result, [report], { ...context, runId: '36966141445' }),
    /No completed Claude review report/,
  );
});

test('rejects a matching marker from another actor', () => {
  assert.throws(
    () => assertReviewCompleted(result, [{ ...report, user: { login: 'contributor' } }], context),
    /No completed Claude review report/,
  );
});

test('rejects a tracking placeholder', () => {
  assert.throws(
    () => assertReviewCompleted(result, [{ ...report, body: `Reviewing ${headSha}...` }], context),
    /No completed Claude review report/,
  );
});

test('fails closed on absent or failed native execution', () => {
  assert.throws(() => assertReviewCompleted(undefined, [report], context), /No successful native/);
  assert.throws(
    () => assertReviewCompleted({ ...result, is_error: true }, [report], context),
    /No successful native/,
  );
  assert.throws(
    () => assertReviewCompleted({ ...result, num_turns: 0 }, [report], context),
    /No successful native/,
  );
});

test('fails closed on invalid head and time metadata', () => {
  assert.throws(
    () => assertReviewCompleted(result, [report], { ...context, headSha: 'invalid' }),
    /Invalid review context/,
  );
  assert.throws(
    () => assertReviewCompleted(result, [report], { ...context, startedAt: 'invalid' }),
    /Invalid review context/,
  );
  assert.throws(
    () => assertReviewCompleted(result, [report], { ...context, runId: 'invalid' }),
    /Invalid review context/,
  );
  assert.throws(
    () => assertReviewCompleted(result, [{ ...report, updated_at: 'invalid' }], context),
    /No completed Claude review report/,
  );
});

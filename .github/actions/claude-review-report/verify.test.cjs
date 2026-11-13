const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
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
  assert.equal(assertReviewCompleted(result, [report], context).permissionDenials, 13);
});

test('counts raw SDK permission denials without publishing their arguments', () => {
  const rawResult = { ...result, permission_denials: [{ tool_name: 'Bash', tool_input: {} }] };
  assert.equal(assertReviewCompleted(rawResult, [report], context).permissionDenials, 1);
});

test('accepts the completion markers requested by the actual workflow prompt', () => {
  const workflow = fs.readFileSync(path.join(__dirname, '../../workflows/claude-code-review.yml'), 'utf8');
  const markers = workflow
    .split('\n')
    .map((line) => line.trim())
    .filter((line) => line.startsWith('REVIEWED ') || line.startsWith('CI run: '))
    .join('\n')
    .replace(/\$\{\{ github\.event\.pull_request\.head\.sha \}\}/g, headSha)
    .replace(/\$\{\{ github\.run_id \}\}/g, context.runId)
    .replace(/\$\{\{ github\.run_attempt \}\}/g, context.runAttempt);
  assert.equal(
    assertReviewCompleted(result, [{ ...report, body: `No findings.\n${markers}` }], context).commentId,
    123,
  );
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

const withRunLine = (runLine) => ({
  ...report,
  body: `No findings.\n\nREVIEWED ${headSha} BY anthropic/claude\n${runLine}`,
});

for (const runLine of [
  // Observed on PRs #5194 and #5202.
  'CI run: 36966141444/2 · [Branch](https://github.com/shakacode/react_on_rails/tree/feature)',
  // Observed on PR #5160.
  'CI run: 36966141444/2 · branch [`ppr-event-logger`](https://github.com/shakacode/react_on_rails/tree/ppr-event-logger)',
]) {
  test(`accepts a run marker followed by decoration: ${runLine.slice(0, 40)}`, () => {
    assert.equal(assertReviewCompleted(result, [withRunLine(runLine)], context).commentId, 123);
  });
}

test('rejects a linked run ID that drops the attempt', () => {
  // Observed on PR #5225; the prompt, not the verifier, prevents this form.
  const runLine =
    'CI run: [36966141444](https://github.com/shakacode/react_on_rails/actions/runs/36966141444) · Branch: [`feature`](https://github.com/shakacode/react_on_rails/tree/feature)';
  assert.throws(
    () => assertReviewCompleted(result, [withRunLine(runLine)], context),
    /No completed Claude review report/,
  );
});

test('rejects a run marker that only shares a prefix with this run', () => {
  const prefixContext = { ...context, runId: '123', runAttempt: '1' };
  for (const runLine of [
    'CI run: 123/12',
    'CI run: 123/12 · [Branch](https://example.com)',
    'CI run: 123/1x',
  ]) {
    assert.throws(
      () => assertReviewCompleted(result, [withRunLine(runLine)], prefixContext),
      /No completed Claude review report/,
    );
  }
  assert.equal(assertReviewCompleted(result, [withRunLine('CI run: 123/1')], prefixContext).commentId, 123);
});

test('rejects a decorated REVIEWED line', () => {
  const body = `No findings.\n\nREVIEWED ${headSha} BY anthropic/claude · [Branch](https://example.com)\nCI run: 36966141444/2`;
  assert.throws(
    () => assertReviewCompleted(result, [{ ...report, body }], context),
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
  assert.throws(
    () =>
      assertReviewCompleted(
        { ...result, is_error: true, num_turns: 1, total_cost_usd: 0 },
        [report],
        context,
      ),
    /Check CLAUDE_CODE_OAUTH_TOKEN/,
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

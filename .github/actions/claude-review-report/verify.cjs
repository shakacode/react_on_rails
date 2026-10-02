const fs = require('node:fs');
const { execFileSync } = require('node:child_process');

function getLastResult(text) {
  let records;
  try {
    records = JSON.parse(text);
  } catch {
    try {
      records = text
        .split('\n')
        .filter((line) => line.trim())
        .map((line) => JSON.parse(line));
    } catch {
      throw new Error('Invalid Claude execution JSON.');
    }
  }
  return [records]
    .flat(Infinity)
    .filter((record) => record?.type === 'result')
    .at(-1);
}

function assertNativeResult(result) {
  if (result?.is_error !== false || !Number.isInteger(result.num_turns) || result.num_turns < 1) {
    const tokenHint =
      result?.is_error === true && result.num_turns === 1 && result.total_cost_usd === 0
        ? " Check CLAUDE_CODE_OAUTH_TOKEN; rotate it with 'claude setup-token' if invalid or expired."
        : '';
    throw new Error(`No successful native Claude execution result; inspect the action result.${tokenHint}`);
  }
}

function assertReviewCompleted(result, comments, { headSha, startedAt, runId, runAttempt }) {
  assertNativeResult(result);
  const started = Date.parse(startedAt);
  if (
    !/^[a-f0-9]{40}$/.test(headSha) ||
    !Number.isFinite(started) ||
    !/^[1-9]\d*$/.test(runId) ||
    !/^[1-9]\d*$/.test(runAttempt)
  ) {
    throw new Error('Invalid review context.');
  }
  if (!Array.isArray(comments)) throw new Error('Invalid GitHub comment response.');

  const marker = `REVIEWED ${headSha} BY anthropic/claude`;
  const runMarker = `CI run: ${runId}/${runAttempt}`;
  const report = comments.find((comment) => {
    // Inspect only the configured app's report. Other comment prose is never interpreted.
    if (comment?.user?.login !== 'claude[bot]' || typeof comment.body !== 'string') return false;
    const updated = Date.parse(comment.updated_at);
    const lines = comment.body.split('\n').map((line) => line.trim());
    return (
      Number.isFinite(updated) &&
      updated >= started &&
      Number.isSafeInteger(comment.id) &&
      comment.id > 0 &&
      lines.includes(marker) &&
      lines.includes(runMarker)
    );
  });
  if (!report)
    throw new Error(`No completed Claude review report for ${headSha} was published during this run.`);
  return {
    commentId: report.id,
    permissionDenials: Array.isArray(result.permission_denials)
      ? result.permission_denials.length
      : (result.permission_denials_count ?? 'UNKNOWN'),
  };
}

if (require.main === module) {
  try {
    const {
      EXECUTION_FILE,
      GH_REPO,
      PR_NUMBER,
      REVIEW_HEAD_SHA,
      REVIEW_STARTED_AT,
      GITHUB_RUN_ID,
      GITHUB_RUN_ATTEMPT,
    } = process.env;
    if (!EXECUTION_FILE) throw new Error('Missing Claude execution file.');
    const result = getLastResult(fs.readFileSync(EXECUTION_FILE, 'utf8'));
    console.log(
      `Claude native result: is_error=${result?.is_error ?? 'UNKNOWN'} turns=${result?.num_turns ?? 'UNKNOWN'} cost_usd=${result?.total_cost_usd ?? 'UNKNOWN'}`,
    );
    assertNativeResult(result);
    if (!/^[\w.-]+\/[\w.-]+$/.test(GH_REPO) || !/^[1-9]\d*$/.test(PR_NUMBER)) {
      throw new Error('Invalid GitHub repository or PR number.');
    }
    const pages = JSON.parse(
      execFileSync('gh', ['api', '--paginate', '--slurp', `repos/${GH_REPO}/issues/${PR_NUMBER}/comments`], {
        encoding: 'utf8',
        timeout: 30000,
        maxBuffer: 8 * 1024 * 1024,
      }),
    );
    const verified = assertReviewCompleted(result, pages.flat(), {
      headSha: REVIEW_HEAD_SHA,
      startedAt: REVIEW_STARTED_AT,
      runId: GITHUB_RUN_ID,
      runAttempt: GITHUB_RUN_ATTEMPT,
    });
    console.log(
      `Verified Claude report ${verified.commentId} for ${REVIEW_HEAD_SHA}; permission denials: ${verified.permissionDenials}`,
    );
  } catch (error) {
    console.error(`::error::Claude review did not complete: ${error.message}`);
    process.exitCode = 1;
  }
}

module.exports = { getLastResult, assertReviewCompleted };

const assert = require('assert/strict');
const {
  GUARD_JOB_NAME,
  GUARD_STEP_NAME,
  checkPreviousMainCommitStatus,
  isGuardOnlyFailure,
  latestRunsByWorkflow,
  parseExcludeWorkflows,
} = require('./check-previous-main.cjs');

const context = { eventName: 'push', repo: { owner: 'shakacode', repo: 'react_on_rails' } };

function run({ id, workflowId = id, sha, name = `Workflow ${id}`, runNumber = id, conclusion = 'success' }) {
  return {
    id,
    workflow_id: workflowId,
    head_sha: sha,
    name,
    run_number: runNumber,
    status: 'completed',
    conclusion,
    html_url: `https://example.test/runs/${id}`,
  };
}

function guardOnlyJob() {
  return {
    name: GUARD_JOB_NAME,
    run_attempt: 1,
    conclusion: 'failure',
    steps: [{ name: GUARD_STEP_NAME, conclusion: 'failure' }],
  };
}

function mixedDetectChangesFailureJob() {
  return {
    name: GUARD_JOB_NAME,
    run_attempt: 1,
    conclusion: 'failure',
    steps: [
      { name: GUARD_STEP_NAME, conclusion: 'failure' },
      { name: 'Resolve changed files', conclusion: 'failure' },
    ],
  };
}

function buildFailureJob() {
  return {
    name: 'build',
    run_attempt: 1,
    conclusion: 'failure',
    steps: [{ name: 'Run tests', conclusion: 'failure' }],
  };
}

function successJob(name = 'build') {
  return {
    name,
    run_attempt: 1,
    conclusion: 'success',
    steps: [{ name: 'Run tests', conclusion: 'success' }],
  };
}

function makeGithub({
  pages,
  jobsByRunId,
  jobPagesByRunId,
  jobIteratorDataByRunId,
  parentsBySha,
  defaultBranchContainsSha = {},
  compareErrorByBase = {},
  commitErrorByRef = {},
}) {
  const listWorkflowRunsForRepo = async () => {};
  const listJobsForWorkflowRun = async ({ run_id: runId }) => ({
    data: { jobs: jobsByRunId[runId] || [] },
  });

  return {
    paginate: {
      iterator: async function* iterator(endpoint, options = {}) {
        if (endpoint === listJobsForWorkflowRun) {
          if (jobIteratorDataByRunId?.[options.run_id]) {
            for (const data of jobIteratorDataByRunId[options.run_id]) {
              yield { data };
            }
            return;
          }

          const jobPages = jobPagesByRunId?.[options.run_id] || [jobsByRunId[options.run_id] || []];
          for (const jobs of jobPages) {
            yield { data: { jobs } };
          }
          return;
        }

        for (const page of pages) {
          yield { data: page };
        }
      },
    },
    request: async (_route, { basehead }) => {
      const [base] = basehead.split('...');
      if (compareErrorByBase[base]) {
        throw compareErrorByBase[base];
      }

      return { data: { status: defaultBranchContainsSha[base] ? 'ahead' : 'diverged' } };
    },
    rest: {
      actions: {
        listWorkflowRunsForRepo,
        listJobsForWorkflowRun,
      },
      repos: {
        getCommit: async ({ ref }) => {
          if (commitErrorByRef[ref]) {
            throw commitErrorByRef[ref];
          }

          return {
            data: { parents: parentsBySha[ref] ? [{ sha: parentsBySha[ref] }] : [] },
          };
        },
      },
    },
  };
}

function makeCore() {
  return {
    failed: [],
    infoMessages: [],
    warnings: [],
    info(message) {
      this.infoMessages.push(message);
    },
    setFailed(message) {
      this.failed.push(message);
    },
    warning(message) {
      this.warnings.push(message);
    },
  };
}

async function testNonContiguousWorkflowRunPagesAreChecked() {
  const previous = 'previous';
  const targetPassingRun = run({ id: 8, workflowId: 80, sha: previous, name: 'Lint JS and Ruby' });
  const otherRun1 = run({ id: 9, workflowId: 90, sha: 'other-1', name: 'Other workflow 1' });
  const otherRun2 = run({ id: 10, workflowId: 100, sha: 'other-2', name: 'Other workflow 2' });
  const targetFailingRun = run({
    id: 11,
    workflowId: 110,
    sha: previous,
    name: 'JS unit tests for Renderer package',
    conclusion: 'failure',
  });
  const github = makeGithub({
    pages: [[targetPassingRun, otherRun1], [otherRun2], [targetFailingRun]],
    jobsByRunId: {
      8: [successJob()],
      11: [buildFailureJob()],
    },
    parentsBySha: {},
  });
  const core = makeCore();

  await checkPreviousMainCommitStatus({
    github,
    context,
    core,
    previousSha: previous,
    excludeWorkflowsInput: '',
    createdAfter: '2026-01-01T00:00:00.000Z',
  });

  assert.equal(core.failed.length, 1);
  assert.match(core.failed[0], /JS unit tests for Renderer package/);
}

async function testPaginatedJobsAreChecked() {
  const previous = 'previous';
  const failingRun = run({ id: 12, sha: previous, name: 'Large workflow', conclusion: 'failure' });
  const github = makeGithub({
    pages: [[failingRun]],
    jobsByRunId: {},
    jobPagesByRunId: {
      12: [[successJob('setup')], [buildFailureJob()]],
    },
    parentsBySha: {},
  });
  const core = makeCore();

  await checkPreviousMainCommitStatus({
    github,
    context,
    core,
    previousSha: previous,
    excludeWorkflowsInput: '',
    createdAfter: '2026-01-01T00:00:00.000Z',
  });

  assert.equal(core.failed.length, 1);
  assert.match(core.failed[0], /Large workflow/);
}

async function testOctokitJobIteratorArrayPagesAreChecked() {
  const previous = 'previous';
  const failingRun = run({ id: 14, sha: previous, name: 'Main push lint', conclusion: 'failure' });
  const github = makeGithub({
    pages: [[failingRun]],
    jobsByRunId: {},
    jobIteratorDataByRunId: {
      14: [[successJob('setup')], [buildFailureJob()]],
    },
    parentsBySha: {},
  });
  const core = makeCore();

  await checkPreviousMainCommitStatus({
    github,
    context,
    core,
    previousSha: previous,
    excludeWorkflowsInput: '',
    createdAfter: '2026-01-01T00:00:00.000Z',
  });

  assert.equal(core.failed.length, 1);
  assert.match(core.failed[0], /Main push lint/);
}

async function testUnexpectedJobIteratorShapeFailsClearly() {
  const previous = 'previous';
  const failingRun = run({ id: 15, sha: previous, name: 'Main push lint', conclusion: 'failure' });
  const github = makeGithub({
    pages: [[failingRun]],
    jobsByRunId: {},
    jobIteratorDataByRunId: {
      15: [{}],
    },
    parentsBySha: {},
  });
  const core = makeCore();

  await assert.rejects(
    () =>
      checkPreviousMainCommitStatus({
        github,
        context,
        core,
        previousSha: previous,
        excludeWorkflowsInput: '',
        createdAfter: '2026-01-01T00:00:00.000Z',
      }),
    /Expected jobs array while listing workflow run 15 \(Main push lint\)\./,
  );
}

async function testGuardOnlyHopLimitStopsAtConfiguredLimit() {
  const previous = 'docs-2';
  const parent = 'docs-1';
  const guardRun = run({ id: 13, sha: previous, name: 'Lint JS and Ruby', conclusion: 'failure' });
  const github = makeGithub({
    pages: [[guardRun]],
    jobsByRunId: {
      13: [guardOnlyJob()],
    },
    parentsBySha: {
      [previous]: parent,
    },
  });
  const core = makeCore();

  await checkPreviousMainCommitStatus({
    github,
    context,
    core,
    previousSha: previous,
    excludeWorkflowsInput: '',
    maxGuardOnlyHops: 1,
    createdAfter: '2026-01-01T00:00:00.000Z',
  });

  assert.equal(core.failed.length, 1);
  assert.match(core.failed[0], /after 1 docs-only guard-only commits/);
}

async function testGuardOnlyFailuresLookThroughToParentFailure() {
  const previous = 'docs-2';
  const parent = 'docs-1';
  const realFailure = 'real-failure';
  const guardRun1 = run({ id: 1, sha: previous, name: 'Lint JS and Ruby', conclusion: 'failure' });
  const guardRun2 = run({
    id: 2,
    sha: parent,
    name: 'JS unit tests for Renderer package',
    conclusion: 'failure',
  });
  const realRun = run({ id: 3, sha: realFailure, name: 'Check Markdown Links', conclusion: 'failure' });
  const github = makeGithub({
    pages: [[guardRun1], [guardRun2], [realRun]],
    jobsByRunId: {
      1: [guardOnlyJob()],
      2: [guardOnlyJob()],
      3: [buildFailureJob()],
    },
    parentsBySha: {
      [previous]: parent,
      [parent]: realFailure,
    },
  });
  const core = makeCore();

  await checkPreviousMainCommitStatus({
    github,
    context,
    core,
    previousSha: previous,
    excludeWorkflowsInput: '',
    createdAfter: '2026-01-01T00:00:00.000Z',
  });

  assert.equal(core.failed.length, 1);
  assert.match(core.failed[0], /main commit real-failure still has failing workflows/);
  assert.match(core.failed[0], /Ignored docs-only guard-only failures/);
}

async function testNoRunSyntheticBaseLooksThroughToParentFailure() {
  const syntheticBase = 'synthetic-base';
  const realFailure = 'real-failure';
  const realRun = run({ id: 16, sha: realFailure, name: 'Main push lint', conclusion: 'failure' });
  const github = makeGithub({
    pages: [[realRun]],
    jobsByRunId: {
      16: [buildFailureJob()],
    },
    parentsBySha: {
      [syntheticBase]: realFailure,
    },
  });
  const core = makeCore();

  await checkPreviousMainCommitStatus({
    github,
    context: { ...context, eventName: 'merge_group' },
    core,
    previousSha: syntheticBase,
    excludeWorkflowsInput: '',
    createdAfter: '2026-01-01T00:00:00.000Z',
  });

  assert.equal(core.failed.length, 1);
  assert.match(core.failed[0], /main commit real-failure still has failing workflows/);
}

async function testNoRunPushBaseAllowsQuietMainSkip() {
  const quietMain = 'quiet-main';
  const olderFailure = 'older-failure';
  const realRun = run({ id: 17, sha: olderFailure, name: 'Main push lint', conclusion: 'failure' });
  const github = makeGithub({
    pages: [[realRun]],
    jobsByRunId: {
      17: [buildFailureJob()],
    },
    parentsBySha: {
      [quietMain]: olderFailure,
    },
  });
  const core = makeCore();

  await checkPreviousMainCommitStatus({
    github,
    context,
    core,
    previousSha: quietMain,
    excludeWorkflowsInput: '',
    createdAfter: '2026-01-01T00:00:00.000Z',
  });

  assert.deepEqual(core.failed, []);
  assert.match(core.infoMessages.at(-1), /Allowing docs-only skip/);
}

async function testNoRunSyntheticBaseAllowsQuietParentSkip() {
  const syntheticBase = 'synthetic-base';
  const quietMain = 'quiet-main';
  const olderFailure = 'older-failure';
  const realRun = run({ id: 18, sha: olderFailure, name: 'Main push lint', conclusion: 'failure' });
  const github = makeGithub({
    pages: [[realRun]],
    jobsByRunId: {
      18: [buildFailureJob()],
    },
    parentsBySha: {
      [syntheticBase]: quietMain,
      [quietMain]: olderFailure,
    },
    defaultBranchContainsSha: {
      [quietMain]: true,
    },
  });
  const core = makeCore();

  await checkPreviousMainCommitStatus({
    github,
    context: { ...context, eventName: 'merge_group' },
    core,
    previousSha: syntheticBase,
    excludeWorkflowsInput: '',
    createdAfter: '2026-01-01T00:00:00.000Z',
  });

  assert.deepEqual(core.failed, []);
  assert.match(core.infoMessages.at(-1), /Allowing docs-only skip/);
}

async function testNoRunSyntheticChainLooksThroughToParentFailure() {
  const syntheticBase = 'synthetic-base';
  const priorSyntheticBase = 'prior-synthetic-base';
  const realFailure = 'real-failure';
  const realRun = run({ id: 19, sha: realFailure, name: 'Main push lint', conclusion: 'failure' });
  const github = makeGithub({
    pages: [[realRun]],
    jobsByRunId: {
      19: [buildFailureJob()],
    },
    parentsBySha: {
      [syntheticBase]: priorSyntheticBase,
      [priorSyntheticBase]: realFailure,
    },
  });
  const core = makeCore();

  await checkPreviousMainCommitStatus({
    github,
    context: { ...context, eventName: 'merge_group' },
    core,
    previousSha: syntheticBase,
    excludeWorkflowsInput: '',
    createdAfter: '2026-01-01T00:00:00.000Z',
  });

  assert.equal(core.failed.length, 1);
  assert.match(core.failed[0], /main commit real-failure still has failing workflows/);
}

async function testNoRunHopLimitStopsAtConfiguredLimitWithTrail() {
  const syntheticBase = 'synthetic-base';
  const priorSyntheticBase = 'prior-synthetic-base';
  const github = makeGithub({
    pages: [],
    jobsByRunId: {},
    parentsBySha: {
      [syntheticBase]: priorSyntheticBase,
    },
  });
  const core = makeCore();

  await checkPreviousMainCommitStatus({
    github,
    context: { ...context, eventName: 'merge_group' },
    core,
    previousSha: syntheticBase,
    excludeWorkflowsInput: '',
    maxNoRunsHops: 1,
    createdAfter: '2026-01-01T00:00:00.000Z',
  });

  assert.equal(core.failed.length, 1);
  assert.match(core.failed[0], /after 1 no-run merge queue candidate commits/);
  assert.match(core.failed[0], /synthetic-base/);
}

async function testCompareUnprocessableSyntheticBaseLooksThroughToParentFailure() {
  const syntheticBase = 'synthetic-base';
  const realFailure = 'real-failure';
  const failingRun = run({ id: 16, sha: realFailure, name: 'Ruby Tests', conclusion: 'failure' });
  const compareError = new Error('No common ancestor');
  compareError.status = 422;
  const github = makeGithub({
    pages: [[failingRun]],
    jobsByRunId: {
      16: [buildFailureJob()],
    },
    parentsBySha: {
      [syntheticBase]: realFailure,
    },
    compareErrorByBase: {
      [syntheticBase]: compareError,
    },
  });
  const core = makeCore();

  await checkPreviousMainCommitStatus({
    github,
    context: { ...context, eventName: 'merge_group' },
    core,
    previousSha: syntheticBase,
    excludeWorkflowsInput: '',
    createdAfter: '2026-01-01T00:00:00.000Z',
  });

  assert.equal(core.failed.length, 1);
  assert.match(core.failed[0], /main commit real-failure still has failing workflows/);
  assert.match(core.failed[0], /synthetic-base/);
}

async function testCompareTransientFailureSetsHelpfulFailure() {
  const syntheticBase = 'synthetic-base';
  const priorSyntheticBase = 'prior-synthetic-base';
  const compareError = new Error('GitHub is unavailable');
  compareError.status = 502;
  const github = makeGithub({
    pages: [],
    jobsByRunId: {},
    parentsBySha: {
      [syntheticBase]: priorSyntheticBase,
    },
    compareErrorByBase: {
      [priorSyntheticBase]: compareError,
    },
  });
  const core = makeCore();

  await checkPreviousMainCommitStatus({
    github,
    context: { ...context, eventName: 'merge_group' },
    core,
    previousSha: syntheticBase,
    excludeWorkflowsInput: '',
    createdAfter: '2026-01-01T00:00:00.000Z',
  });

  assert.equal(core.failed.length, 1);
  assert.match(core.failed[0], /Cannot determine prior real CI status because a GitHub API request failed/);
  assert.match(core.failed[0], /502/);
  assert.match(core.failed[0], /Skipped candidate commits[\s\S]*- synthetic-base/);
  assert.match(core.failed[0], /prior-synthetic-base/);
  assert.match(core.failed[0], /GitHub is unavailable/);
}

async function testCompareNetworkFailureSetsHelpfulFailure() {
  const syntheticBase = 'synthetic-base';
  const compareError = new Error('read ECONNRESET');
  const github = makeGithub({
    pages: [],
    jobsByRunId: {},
    parentsBySha: {},
    compareErrorByBase: {
      [syntheticBase]: compareError,
    },
  });
  const core = makeCore();

  await checkPreviousMainCommitStatus({
    github,
    context: { ...context, eventName: 'merge_group' },
    core,
    previousSha: syntheticBase,
    excludeWorkflowsInput: '',
    createdAfter: '2026-01-01T00:00:00.000Z',
  });

  assert.equal(core.failed.length, 1);
  assert.match(core.failed[0], /Cannot determine prior real CI status because a GitHub API request failed/);
  assert.match(core.failed[0], /synthetic-base/);
  assert.match(core.failed[0], /read ECONNRESET/);
}

async function testFirstParentNetworkFailureSetsHelpfulFailure() {
  const syntheticBase = 'synthetic-base';
  const commitError = new Error('read ECONNRESET');
  const github = makeGithub({
    pages: [],
    jobsByRunId: {},
    parentsBySha: {},
    commitErrorByRef: {
      [syntheticBase]: commitError,
    },
  });
  const core = makeCore();

  await checkPreviousMainCommitStatus({
    github,
    context: { ...context, eventName: 'merge_group' },
    core,
    previousSha: syntheticBase,
    excludeWorkflowsInput: '',
    createdAfter: '2026-01-01T00:00:00.000Z',
  });

  assert.equal(core.failed.length, 1);
  assert.match(core.failed[0], /Cannot determine prior real CI status because a GitHub API request failed/);
  assert.match(core.failed[0], /synthetic-base/);
  assert.match(core.failed[0], /read ECONNRESET/);
}

async function testNoRunUnreachableSyntheticBaseWithoutParentFailsClosed() {
  const syntheticBase = 'synthetic-base';
  const github = makeGithub({
    pages: [],
    jobsByRunId: {},
    parentsBySha: {},
  });
  const core = makeCore();

  await checkPreviousMainCommitStatus({
    github,
    context: { ...context, eventName: 'merge_group' },
    core,
    previousSha: syntheticBase,
    excludeWorkflowsInput: '',
    createdAfter: '2026-01-01T00:00:00.000Z',
  });

  assert.equal(core.failed.length, 1);
  assert.match(core.failed[0], /not in the default branch and has no parent commits to inspect/);
  assert.match(core.failed[0], /synthetic-base/);
}

async function testGuardOnlyFailuresLookThroughToParentSuccess() {
  const previous = 'docs-1';
  const parent = 'green';
  const guardRun = run({ id: 4, sha: previous, name: 'Lint JS and Ruby', conclusion: 'failure' });
  const greenRun = run({ id: 5, sha: parent, name: 'Lint JS and Ruby' });
  const github = makeGithub({
    pages: [[guardRun], [greenRun]],
    jobsByRunId: {
      4: [guardOnlyJob()],
      5: [successJob()],
    },
    parentsBySha: {
      [previous]: parent,
    },
  });
  const core = makeCore();

  await checkPreviousMainCommitStatus({
    github,
    context,
    core,
    previousSha: previous,
    excludeWorkflowsInput: '',
    createdAfter: '2026-01-01T00:00:00.000Z',
  });

  assert.deepEqual(core.failed, []);
  assert.match(core.infoMessages.at(-1), /completed without failures/);
}

async function main() {
  assert.deepEqual(parseExcludeWorkflows('Benchmark Workflow, Check Markdown Links'), [
    'Benchmark Workflow',
    'Check Markdown Links',
  ]);
  assert.equal(isGuardOnlyFailure([guardOnlyJob()]), true);
  assert.equal(isGuardOnlyFailure([buildFailureJob()]), false);
  assert.equal(isGuardOnlyFailure([mixedDetectChangesFailureJob()]), false);
  assert.equal(
    latestRunsByWorkflow([
      run({ id: 6, workflowId: 10, sha: 'a', runNumber: 1 }),
      run({ id: 7, workflowId: 10, sha: 'a', runNumber: 2 }),
    ]).get(10).id,
    7,
  );

  await testGuardOnlyFailuresLookThroughToParentFailure();
  await testNoRunSyntheticBaseLooksThroughToParentFailure();
  await testNoRunPushBaseAllowsQuietMainSkip();
  await testNoRunSyntheticBaseAllowsQuietParentSkip();
  await testNoRunSyntheticChainLooksThroughToParentFailure();
  await testNoRunHopLimitStopsAtConfiguredLimitWithTrail();
  await testCompareUnprocessableSyntheticBaseLooksThroughToParentFailure();
  await testCompareTransientFailureSetsHelpfulFailure();
  await testCompareNetworkFailureSetsHelpfulFailure();
  await testFirstParentNetworkFailureSetsHelpfulFailure();
  await testNoRunUnreachableSyntheticBaseWithoutParentFailsClosed();
  await testGuardOnlyFailuresLookThroughToParentSuccess();
  await testNonContiguousWorkflowRunPagesAreChecked();
  await testPaginatedJobsAreChecked();
  await testOctokitJobIteratorArrayPagesAreChecked();
  await testUnexpectedJobIteratorShapeFailsClearly();
  await testGuardOnlyHopLimitStopsAtConfiguredLimit();
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

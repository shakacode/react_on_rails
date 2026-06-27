const assert = require('assert/strict');
const {
  checkPreviousMainCommitStatus,
  isGuardOnlyFailure,
  latestRunsByWorkflow,
  parseExcludeWorkflows,
} = require('./check-previous-main.cjs');

const context = { repo: { owner: 'shakacode', repo: 'react_on_rails' } };

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
    name: 'detect-changes',
    run_attempt: 1,
    conclusion: 'failure',
    steps: [{ name: 'Guard docs-only main pushes', conclusion: 'failure' }],
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

function makeGithub({ pages, jobsByRunId, parentsBySha }) {
  return {
    paginate: {
      iterator: async function* iterator() {
        for (const page of pages) {
          yield { data: page };
        }
      },
    },
    rest: {
      actions: {
        listWorkflowRunsForRepo: async () => {},
        listJobsForWorkflowRun: async ({ run_id: runId }) => ({
          data: { jobs: jobsByRunId[runId] || [] },
        }),
      },
      repos: {
        getCommit: async ({ ref }) => ({
          data: { parents: parentsBySha[ref] ? [{ sha: parentsBySha[ref] }] : [] },
        }),
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
  assert.equal(
    latestRunsByWorkflow([
      run({ id: 6, workflowId: 10, sha: 'a', runNumber: 1 }),
      run({ id: 7, workflowId: 10, sha: 'a', runNumber: 2 }),
    ]).get(10).id,
    7,
  );

  await testGuardOnlyFailuresLookThroughToParentFailure();
  await testGuardOnlyFailuresLookThroughToParentSuccess();
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

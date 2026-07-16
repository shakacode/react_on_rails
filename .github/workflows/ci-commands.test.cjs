const assert = require('node:assert/strict');
const fs = require('node:fs');
const { test } = require('node:test');

const AsyncFunction = Object.getPrototypeOf(async function asyncFunctionPrototype() {
  return undefined;
}).constructor;

const workflowSource = fs.readFileSync('.github/workflows/ci-commands.yml', 'utf8');
const scriptMarker = '          script: |\n';
const scriptStart = workflowSource.indexOf(scriptMarker);

assert.notEqual(scriptStart, -1, 'ci-commands workflow must contain an embedded github-script');

const workflowScript = workflowSource
  .slice(scriptStart + scriptMarker.length)
  .split('\n')
  .map((line) => (line.startsWith('            ') ? line.slice(12) : line))
  .join('\n');
const executeWorkflow = new AsyncFunction('github', 'context', 'core', workflowScript);

const hostedWorkflowFiles = [
  'lint-js-and-ruby.yml',
  'package-js-tests.yml',
  'gem-tests.yml',
  'integration-tests.yml',
  'precompile-check.yml',
  'examples.yml',
  'playwright.yml',
  'pro-integration-tests.yml',
  'pro-test-package-and-gem.yml',
];

function defaultPullRequest() {
  return {
    base: { ref: 'release/17.0.0', sha: 'base-sha' },
    head: {
      ref: 'verify-release-ci',
      repo: { full_name: 'shakacode/react_on_rails' },
      sha: 'current-head-sha',
    },
    merged: false,
    state: 'open',
    user: { login: 'maintainer' },
  };
}

function currentPullRequestAssociation() {
  return [
    {
      base: { ref: 'release/17.0.0', sha: 'base-sha' },
      head: { ref: 'verify-release-ci', sha: 'current-head-sha' },
      number: 42,
    },
  ];
}

function coverageMarkerFrom(comment) {
  const match = comment.match(/<!-- hosted-ci-coverage:v1 (\{[^\r\n]*\}) -->/);
  assert.ok(match, 'expected a machine-readable hosted-CI coverage marker');
  return JSON.parse(match[1]);
}

async function runCommand({
  body,
  ciCommandRunSnapshots = [],
  comments = [],
  dispatchErrors = {},
  dispatchReturnsNoRunDetails = false,
  dispatchedRunOverrides = {},
  files,
  labels = [],
  nowMs,
  pullRequest,
  pullRequests,
  runListError,
  runs = [],
  serializationRunListError,
  workflowRunReadFailures = {},
}) {
  const calls = {
    comments: [],
    dispatches: [],
    failures: [],
    labels: [],
    reactions: [],
    workflowRunReads: [],
  };
  const pr = pullRequest || defaultPullRequest();
  const pullRequestSequence = pullRequests || [pr];
  let pullRequestReadIndex = 0;
  const dispatchedRuns = new Map();
  const workflowRunReadIndexes = new Map();
  let serializationCompleted = ciCommandRunSnapshots.length === 0;
  let serializationSnapshotIndex = 0;
  const endpoints = {
    addLabels: async ({ labels: addedLabels }) => calls.labels.push(...addedLabels),
    createComment: async ({ body: commentBody }) => calls.comments.push(commentBody),
    createLabel: async () => {},
    createWorkflowDispatch: async (options) => {
      calls.dispatches.push(options);
      if (dispatchErrors[options.workflow_id]) throw dispatchErrors[options.workflow_id];
      if (dispatchReturnsNoRunDetails) return { data: '', status: 204 };
      const runId = 1000 + calls.dispatches.length;
      dispatchedRuns.set(runId, {
        event: 'workflow_dispatch',
        head_sha: pr.head.sha,
        id: runId,
        path: `.github/workflows/${options.workflow_id}`,
        status: 'queued',
        ...dispatchedRunOverrides[options.workflow_id],
      });
      return { data: { workflow_run_id: runId }, status: 200 };
    },
    getWorkflowRun: async ({ run_id: runId }) => {
      calls.workflowRunReads.push(runId);
      const workflowFile = dispatchedRuns.get(runId)?.path?.split('/').at(-1);
      const readIndex = workflowRunReadIndexes.get(runId) || 0;
      workflowRunReadIndexes.set(runId, readIndex + 1);
      const failure = workflowRunReadFailures[workflowFile]?.[readIndex];
      if (failure) throw failure;
      return { data: dispatchedRuns.get(runId) };
    },
    getCollaboratorPermissionLevel: async () => ({ data: { permission: 'write' } }),
    getPullRequest: async () => {
      const current = pullRequestSequence[Math.min(pullRequestReadIndex, pullRequestSequence.length - 1)];
      pullRequestReadIndex += 1;
      return { data: current };
    },
    listComments: async () => {},
    listFiles: async () => {},
    listLabelsOnIssue: async () => {},
    listWorkflowRuns: async () => {},
    listWorkflowRunsForRepo: async () => {},
    removeLabel: async () => {},
    createReaction: async ({ content }) => calls.reactions.push(content),
  };
  const github = {
    paginate: async (endpoint, options = {}) => {
      if (endpoint === endpoints.listComments) {
        return serializationCompleted ? comments : [];
      }
      if (endpoint === endpoints.listFiles) return files || [{ filename: 'app/models/example.rb' }];
      if (endpoint === endpoints.listLabelsOnIssue) return labels.map((name) => ({ name }));
      if (endpoint === endpoints.listWorkflowRuns) {
        assert.equal(options.workflow_id, 'ci-commands.yml');
        assert.equal(options.event, 'issue_comment');
        if (serializationRunListError) throw serializationRunListError;
        const snapshot =
          ciCommandRunSnapshots[Math.min(serializationSnapshotIndex, ciCommandRunSnapshots.length - 1)] || [];
        serializationSnapshotIndex += 1;
        serializationCompleted = !snapshot.some(
          (run) =>
            run.id < 100 && ['in_progress', 'queued', 'requested', 'waiting', 'pending'].includes(run.status),
        );
        return snapshot;
      }
      if (endpoint === endpoints.listWorkflowRunsForRepo) {
        if (runListError) throw runListError;
        return serializationCompleted ? runs : [];
      }
      throw new Error('unexpected paginated endpoint');
    },
    rest: {
      actions: {
        createWorkflowDispatch: endpoints.createWorkflowDispatch,
        getWorkflowRun: endpoints.getWorkflowRun,
        listWorkflowRuns: endpoints.listWorkflowRuns,
        listWorkflowRunsForRepo: endpoints.listWorkflowRunsForRepo,
      },
      issues: {
        addLabels: endpoints.addLabels,
        createComment: endpoints.createComment,
        createLabel: endpoints.createLabel,
        listComments: endpoints.listComments,
        listLabelsOnIssue: endpoints.listLabelsOnIssue,
        removeLabel: endpoints.removeLabel,
      },
      pulls: {
        get: endpoints.getPullRequest,
        listFiles: endpoints.listFiles,
      },
      reactions: { createForIssueComment: endpoints.createReaction },
      repos: { getCollaboratorPermissionLevel: endpoints.getCollaboratorPermissionLevel },
    },
  };
  github.paginate.iterator = async function* paginateIterator(endpoint) {
    if (endpoint !== endpoints.listComments) throw new Error('unexpected iterator endpoint');
    yield { data: comments };
  };
  const context = {
    actor: 'maintainer',
    issue: { number: 42 },
    payload: {
      comment: {
        body,
        created_at: '2026-07-16T08:00:00Z',
        id: 100,
      },
    },
    repo: { owner: 'shakacode', repo: 'react_on_rails' },
    runId: 100,
  };
  const core = {
    setFailed: (message) => calls.failures.push(message),
    warning: () => {},
  };

  const originalSetTimeout = global.setTimeout;
  const originalDateNow = Date.now;
  global.setTimeout = (callback) => {
    callback();
    return 0;
  };
  if (nowMs !== undefined) Date.now = () => nowMs;
  try {
    await executeWorkflow(github, context, core);
  } finally {
    global.setTimeout = originalSetTimeout;
    Date.now = originalDateNow;
  }
  return calls;
}

test('+ci-status reports automatic exact-head release-target coverage', async () => {
  const runs = hostedWorkflowFiles.map((workflowFile, index) => ({
    conclusion: index === 0 ? null : 'success',
    event: 'pull_request',
    head_sha: 'current-head-sha',
    path: `.github/workflows/${workflowFile}`,
    pull_requests: currentPullRequestAssociation(),
    status: index === 0 ? 'in_progress' : 'completed',
  }));

  const calls = await runCommand({ body: '+ci-status', runs });
  const statusComment = calls.comments.at(-1);

  assert.match(statusComment, /Automatic release-target hosted mode: active/);
  assert.match(statusComment, /Observed exact-head coverage:/);
  assert.doesNotMatch(statusComment, /Only the required gate is active/);

  const marker = coverageMarkerFrom(statusComment);
  assert.equal(marker.head_sha, 'current-head-sha');
  assert.equal(marker.requested_mode, 'status');
  assert.equal(marker.automatic_release_target, true);
  assert.equal(marker.observed.length, 9);
  assert.ok(marker.observed.every((workflow) => workflow.mode === 'release-full'));
});

test('+ci-run-hosted skips equivalent automatic exact-head release coverage', async () => {
  const runs = hostedWorkflowFiles.map((workflowFile, index) => ({
    conclusion: index === 0 ? null : 'success',
    event: 'pull_request',
    head_sha: 'current-head-sha',
    path: `.github/workflows/${workflowFile}`,
    pull_requests: currentPullRequestAssociation(),
    status: index === 0 ? 'queued' : 'completed',
  }));

  const calls = await runCommand({ body: '+ci-run-hosted', runs });

  assert.equal(calls.dispatches.length, 0);
  assert.deepEqual(calls.reactions, ['eyes']);
  assert.ok(calls.labels.includes('ready-for-hosted-ci'));
  assert.match(calls.comments.at(-1), /Skipped 9 workflow\(s\) with equivalent exact-head coverage/);
});

test('+ci-run-hosted does not reuse detector-only pull_request shells', async () => {
  const pullRequest = defaultPullRequest();
  pullRequest.base.ref = 'main';
  const runs = hostedWorkflowFiles.map((workflowFile) => ({
    conclusion: 'success',
    event: 'pull_request',
    head_sha: 'current-head-sha',
    path: `.github/workflows/${workflowFile}`,
    status: 'completed',
  }));

  const calls = await runCommand({ body: '+ci-run-hosted', pullRequest, runs });

  assert.equal(calls.dispatches.length, 9);
  assert.match(calls.comments.at(-1), /Triggered 9 workflow\(s\)/);
});

test('a simultaneous same-head command waits for the older command proof before dispatching', async () => {
  const pullRequest = defaultPullRequest();
  pullRequest.base.ref = 'main';
  const runIds = Object.fromEntries(
    hostedWorkflowFiles.map((workflowFile, index) => [workflowFile, 500 + index]),
  );
  const priorProof = {
    body: `<!-- hosted-ci-coverage:v1 ${JSON.stringify({
      head_sha: 'current-head-sha',
      pull_request_number: 42,
      base_ref: 'main',
      base_sha: 'base-sha',
      requested_mode: 'optimized',
      requested_at: '2026-07-16T08:00:00Z',
      workflows: hostedWorkflowFiles,
      run_ids: runIds,
    })} -->`,
    created_at: '2026-07-16T08:00:30Z',
    id: 90,
    user: { login: 'github-actions[bot]', type: 'Bot' },
  };
  const completedRuns = hostedWorkflowFiles.map((workflowFile, index) => ({
    conclusion: 'success',
    event: 'workflow_dispatch',
    head_sha: 'current-head-sha',
    id: 500 + index,
    path: `.github/workflows/${workflowFile}`,
    status: 'completed',
  }));
  const olderCommandRun = {
    event: 'issue_comment',
    id: 99,
    path: '.github/workflows/ci-commands.yml',
  };

  const calls = await runCommand({
    body: '+ci-run-hosted',
    ciCommandRunSnapshots: [
      [{ ...olderCommandRun, status: 'in_progress' }],
      [{ ...olderCommandRun, status: 'completed' }],
    ],
    comments: [priorProof],
    pullRequest,
    runs: completedRuns,
  });

  assert.equal(calls.dispatches.length, 0);
  assert.match(calls.comments.at(-1), /Skipped 9 workflow\(s\) with equivalent exact-head coverage/);
});

test('a force-full command waits for older optimized coverage without treating it as force-full', async () => {
  const pullRequest = defaultPullRequest();
  pullRequest.base.ref = 'main';
  const runIds = Object.fromEntries(
    hostedWorkflowFiles.map((workflowFile, index) => [workflowFile, 500 + index]),
  );
  const priorProof = {
    body: `<!-- hosted-ci-coverage:v1 ${JSON.stringify({
      head_sha: 'current-head-sha',
      pull_request_number: 42,
      base_ref: 'main',
      base_sha: 'base-sha',
      requested_mode: 'optimized',
      requested_at: '2026-07-16T08:00:00Z',
      workflows: hostedWorkflowFiles,
      run_ids: runIds,
    })} -->`,
    created_at: '2026-07-16T08:00:30Z',
    id: 90,
    user: { login: 'github-actions[bot]', type: 'Bot' },
  };
  const completedRuns = hostedWorkflowFiles.map((workflowFile, index) => ({
    conclusion: 'success',
    event: 'workflow_dispatch',
    head_sha: 'current-head-sha',
    id: 500 + index,
    path: `.github/workflows/${workflowFile}`,
    status: 'completed',
  }));
  const olderCommandRun = {
    event: 'issue_comment',
    id: 99,
    path: '.github/workflows/ci-commands.yml',
  };

  const calls = await runCommand({
    body: '+ci-force-full',
    ciCommandRunSnapshots: [
      [{ ...olderCommandRun, status: 'in_progress' }],
      [{ ...olderCommandRun, status: 'completed' }],
    ],
    comments: [priorProof],
    pullRequest,
    runs: completedRuns,
  });

  assert.equal(calls.dispatches.length, 9);
  assert.match(calls.comments.at(-1), /Mode: force-full hosted CI/);
});

test('hosted dispatch fails closed when older CI Commands state is UNKNOWN', async () => {
  const calls = await runCommand({
    body: '+ci-run-hosted',
    serializationRunListError: new Error('simulated serialization API outage'),
  });

  assert.equal(calls.dispatches.length, 0);
  assert.deepEqual(calls.failures, ['Older CI command state is UNKNOWN; dispatch stopped.']);
  assert.match(calls.comments.at(-1), /Hosted CI Command Serialization UNKNOWN/);
});

test('hosted dispatch times out rather than racing an older active CI command', async () => {
  const calls = await runCommand({
    body: '+ci-run-hosted',
    ciCommandRunSnapshots: [
      [
        {
          event: 'issue_comment',
          id: 99,
          path: '.github/workflows/ci-commands.yml',
          status: 'in_progress',
        },
      ],
    ],
  });

  assert.equal(calls.dispatches.length, 0);
  assert.deepEqual(calls.failures, ['Older CI command state is UNKNOWN; dispatch stopped.']);
  assert.match(calls.comments.at(-1), /did not finish within the bounded wait/);
});

test('+ci-force-full dispatches only force-full coverage proven missing', async () => {
  const forceFullWorkflow = hostedWorkflowFiles[0];
  const automaticRuns = hostedWorkflowFiles.map((workflowFile) => ({
    conclusion: 'success',
    event: 'pull_request',
    head_sha: 'current-head-sha',
    path: `.github/workflows/${workflowFile}`,
    status: 'completed',
  }));
  const provenForceFullRun = {
    conclusion: 'success',
    created_at: '2026-07-16T08:01:00Z',
    event: 'workflow_dispatch',
    head_sha: 'current-head-sha',
    id: 501,
    path: `.github/workflows/${forceFullWorkflow}`,
    status: 'completed',
  };
  const proof = {
    body: '<!-- hosted-ci-coverage:v1 {"head_sha":"current-head-sha","pull_request_number":42,"base_ref":"release/17.0.0","base_sha":"base-sha","requested_mode":"force-full","requested_at":"2026-07-16T08:00:30Z","workflows":["lint-js-and-ruby.yml"],"run_ids":{"lint-js-and-ruby.yml":501}} -->',
    created_at: '2026-07-16T08:01:05Z',
    id: 90,
    user: { login: 'github-actions[bot]', type: 'Bot' },
  };

  const calls = await runCommand({
    body: '+ci-force-full',
    comments: [proof],
    runs: [...automaticRuns, provenForceFullRun],
  });

  assert.equal(calls.dispatches.length, 8);
  assert.ok(calls.dispatches.every((dispatch) => dispatch.workflow_id !== forceFullWorkflow));
  const resultComment = calls.comments.at(-1);
  assert.match(resultComment, /Skipped 1 workflow\(s\) with equivalent exact-head coverage/);

  const marker = coverageMarkerFrom(resultComment);
  assert.equal(marker.pull_request_number, 42);
  assert.equal(marker.base_ref, 'release/17.0.0');
  assert.equal(marker.base_sha, 'base-sha');
  assert.equal(marker.requested_mode, 'force-full');
  assert.equal(marker.observed.length, 9);
  assert.deepEqual([...marker.dispatched].sort(), hostedWorkflowFiles.slice(1).sort());
  assert.deepEqual(marker.workflows, marker.dispatched);
  assert.deepEqual(Object.keys(marker.run_ids).sort(), hostedWorkflowFiles.slice(1).sort());
  assert.ok(calls.dispatches.every((dispatch) => !('return_run_details' in dispatch)));
  assert.ok(calls.dispatches.every((dispatch) => dispatch.headers['x-github-api-version'] === '2026-03-10'));
});

test('+ci-status records exact-head coverage API uncertainty as UNKNOWN', async () => {
  const calls = await runCommand({
    body: '+ci-status',
    runListError: new Error('simulated Actions API outage'),
  });
  const statusComment = calls.comments.at(-1);

  assert.match(statusComment, /Observed exact-head coverage: UNKNOWN/);
  const marker = coverageMarkerFrom(statusComment);
  assert.equal(marker.coverage_status, 'UNKNOWN');
  assert.deepEqual(marker.observed, []);
});

test('+ci-force-full fails closed without dispatch when exact-head coverage is UNKNOWN', async () => {
  const calls = await runCommand({
    body: '+ci-force-full',
    runListError: new Error('simulated Actions API outage'),
  });

  assert.equal(calls.dispatches.length, 0);
  assert.deepEqual(calls.failures, ['Exact-head hosted CI coverage is UNKNOWN; dispatch stopped.']);
  const resultComment = calls.comments.at(-1);
  assert.match(resultComment, /No workflows were dispatched/);
  const marker = coverageMarkerFrom(resultComment);
  assert.equal(marker.requested_mode, 'force-full');
  assert.equal(marker.coverage_status, 'UNKNOWN');
  assert.deepEqual(marker.dispatched, []);
});

test('+ci-run-hosted fails closed when dispatch does not return exact run details', async () => {
  const calls = await runCommand({
    body: '+ci-run-hosted',
    dispatchReturnsNoRunDetails: true,
  });

  assert.equal(calls.dispatches.length, 9);
  assert.equal(calls.failures.length, 1);
  assert.match(calls.failures[0], /Failed to trigger: Lint JS and Ruby/);
  assert.equal(calls.labels.length, 0);
  assert.match(calls.comments.at(-1), /dispatch did not return an exact workflow run ID/);
  const marker = coverageMarkerFrom(calls.comments.at(-1));
  assert.deepEqual(marker.workflows, []);
  assert.deepEqual(marker.run_ids, {});
  assert.equal(marker.dispatch_uncertain, true);

  const priorUnknownComment = {
    body: calls.comments.at(-1),
    created_at: '2026-07-16T08:00:30Z',
    id: 90,
    user: { login: 'github-actions[bot]', type: 'Bot' },
  };
  const retryCalls = await runCommand({
    body: '+ci-run-hosted',
    comments: [priorUnknownComment],
  });
  assert.equal(retryCalls.dispatches.length, 0);
  assert.match(retryCalls.comments.at(-1), /Hosted CI Coverage UNKNOWN/);
});

test('a definitive dispatch rejection records no proof and lets a later command retry the missing workflow', async () => {
  const rejection = Object.assign(new Error('workflow is disabled'), { status: 404 });
  const calls = await runCommand({
    body: '+ci-run-hosted',
    dispatchErrors: { 'lint-js-and-ruby.yml': rejection },
  });

  assert.equal(calls.dispatches.length, 9);
  assert.equal(calls.labels.length, 0);
  assert.equal(calls.failures.length, 1);
  const resultComment = calls.comments.at(-1);
  assert.match(resultComment, /workflow is disabled/);
  const marker = coverageMarkerFrom(resultComment);
  assert.equal(marker.dispatch_uncertain, undefined);
  assert.equal(marker.workflows.includes('lint-js-and-ruby.yml'), false);
  assert.equal(marker.run_ids['lint-js-and-ruby.yml'], undefined);

  const successfulRuns = Object.entries(marker.run_ids).map(([workflowFile, runId]) => ({
    event: 'workflow_dispatch',
    head_sha: 'current-head-sha',
    id: runId,
    path: `.github/workflows/${workflowFile}`,
    status: 'queued',
  }));
  const priorProof = {
    body: resultComment,
    created_at: '2026-07-16T08:00:30Z',
    id: 90,
    user: { login: 'github-actions[bot]', type: 'Bot' },
  };
  const retryCalls = await runCommand({
    body: '+ci-run-hosted',
    comments: [priorProof],
    runs: successfulRuns,
  });

  assert.deepEqual(
    retryCalls.dispatches.map((dispatch) => dispatch.workflow_id),
    ['lint-js-and-ruby.yml'],
  );
});

test('a dispatch server error remains durable UNKNOWN', async () => {
  const serverError = Object.assign(new Error('service unavailable'), { status: 503 });
  const calls = await runCommand({
    body: '+ci-run-hosted',
    dispatchErrors: { 'lint-js-and-ruby.yml': serverError },
  });

  assert.equal(calls.labels.length, 0);
  assert.equal(calls.failures.length, 1);
  const resultComment = calls.comments.at(-1);
  assert.match(resultComment, /dispatch result is UNKNOWN: service unavailable/);
  const marker = coverageMarkerFrom(resultComment);
  assert.equal(marker.coverage_status, 'UNKNOWN');
  assert.equal(marker.dispatch_uncertain, true);
  assert.deepEqual(marker.uncertain_workflows, ['lint-js-and-ruby.yml']);

  const priorUnknownComment = {
    body: resultComment,
    created_at: '2026-07-16T08:00:30Z',
    id: 90,
    user: { login: 'github-actions[bot]', type: 'Bot' },
  };
  const laterStart = await runCommand({
    body: '+ci-run-hosted',
    comments: [priorUnknownComment],
  });
  assert.equal(laterStart.dispatches.length, 0);
  assert.match(laterStart.comments.at(-1), /Hosted CI Coverage UNKNOWN/);
});

test('a dispatch transport error records durable UNKNOWN and blocks later start and status guesses', async () => {
  const timeout = Object.assign(new Error('request timed out after dispatch submission'), {
    code: 'ETIMEDOUT',
  });
  const calls = await runCommand({
    body: '+ci-run-hosted',
    dispatchErrors: { 'lint-js-and-ruby.yml': timeout },
  });

  assert.equal(calls.dispatches.length, 9);
  assert.equal(calls.labels.length, 0);
  assert.equal(calls.failures.length, 1);
  const resultComment = calls.comments.at(-1);
  assert.match(resultComment, /dispatch result is UNKNOWN: request timed out/);
  const marker = coverageMarkerFrom(resultComment);
  assert.equal(marker.dispatch_uncertain, true);
  assert.deepEqual(marker.uncertain_workflows, ['lint-js-and-ruby.yml']);

  const priorUnknownComment = {
    body: resultComment,
    created_at: '2026-07-16T08:00:30Z',
    id: 90,
    user: { login: 'github-actions[bot]', type: 'Bot' },
  };
  const laterStart = await runCommand({
    body: '+ci-force-full',
    comments: [priorUnknownComment],
  });
  assert.equal(laterStart.dispatches.length, 0);
  assert.match(laterStart.comments.at(-1), /Hosted CI Coverage UNKNOWN/);

  const laterStatus = await runCommand({
    body: '+ci-status',
    comments: [priorUnknownComment],
  });
  assert.equal(laterStatus.dispatches.length, 0);
  assert.match(laterStatus.comments.at(-1), /Observed exact-head coverage: UNKNOWN/);
  assert.equal(coverageMarkerFrom(laterStatus.comments.at(-1)).coverage_status, 'UNKNOWN');
});

test('hosted dispatch stops when the PR head changes after the coverage snapshot', async () => {
  const initialPullRequest = defaultPullRequest();
  const pushedPullRequest = structuredClone(initialPullRequest);
  pushedPullRequest.head.sha = 'pushed-head-sha';

  const calls = await runCommand({
    body: '+ci-run-hosted',
    pullRequests: [initialPullRequest, pushedPullRequest],
  });

  assert.equal(calls.dispatches.length, 0);
  assert.equal(calls.labels.length, 0);
  assert.deepEqual(calls.failures, ['Pull request changed during hosted CI planning; dispatch stopped.']);
  assert.match(calls.comments.at(-1), /Pull Request Changed/);
});

test('hosted dispatch stops when the PR base changes after the coverage snapshot', async () => {
  const initialPullRequest = defaultPullRequest();
  const retargetedPullRequest = structuredClone(initialPullRequest);
  retargetedPullRequest.base = { ref: 'release/17.1.0', sha: 'retargeted-base-sha' };

  const calls = await runCommand({
    body: '+ci-force-full',
    pullRequests: [initialPullRequest, retargetedPullRequest],
  });

  assert.equal(calls.dispatches.length, 0);
  assert.equal(calls.labels.length, 0);
  assert.deepEqual(calls.failures, ['Pull request changed during hosted CI planning; dispatch stopped.']);
  assert.match(calls.comments.at(-1), /Pull Request Changed/);
});

test('hosted dispatch rejects a returned run that is not bound to the expected head', async () => {
  const calls = await runCommand({
    body: '+ci-run-hosted',
    dispatchedRunOverrides: {
      'lint-js-and-ruby.yml': { head_sha: 'unexpected-head-sha' },
    },
  });

  assert.equal(calls.dispatches.length, 9);
  assert.equal(calls.workflowRunReads.length, 9);
  assert.equal(calls.workflowRunReads.filter((runId) => runId === 1001).length, 1);
  assert.equal(calls.labels.length, 0);
  assert.match(calls.comments.at(-1), /returned run did not match the expected workflow and head/);
  const marker = coverageMarkerFrom(calls.comments.at(-1));
  assert.equal(marker.dispatch_uncertain, true);
  assert.deepEqual(marker.uncertain_workflows, ['lint-js-and-ruby.yml']);
});

test('hosted dispatch retries a newly returned run that is briefly not visible', async () => {
  const notVisible = Object.assign(new Error('workflow run is not visible yet'), { status: 404 });
  const calls = await runCommand({
    body: '+ci-run-hosted',
    workflowRunReadFailures: { 'lint-js-and-ruby.yml': [notVisible] },
  });

  assert.equal(calls.workflowRunReads.filter((runId) => runId === 1001).length, 2);
  assert.deepEqual(calls.failures, []);
  assert.ok(calls.labels.includes('ready-for-hosted-ci'));
  const marker = coverageMarkerFrom(calls.comments.at(-1));
  assert.equal(marker.dispatch_uncertain, undefined);
  assert.equal(marker.workflows.length, 9);
});

test('hosted dispatch records durable UNKNOWN after exact-run visibility retries are exhausted', async () => {
  const notVisible = () => Object.assign(new Error('workflow run is not visible yet'), { status: 404 });
  const calls = await runCommand({
    body: '+ci-run-hosted',
    workflowRunReadFailures: {
      'lint-js-and-ruby.yml': [notVisible(), notVisible(), notVisible()],
    },
  });

  assert.equal(calls.workflowRunReads.filter((runId) => runId === 1001).length, 3);
  assert.equal(calls.labels.length, 0);
  const marker = coverageMarkerFrom(calls.comments.at(-1));
  assert.equal(marker.dispatch_uncertain, true);
  assert.deepEqual(marker.uncertain_workflows, ['lint-js-and-ruby.yml']);
});

test('hosted dispatch rejects a returned run with the wrong event', async () => {
  const calls = await runCommand({
    body: '+ci-run-hosted',
    dispatchedRunOverrides: { 'lint-js-and-ruby.yml': { event: 'pull_request' } },
  });

  assert.equal(calls.dispatches.length, 9);
  assert.equal(calls.workflowRunReads.length, 9);
  assert.equal(calls.labels.length, 0);
  const marker = coverageMarkerFrom(calls.comments.at(-1));
  assert.equal(marker.dispatch_uncertain, true);
  assert.deepEqual(marker.uncertain_workflows, ['lint-js-and-ruby.yml']);
});

test('hosted dispatch rejects a returned run with the wrong workflow path', async () => {
  const calls = await runCommand({
    body: '+ci-run-hosted',
    dispatchedRunOverrides: {
      'lint-js-and-ruby.yml': { path: '.github/workflows/package-js-tests.yml' },
    },
  });

  assert.equal(calls.dispatches.length, 9);
  assert.equal(calls.workflowRunReads.length, 9);
  assert.equal(calls.labels.length, 0);
  const marker = coverageMarkerFrom(calls.comments.at(-1));
  assert.equal(marker.dispatch_uncertain, true);
  assert.deepEqual(marker.uncertain_workflows, ['lint-js-and-ruby.yml']);
});

test('+ci-run-hosted does not reuse old-head, failed, or cancelled workflow runs', async () => {
  const staleSuccesses = hostedWorkflowFiles.map((workflowFile) => ({
    conclusion: 'success',
    event: 'pull_request',
    head_sha: 'old-head-sha',
    path: `.github/workflows/${workflowFile}`,
    status: 'completed',
  }));
  const currentFailures = [
    {
      conclusion: 'failure',
      event: 'pull_request',
      head_sha: 'current-head-sha',
      path: `.github/workflows/${hostedWorkflowFiles[0]}`,
      status: 'completed',
    },
    {
      conclusion: 'cancelled',
      event: 'pull_request',
      head_sha: 'current-head-sha',
      path: `.github/workflows/${hostedWorkflowFiles[1]}`,
      status: 'completed',
    },
  ];

  const calls = await runCommand({
    body: '+ci-run-hosted',
    runs: [...staleSuccesses, ...currentFailures],
  });

  assert.equal(calls.dispatches.length, 9);
  assert.match(calls.comments.at(-1), /Skipped 0 workflow\(s\) with equivalent exact-head coverage/);
});

test('+ci-run-hosted does not reuse dispatch coverage from an old PR base', async () => {
  const workflowFile = hostedWorkflowFiles[0];
  const oldBaseProof = {
    body: '<!-- hosted-ci-coverage:v1 {"head_sha":"current-head-sha","pull_request_number":42,"base_ref":"main","base_sha":"old-base-sha","requested_mode":"optimized","requested_at":"2026-07-16T08:00:00Z","workflows":["lint-js-and-ruby.yml"],"run_ids":{"lint-js-and-ruby.yml":501}} -->',
    created_at: '2026-07-16T08:00:30Z',
    id: 90,
    user: { login: 'github-actions[bot]', type: 'Bot' },
  };
  const oldBaseRun = {
    conclusion: 'success',
    created_at: '2026-07-16T08:00:10Z',
    event: 'workflow_dispatch',
    head_sha: 'current-head-sha',
    id: 501,
    path: `.github/workflows/${workflowFile}`,
    status: 'completed',
  };

  const calls = await runCommand({
    body: '+ci-run-hosted',
    comments: [oldBaseProof],
    runs: [oldBaseRun],
  });

  assert.equal(calls.dispatches.length, 9);
  assert.match(calls.comments.at(-1), /Skipped 0 workflow\(s\)/);
});

test('+ci-force-full retries a force-full proof whose exact-head run was cancelled', async () => {
  const automaticRuns = hostedWorkflowFiles.map((workflowFile) => ({
    conclusion: 'success',
    event: 'pull_request',
    head_sha: 'current-head-sha',
    path: `.github/workflows/${workflowFile}`,
    status: 'completed',
  }));
  const proof = {
    body: '<!-- hosted-ci-coverage:v1 {"head_sha":"current-head-sha","pull_request_number":42,"base_ref":"release/17.0.0","base_sha":"base-sha","requested_mode":"force-full","requested_at":"2026-07-16T08:00:30Z","workflows":["lint-js-and-ruby.yml"],"run_ids":{"lint-js-and-ruby.yml":501}} -->',
    created_at: '2026-07-16T08:01:05Z',
    id: 90,
    user: { login: 'github-actions[bot]', type: 'Bot' },
  };
  const cancelledForceFullRun = {
    conclusion: 'cancelled',
    created_at: '2026-07-16T08:01:00Z',
    event: 'workflow_dispatch',
    head_sha: 'current-head-sha',
    id: 501,
    path: `.github/workflows/${hostedWorkflowFiles[0]}`,
    status: 'completed',
  };

  const calls = await runCommand({
    body: '+ci-force-full',
    comments: [proof],
    runs: [...automaticRuns, cancelledForceFullRun],
  });

  assert.equal(calls.dispatches.length, 9);
  assert.ok(calls.dispatches.some((dispatch) => dispatch.workflow_id === hostedWorkflowFiles[0]));
});

test('a later optimized success does not satisfy an earlier failed force-full proof', async () => {
  const workflowFile = hostedWorkflowFiles[0];
  const forceFullProof = {
    body: '<!-- hosted-ci-coverage:v1 {"head_sha":"current-head-sha","pull_request_number":42,"base_ref":"release/17.0.0","base_sha":"base-sha","requested_mode":"force-full","requested_at":"2026-07-16T08:00:30Z","workflows":["lint-js-and-ruby.yml"],"run_ids":{"lint-js-and-ruby.yml":501}} -->',
    created_at: '2026-07-16T08:01:05Z',
    id: 90,
    user: { login: 'github-actions[bot]', type: 'Bot' },
  };
  const optimizedProof = {
    body: '<!-- hosted-ci-coverage:v1 {"head_sha":"current-head-sha","pull_request_number":42,"base_ref":"release/17.0.0","base_sha":"base-sha","requested_mode":"optimized","requested_at":"2026-07-16T08:02:00Z","workflows":["lint-js-and-ruby.yml"],"run_ids":{"lint-js-and-ruby.yml":502}} -->',
    created_at: '2026-07-16T08:02:35Z',
    id: 91,
    user: { login: 'github-actions[bot]', type: 'Bot' },
  };
  const automaticRuns = hostedWorkflowFiles.map((file) => ({
    conclusion: 'success',
    event: 'pull_request',
    head_sha: 'current-head-sha',
    path: `.github/workflows/${file}`,
    status: 'completed',
  }));
  const failedForceFullRun = {
    conclusion: 'cancelled',
    created_at: '2026-07-16T08:01:00Z',
    event: 'workflow_dispatch',
    head_sha: 'current-head-sha',
    id: 501,
    path: `.github/workflows/${workflowFile}`,
    status: 'completed',
  };
  const successfulOptimizedRun = {
    conclusion: 'success',
    created_at: '2026-07-16T08:02:30Z',
    event: 'workflow_dispatch',
    head_sha: 'current-head-sha',
    id: 502,
    path: `.github/workflows/${workflowFile}`,
    status: 'completed',
  };

  const calls = await runCommand({
    body: '+ci-force-full',
    comments: [forceFullProof, optimizedProof],
    runs: [...automaticRuns, failedForceFullRun, successfulOptimizedRun],
  });

  assert.equal(calls.dispatches.length, 9);
  assert.ok(calls.dispatches.some((dispatch) => dispatch.workflow_id === workflowFile));
});

test('a late optimized run does not satisfy a newer failed force-full proof', async () => {
  const workflowFile = hostedWorkflowFiles[0];
  const optimizedProof = {
    body: '<!-- hosted-ci-coverage:v1 {"head_sha":"current-head-sha","pull_request_number":42,"base_ref":"release/17.0.0","base_sha":"base-sha","requested_mode":"optimized","requested_at":"2026-07-16T08:00:00Z","workflows":["lint-js-and-ruby.yml"],"run_ids":{"lint-js-and-ruby.yml":501}} -->',
    created_at: '2026-07-16T08:00:30Z',
    id: 90,
    user: { login: 'github-actions[bot]', type: 'Bot' },
  };
  const forceFullProof = {
    body: '<!-- hosted-ci-coverage:v1 {"head_sha":"current-head-sha","pull_request_number":42,"base_ref":"release/17.0.0","base_sha":"base-sha","requested_mode":"force-full","requested_at":"2026-07-16T08:01:00Z","workflows":["lint-js-and-ruby.yml"],"run_ids":{"lint-js-and-ruby.yml":502}} -->',
    created_at: '2026-07-16T08:01:30Z',
    id: 91,
    user: { login: 'github-actions[bot]', type: 'Bot' },
  };
  const lateOptimizedSuccess = {
    conclusion: 'success',
    created_at: '2026-07-16T08:01:10Z',
    event: 'workflow_dispatch',
    head_sha: 'current-head-sha',
    id: 501,
    path: `.github/workflows/${workflowFile}`,
    status: 'completed',
  };
  const failedForceFullRun = {
    conclusion: 'cancelled',
    created_at: '2026-07-16T08:01:20Z',
    event: 'workflow_dispatch',
    head_sha: 'current-head-sha',
    id: 502,
    path: `.github/workflows/${workflowFile}`,
    status: 'completed',
  };

  const calls = await runCommand({
    body: '+ci-force-full',
    comments: [optimizedProof, forceFullProof],
    runs: [lateOptimizedSuccess, failedForceFullRun],
  });

  assert.equal(calls.dispatches.length, 9);
  assert.ok(calls.dispatches.some((dispatch) => dispatch.workflow_id === workflowFile));
});

test('exact run IDs separate same-second optimized and force-full requests', async () => {
  const workflowFile = hostedWorkflowFiles[0];
  const optimizedProof = {
    body: '<!-- hosted-ci-coverage:v1 {"head_sha":"current-head-sha","pull_request_number":42,"base_ref":"release/17.0.0","base_sha":"base-sha","requested_mode":"optimized","requested_at":"2026-07-16T08:00:00Z","workflows":["lint-js-and-ruby.yml"],"run_ids":{"lint-js-and-ruby.yml":501}} -->',
    created_at: '2026-07-16T08:00:30Z',
    id: 90,
    user: { login: 'github-actions[bot]', type: 'Bot' },
  };
  const forceFullProof = {
    body: '<!-- hosted-ci-coverage:v1 {"head_sha":"current-head-sha","pull_request_number":42,"base_ref":"release/17.0.0","base_sha":"base-sha","requested_mode":"force-full","requested_at":"2026-07-16T08:00:00Z","workflows":["lint-js-and-ruby.yml"],"run_ids":{"lint-js-and-ruby.yml":502}} -->',
    created_at: '2026-07-16T08:00:30Z',
    id: 91,
    user: { login: 'github-actions[bot]', type: 'Bot' },
  };
  const runs = [
    {
      conclusion: 'success',
      created_at: '2026-07-16T08:00:10Z',
      event: 'workflow_dispatch',
      head_sha: 'current-head-sha',
      id: 501,
      path: `.github/workflows/${workflowFile}`,
      status: 'completed',
    },
    {
      conclusion: 'cancelled',
      created_at: '2026-07-16T08:00:20Z',
      event: 'workflow_dispatch',
      head_sha: 'current-head-sha',
      id: 502,
      path: `.github/workflows/${workflowFile}`,
      status: 'completed',
    },
  ];

  const calls = await runCommand({
    body: '+ci-force-full',
    comments: [optimizedProof, forceFullProof],
    runs,
  });

  assert.equal(calls.dispatches.length, 9);
});

test('the newer same-second proof wins within one request mode', async () => {
  const workflowFile = hostedWorkflowFiles[0];
  const successfulProof = {
    body: '<!-- hosted-ci-coverage:v1 {"head_sha":"current-head-sha","pull_request_number":42,"base_ref":"release/17.0.0","base_sha":"base-sha","requested_mode":"optimized","requested_at":"2026-07-16T08:00:00Z","workflows":["lint-js-and-ruby.yml"],"run_ids":{"lint-js-and-ruby.yml":501}} -->',
    created_at: '2026-07-16T08:00:30Z',
    id: 90,
    user: { login: 'github-actions[bot]', type: 'Bot' },
  };
  const failedProof = {
    body: '<!-- hosted-ci-coverage:v1 {"head_sha":"current-head-sha","pull_request_number":42,"base_ref":"release/17.0.0","base_sha":"base-sha","requested_mode":"optimized","requested_at":"2026-07-16T08:00:00Z","workflows":["lint-js-and-ruby.yml"],"run_ids":{"lint-js-and-ruby.yml":502}} -->',
    created_at: '2026-07-16T08:00:30Z',
    id: 91,
    user: { login: 'github-actions[bot]', type: 'Bot' },
  };
  const runs = [
    {
      conclusion: 'success',
      event: 'workflow_dispatch',
      head_sha: 'current-head-sha',
      id: 501,
      path: `.github/workflows/${workflowFile}`,
      status: 'completed',
    },
    {
      conclusion: 'cancelled',
      event: 'workflow_dispatch',
      head_sha: 'current-head-sha',
      id: 502,
      path: `.github/workflows/${workflowFile}`,
      status: 'completed',
    },
  ];

  const calls = await runCommand({
    body: '+ci-run-hosted',
    comments: [successfulProof, failedProof],
    runs,
  });

  assert.equal(calls.dispatches.length, 9);
});

test('a proof whose exact run is absent does not suppress a retry', async () => {
  const proof = {
    body: '<!-- hosted-ci-coverage:v1 {"head_sha":"current-head-sha","pull_request_number":42,"base_ref":"release/17.0.0","base_sha":"base-sha","requested_mode":"force-full","requested_at":"2026-07-16T08:00:00Z","workflows":["lint-js-and-ruby.yml"],"run_ids":{"lint-js-and-ruby.yml":502}} -->',
    created_at: '2026-07-16T08:00:30Z',
    id: 90,
    user: { login: 'github-actions[bot]', type: 'Bot' },
  };

  const calls = await runCommand({ body: '+ci-force-full', comments: [proof] });

  assert.equal(calls.dispatches.length, 9);
});

test('a delayed command gives its just-completed dispatch proof the full visibility grace period', async () => {
  const dispatchCompletedAt = '2026-07-16T08:05:00.000Z';
  const firstCalls = await runCommand({
    body: '+ci-run-hosted',
    nowMs: Date.parse(dispatchCompletedAt),
  });
  const resultComment = firstCalls.comments.at(-1);
  const marker = coverageMarkerFrom(resultComment);

  assert.equal(marker.requested_at, dispatchCompletedAt);
  assert.equal(firstCalls.dispatches.length, 9);

  const priorProof = {
    body: resultComment,
    created_at: dispatchCompletedAt,
    id: 90,
    user: { login: 'github-actions[bot]', type: 'Bot' },
  };
  const repeatedCalls = await runCommand({
    body: '+ci-run-hosted',
    comments: [priorProof],
    nowMs: Date.parse(dispatchCompletedAt),
  });

  assert.equal(repeatedCalls.dispatches.length, 0);
  assert.match(repeatedCalls.comments.at(-1), /Skipped 9 workflow\(s\) with equivalent exact-head coverage/);
});

test('a just-created future-skewed proof remains pending without duplicate dispatches', async () => {
  const nowMs = Date.parse('2026-07-16T08:05:00.000Z');
  const requestedAt = '2026-07-16T08:05:30.000Z';
  const runIds = Object.fromEntries(
    hostedWorkflowFiles.map((workflowFile, index) => [workflowFile, 700 + index]),
  );
  const proof = {
    body: `<!-- hosted-ci-coverage:v1 ${JSON.stringify({
      head_sha: 'current-head-sha',
      pull_request_number: 42,
      base_ref: 'release/17.0.0',
      base_sha: 'base-sha',
      requested_mode: 'force-full',
      requested_at: requestedAt,
      workflows: hostedWorkflowFiles,
      run_ids: runIds,
    })} -->`,
    created_at: requestedAt,
    id: 90,
    user: { login: 'github-actions[bot]', type: 'Bot' },
  };

  const calls = await runCommand({
    body: '+ci-force-full',
    comments: [proof],
    nowMs,
  });

  assert.equal(calls.dispatches.length, 0);
  assert.match(calls.comments.at(-1), /Skipped 9 workflow\(s\) with equivalent exact-head coverage/);
});

test('a newly recorded exact run ID gets a bounded visibility grace period', async () => {
  const requestedAt = new Date().toISOString();
  const proof = {
    body: `<!-- hosted-ci-coverage:v1 ${JSON.stringify({
      head_sha: 'current-head-sha',
      pull_request_number: 42,
      base_ref: 'release/17.0.0',
      base_sha: 'base-sha',
      requested_mode: 'force-full',
      requested_at: requestedAt,
      workflows: ['lint-js-and-ruby.yml'],
      run_ids: { 'lint-js-and-ruby.yml': 502 },
    })} -->`,
    created_at: requestedAt,
    id: 90,
    user: { login: 'github-actions[bot]', type: 'Bot' },
  };

  const calls = await runCommand({ body: '+ci-force-full', comments: [proof] });

  assert.equal(calls.dispatches.length, 8);
  assert.ok(calls.dispatches.every((dispatch) => dispatch.workflow_id !== 'lint-js-and-ruby.yml'));
});

test('Dependabot release-target selector shells do not satisfy hosted coverage', async () => {
  const dependabotPr = defaultPullRequest();
  dependabotPr.user.login = 'dependabot[bot]';
  const dependabotRuns = hostedWorkflowFiles.slice(0, 7).map((workflowFile) => ({
    conclusion: 'success',
    event: 'pull_request',
    head_sha: 'current-head-sha',
    path: `.github/workflows/${workflowFile}`,
    status: 'completed',
  }));

  const calls = await runCommand({
    body: '+ci-run-hosted',
    pullRequest: dependabotPr,
    runs: dependabotRuns,
  });

  assert.equal(calls.dispatches.length, 7);
  assert.match(calls.comments.at(-1), /Triggered 7 workflow\(s\)/);
});

test('+ci-status does not report pre-trust Dependabot release mode as automatic coverage', async () => {
  const dependabotPr = defaultPullRequest();
  dependabotPr.user.login = 'dependabot[bot]';

  const calls = await runCommand({ body: '+ci-status', pullRequest: dependabotPr });

  assert.match(calls.comments.at(-1), /Automatic release-target hosted mode: inactive/);
});

test('repeated all-covered Dependabot command preserves a nonzero trusted dispatch proof', async () => {
  const dependabotPr = defaultPullRequest();
  dependabotPr.user.login = 'dependabot[bot]';
  const dependabotWorkflowFiles = hostedWorkflowFiles.slice(0, 7);
  const priorProof = {
    body: `<!-- hosted-ci-coverage:v1 ${JSON.stringify({
      head_sha: 'current-head-sha',
      pull_request_number: 42,
      base_ref: 'release/17.0.0',
      base_sha: 'base-sha',
      requested_mode: 'optimized',
      requested_at: '2026-07-16T07:59:00Z',
      workflows: dependabotWorkflowFiles,
      run_ids: Object.fromEntries(
        dependabotWorkflowFiles.map((workflowFile, index) => [workflowFile, 700 + index]),
      ),
    })} -->`,
    created_at: '2026-07-16T07:59:30Z',
    id: 90,
    user: { login: 'github-actions[bot]', type: 'Bot' },
  };
  const completedRuns = dependabotWorkflowFiles.map((workflowFile, index) => ({
    conclusion: 'success',
    created_at: '2026-07-16T07:59:10Z',
    event: 'workflow_dispatch',
    head_sha: 'current-head-sha',
    id: 700 + index,
    path: `.github/workflows/${workflowFile}`,
    status: 'completed',
  }));

  const calls = await runCommand({
    body: '+ci-run-hosted',
    comments: [priorProof],
    pullRequest: dependabotPr,
    runs: completedRuns,
  });

  assert.equal(calls.dispatches.length, 0);
  assert.match(calls.comments.at(-1), /Triggered [1-9][0-9]* workflow\(s\) for `current-head`/);
  assert.deepEqual(coverageMarkerFrom(calls.comments.at(-1)).reused, dependabotWorkflowFiles);
});

test('fork safety and one-command parsing remain intact', async () => {
  const forkPr = defaultPullRequest();
  forkPr.head.repo.full_name = 'external/fork';
  const forkCalls = await runCommand({ body: '+ci-run-hosted', pullRequest: forkPr });
  assert.equal(forkCalls.dispatches.length, 0);
  assert.match(forkCalls.comments.at(-1), /PR branch is from a fork/);

  const statusRuns = hostedWorkflowFiles.map((workflowFile) => ({
    conclusion: 'success',
    event: 'pull_request',
    head_sha: 'current-head-sha',
    path: `.github/workflows/${workflowFile}`,
    status: 'completed',
  }));
  const oneCommandCalls = await runCommand({
    body: '+ci-status\n+ci-force-full',
    runs: statusRuns,
  });
  assert.equal(oneCommandCalls.dispatches.length, 0);
  assert.match(oneCommandCalls.comments.at(-1), /^## CI Status/);
});

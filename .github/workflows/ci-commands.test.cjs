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

async function runCommand({ body, comments = [], files, labels = [], pullRequest, runListError, runs = [] }) {
  const calls = {
    comments: [],
    dispatches: [],
    failures: [],
    labels: [],
    reactions: [],
  };
  const pr = pullRequest || defaultPullRequest();
  const endpoints = {
    addLabels: async ({ labels: addedLabels }) => calls.labels.push(...addedLabels),
    createComment: async ({ body: commentBody }) => calls.comments.push(commentBody),
    createLabel: async () => {},
    createWorkflowDispatch: async (options) => calls.dispatches.push(options),
    getCollaboratorPermissionLevel: async () => ({ data: { permission: 'write' } }),
    getPullRequest: async () => ({ data: pr }),
    listComments: async () => {},
    listFiles: async () => {},
    listLabelsOnIssue: async () => {},
    listWorkflowRunsForRepo: async () => {},
    removeLabel: async () => {},
    createReaction: async ({ content }) => calls.reactions.push(content),
  };
  const github = {
    paginate: async (endpoint) => {
      if (endpoint === endpoints.listComments) return comments;
      if (endpoint === endpoints.listFiles) return files || [{ filename: 'app/models/example.rb' }];
      if (endpoint === endpoints.listLabelsOnIssue) return labels.map((name) => ({ name }));
      if (endpoint === endpoints.listWorkflowRunsForRepo) {
        if (runListError) throw runListError;
        return runs;
      }
      throw new Error('unexpected paginated endpoint');
    },
    rest: {
      actions: {
        createWorkflowDispatch: endpoints.createWorkflowDispatch,
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
  };
  const core = {
    setFailed: (message) => calls.failures.push(message),
    warning: () => {},
  };

  const originalSetTimeout = global.setTimeout;
  global.setTimeout = (callback) => {
    callback();
    return 0;
  };
  try {
    await executeWorkflow(github, context, core);
  } finally {
    global.setTimeout = originalSetTimeout;
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
    path: `.github/workflows/${forceFullWorkflow}`,
    status: 'completed',
  };
  const proof = {
    body: '<!-- hosted-ci-coverage:v1 {"head_sha":"current-head-sha","pull_request_number":42,"base_ref":"release/17.0.0","base_sha":"base-sha","requested_mode":"force-full","requested_at":"2026-07-16T08:00:30Z","workflows":["lint-js-and-ruby.yml"]} -->',
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
    body: '<!-- hosted-ci-coverage:v1 {"head_sha":"current-head-sha","pull_request_number":42,"base_ref":"main","base_sha":"old-base-sha","requested_mode":"optimized","requested_at":"2026-07-16T08:00:00Z","workflows":["lint-js-and-ruby.yml"]} -->',
    created_at: '2026-07-16T08:00:30Z',
    id: 90,
    user: { login: 'github-actions[bot]', type: 'Bot' },
  };
  const oldBaseRun = {
    conclusion: 'success',
    created_at: '2026-07-16T08:00:10Z',
    event: 'workflow_dispatch',
    head_sha: 'current-head-sha',
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
    body: '<!-- hosted-ci-coverage:v1 {"head_sha":"current-head-sha","pull_request_number":42,"base_ref":"release/17.0.0","base_sha":"base-sha","requested_mode":"force-full","requested_at":"2026-07-16T08:00:30Z","workflows":["lint-js-and-ruby.yml"]} -->',
    created_at: '2026-07-16T08:01:05Z',
    id: 90,
    user: { login: 'github-actions[bot]', type: 'Bot' },
  };
  const cancelledForceFullRun = {
    conclusion: 'cancelled',
    created_at: '2026-07-16T08:01:00Z',
    event: 'workflow_dispatch',
    head_sha: 'current-head-sha',
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
    body: '<!-- hosted-ci-coverage:v1 {"head_sha":"current-head-sha","pull_request_number":42,"base_ref":"release/17.0.0","base_sha":"base-sha","requested_mode":"force-full","requested_at":"2026-07-16T08:00:30Z","workflows":["lint-js-and-ruby.yml"]} -->',
    created_at: '2026-07-16T08:01:05Z',
    id: 90,
    user: { login: 'github-actions[bot]', type: 'Bot' },
  };
  const optimizedProof = {
    body: '<!-- hosted-ci-coverage:v1 {"head_sha":"current-head-sha","pull_request_number":42,"base_ref":"release/17.0.0","base_sha":"base-sha","requested_mode":"optimized","requested_at":"2026-07-16T08:02:00Z","workflows":["lint-js-and-ruby.yml"]} -->',
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
    path: `.github/workflows/${workflowFile}`,
    status: 'completed',
  };
  const successfulOptimizedRun = {
    conclusion: 'success',
    created_at: '2026-07-16T08:02:30Z',
    event: 'workflow_dispatch',
    head_sha: 'current-head-sha',
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
    body: '<!-- hosted-ci-coverage:v1 {"head_sha":"current-head-sha","pull_request_number":42,"base_ref":"release/17.0.0","base_sha":"base-sha","requested_mode":"optimized","requested_at":"2026-07-16T08:00:00Z","workflows":["lint-js-and-ruby.yml"]} -->',
    created_at: '2026-07-16T08:00:30Z',
    id: 90,
    user: { login: 'github-actions[bot]', type: 'Bot' },
  };
  const forceFullProof = {
    body: '<!-- hosted-ci-coverage:v1 {"head_sha":"current-head-sha","pull_request_number":42,"base_ref":"release/17.0.0","base_sha":"base-sha","requested_mode":"force-full","requested_at":"2026-07-16T08:01:00Z","workflows":["lint-js-and-ruby.yml"]} -->',
    created_at: '2026-07-16T08:01:30Z',
    id: 91,
    user: { login: 'github-actions[bot]', type: 'Bot' },
  };
  const lateOptimizedSuccess = {
    conclusion: 'success',
    created_at: '2026-07-16T08:01:10Z',
    event: 'workflow_dispatch',
    head_sha: 'current-head-sha',
    path: `.github/workflows/${workflowFile}`,
    status: 'completed',
  };
  const failedForceFullRun = {
    conclusion: 'cancelled',
    created_at: '2026-07-16T08:01:20Z',
    event: 'workflow_dispatch',
    head_sha: 'current-head-sha',
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
    })} -->`,
    created_at: '2026-07-16T07:59:30Z',
    id: 90,
    user: { login: 'github-actions[bot]', type: 'Bot' },
  };
  const completedRuns = dependabotWorkflowFiles.map((workflowFile) => ({
    conclusion: 'success',
    created_at: '2026-07-16T07:59:10Z',
    event: 'workflow_dispatch',
    head_sha: 'current-head-sha',
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

// Runs the Hosted CI Label Dispatch script against a fake GitHub API. ci-required does
// not run on label events, so this workflow must rerun the required gate itself.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const { test } = require('node:test');

const AsyncFunction = Object.getPrototypeOf(async function asyncFunctionPrototype() {
  return undefined;
}).constructor;

const workflowSource = fs.readFileSync('.github/workflows/hosted-ci-label-dispatch.yml', 'utf8');
const requiredSource = fs.readFileSync('.github/workflows/ci-required.yml', 'utf8');
const scriptMarker = '          script: |\n';
const scriptStart = workflowSource.indexOf(scriptMarker);
assert.notEqual(scriptStart, -1, 'hosted-ci-label-dispatch must embed a github-script');
const workflowScript = workflowSource
  .slice(scriptStart + scriptMarker.length)
  .split('\n')
  .map((line) => (line.startsWith('            ') ? line.slice(12) : line))
  .join('\n');
const runWorkflow = new AsyncFunction('github', 'context', 'core', workflowScript);

const repo = { owner: 'shakacode', repo: 'react_on_rails' };
const hostedWorkflowCount = 9;
const completedGateRun = { id: 501, status: 'completed', pull_requests: [{ number: 42 }] };

async function labelEvent({
  action,
  label,
  labelsAfter,
  actor = 'maintainer',
  permission = 'write',
  fork = false,
  author = 'maintainer',
  failingWorkflow,
  gateRunSnapshots = [[completedGateRun]],
  rerunError,
}) {
  const calls = {
    dispatches: [],
    gateRunQueries: [],
    reruns: [],
    removedLabels: [],
    comments: [],
    failed: [],
  };
  const github = {
    rest: {
      actions: {
        createWorkflowDispatch: async (options) => {
          if (options.workflow_id === failingWorkflow) {
            throw Object.assign(new Error('dispatch refused'), { status: 500 });
          }
          calls.dispatches.push(options);
        },
        listWorkflowRuns: async (options) => {
          calls.gateRunQueries.push(options);
          const snapshot =
            gateRunSnapshots[Math.min(calls.gateRunQueries.length - 1, gateRunSnapshots.length - 1)];
          return { data: { workflow_runs: snapshot } };
        },
        reRunWorkflow: async (options) => {
          if (rerunError) throw rerunError;
          calls.reruns.push(options);
        },
      },
      issues: {
        listLabelsOnIssue: async () => ({ data: labelsAfter.map((name) => ({ name })) }),
        removeLabel: async ({ name }) => {
          calls.removedLabels.push(name);
        },
        createComment: async ({ body }) => {
          calls.comments.push(body);
        },
      },
      repos: {
        getCollaboratorPermissionLevel: async () => ({ data: { permission } }),
      },
    },
  };
  const context = {
    repo,
    actor,
    payload: {
      action,
      label: { name: label },
      pull_request: {
        number: 42,
        user: { login: author },
        head: {
          ref: 'feature',
          sha: 'abcdef1234567890',
          repo: { full_name: fork ? 'someone/fork' : 'shakacode/react_on_rails' },
        },
        base: { ref: 'main', sha: 'base-sha' },
      },
    },
  };
  const core = {
    info: () => {},
    warning: () => {},
    setFailed: (message) => calls.failed.push(message),
  };
  const originalSetTimeout = global.setTimeout;
  global.setTimeout = (callback) => originalSetTimeout(callback, 0);
  try {
    await runWorkflow(github, context, core);
  } finally {
    global.setTimeout = originalSetTimeout;
  }
  for (const query of calls.gateRunQueries) {
    assert.deepEqual(query, {
      ...repo,
      workflow_id: 'ci-required.yml',
      event: 'pull_request',
      head_sha: 'abcdef1234567890',
      per_page: 20,
    });
  }
  assert.equal(
    calls.dispatches.filter((dispatch) => dispatch.workflow_id === 'ci-required.yml').length,
    0,
    'dispatched ci-required runs do not count for a PR, so the gate is rerun instead',
  );
  return calls;
}

const rerunOf = (runId) => [{ ...repo, run_id: runId }];

function evaluate(expression, github) {
  return vm.runInNewContext(expression.replace(/^\s*\$\{\{|\}\}\s*$/g, ''), { github });
}

test('ci-required does not run on label events', () => {
  const types = requiredSource.match(/^ {2}pull_request:\n {4}types: \[(.*)\]$/m);
  assert.ok(types, 'ci-required must list its pull_request types');
  assert.deepEqual(types[1].split(', '), ['opened', 'synchronize', 'reopened', 'ready_for_review']);
});

test('only hosted-CI control labels start the dispatch job', () => {
  const condition = workflowSource.match(/^ {4}if: >-\n((?: {6}.*\n)+)/m);
  assert.ok(condition, 'the dispatch job must have a job-level if');
  const expression = condition[1].trim().replace(/\s+/g, ' ');
  for (const [label, expected] of [
    ['ready-for-hosted-ci', true],
    ['force-full-hosted-ci', true],
    ['awaiting-merge-approval', false],
    ['awaiting-resume', false],
    ['hold', false],
  ]) {
    assert.equal(evaluate(expression, { event: { label: { name: label } } }), expected, label);
  }
});

test('adding a hosted-CI label dispatches hosted CI and then reruns the required gate', async () => {
  const calls = await labelEvent({
    action: 'labeled',
    label: 'ready-for-hosted-ci',
    labelsAfter: ['ready-for-hosted-ci'],
  });
  assert.equal(calls.dispatches.length, hostedWorkflowCount);
  assert.deepEqual(calls.reruns, rerunOf(501));
  assert.deepEqual(calls.failed, []);
});

test('the newest pull_request run is rerun once it finishes', async () => {
  const calls = await labelEvent({
    action: 'unlabeled',
    label: 'ready-for-hosted-ci',
    labelsAfter: [],
    gateRunSnapshots: [
      [completedGateRun, { id: 502, status: 'in_progress', pull_requests: [{ number: 42 }] }],
      [completedGateRun, { id: 502, status: 'completed', pull_requests: [{ number: 42 }] }],
    ],
  });
  assert.equal(calls.gateRunQueries.length, 2);
  assert.deepEqual(calls.reruns, rerunOf(502));
});

test('removing the last hosted-CI label reruns the required gate', async () => {
  const calls = await Promise.all(
    ['ready-for-hosted-ci', 'force-full-hosted-ci'].map((label) =>
      labelEvent({ action: 'unlabeled', label, labelsAfter: ['awaiting-resume'] }),
    ),
  );
  for (const result of calls) {
    assert.deepEqual(result.reruns, rerunOf(501));
    assert.deepEqual(result.failed, []);
  }
});

test('removing one hosted-CI label while another remains leaves the gate alone', async () => {
  const calls = await labelEvent({
    action: 'unlabeled',
    label: 'force-full-hosted-ci',
    labelsAfter: ['ready-for-hosted-ci'],
  });
  assert.deepEqual(calls.reruns, []);
  assert.deepEqual(calls.failed, []);
});

test('hosted-CI label removal on a fork reruns nothing', async () => {
  const calls = await labelEvent({
    action: 'unlabeled',
    label: 'ready-for-hosted-ci',
    labelsAfter: [],
    fork: true,
  });
  assert.deepEqual(calls.reruns, []);
  assert.deepEqual(calls.gateRunQueries, []);
});

test('a head with no pull_request run yet needs no rerun', async () => {
  const calls = await labelEvent({
    action: 'unlabeled',
    label: 'ready-for-hosted-ci',
    labelsAfter: [],
    gateRunSnapshots: [[]],
  });
  assert.deepEqual(calls.reruns, []);
  assert.deepEqual(calls.failed, []);
});

test('a failed or timed-out rerun fails the job', async () => {
  const refused = await labelEvent({
    action: 'unlabeled',
    label: 'ready-for-hosted-ci',
    labelsAfter: [],
    rerunError: Object.assign(new Error('forbidden'), { status: 403 }),
  });
  assert.equal(refused.failed.length, 1);

  const stuck = await labelEvent({
    action: 'unlabeled',
    label: 'ready-for-hosted-ci',
    labelsAfter: [],
    gateRunSnapshots: [[{ id: 502, status: 'in_progress', pull_requests: [{ number: 42 }] }]],
  });
  assert.deepEqual(stuck.reruns, []);
  assert.equal(stuck.failed.length, 1);
});

test('untrusted, Dependabot, and failed hosted requests rerun the gate after removing the label', async () => {
  const untrusted = await labelEvent({
    action: 'labeled',
    label: 'ready-for-hosted-ci',
    labelsAfter: ['ready-for-hosted-ci'],
    permission: 'read',
  });
  assert.deepEqual(untrusted.dispatches, []);
  assert.deepEqual(untrusted.removedLabels, ['ready-for-hosted-ci']);
  assert.deepEqual(untrusted.reruns, rerunOf(501));

  const dependabot = await labelEvent({
    action: 'labeled',
    label: 'ready-for-hosted-ci',
    labelsAfter: ['ready-for-hosted-ci'],
    author: 'dependabot[bot]',
  });
  assert.deepEqual(dependabot.dispatches, []);
  assert.deepEqual(dependabot.reruns, rerunOf(501));

  const hostedFailure = await labelEvent({
    action: 'labeled',
    label: 'ready-for-hosted-ci',
    labelsAfter: ['ready-for-hosted-ci'],
    failingWorkflow: 'gem-tests.yml',
  });
  assert.deepEqual(hostedFailure.reruns, rerunOf(501));
  assert.deepEqual(hostedFailure.removedLabels, ['ready-for-hosted-ci', 'force-full-hosted-ci']);
});

test('ready-for-hosted-ci added beside force-full-hosted-ci leaves dispatch to the force-full event', async () => {
  const calls = await labelEvent({
    action: 'labeled',
    label: 'ready-for-hosted-ci',
    labelsAfter: ['ready-for-hosted-ci', 'force-full-hosted-ci'],
  });
  assert.deepEqual(calls.dispatches, []);
  assert.deepEqual(calls.reruns, []);
});

test('a gate run that belongs to another PR on the same head is never rerun', async () => {
  const shared = await labelEvent({
    action: 'unlabeled',
    label: 'ready-for-hosted-ci',
    labelsAfter: [],
    gateRunSnapshots: [[completedGateRun, { id: 509, status: 'completed', pull_requests: [{ number: 77 }] }]],
  });
  assert.deepEqual(shared.reruns, rerunOf(501));

  const foreign = await labelEvent({
    action: 'unlabeled',
    label: 'ready-for-hosted-ci',
    labelsAfter: [],
    gateRunSnapshots: [[{ id: 509, status: 'completed', pull_requests: [{ number: 77 }] }]],
  });
  assert.deepEqual(foreign.reruns, []);
  assert.equal(foreign.failed.length, 1);
});

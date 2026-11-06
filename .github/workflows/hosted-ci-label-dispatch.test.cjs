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

async function labelEvent({
  action,
  label,
  labelsAfter,
  actor = 'maintainer',
  permission = 'write',
  fork = false,
  author = 'maintainer',
  failingWorkflow,
}) {
  const calls = { dispatches: [], removedLabels: [], comments: [], failed: [] };
  const github = {
    rest: {
      actions: {
        createWorkflowDispatch: async (options) => {
          if (options.workflow_id === failingWorkflow) {
            throw Object.assign(new Error('dispatch refused'), { status: 500 });
          }
          calls.dispatches.push(options);
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
  await runWorkflow(github, context, core);
  calls.requiredGate = calls.dispatches.filter((dispatch) => dispatch.workflow_id === 'ci-required.yml');
  calls.hosted = calls.dispatches.filter((dispatch) => dispatch.workflow_id !== 'ci-required.yml');
  return calls;
}

const plainGate = {
  ...repo,
  workflow_id: 'ci-required.yml',
  ref: 'feature',
  inputs: { pull_request_base_ref: 'main', pull_request_base_sha: 'base-sha' },
};
const forcedGate = {
  ...plainGate,
  inputs: { ...plainGate.inputs, force_required_hosted_ci_recheck: 'true' },
};

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

test('adding a hosted-CI label dispatches hosted CI and then a plain required-gate run', async () => {
  const calls = await labelEvent({
    action: 'labeled',
    label: 'ready-for-hosted-ci',
    labelsAfter: ['ready-for-hosted-ci'],
  });
  assert.equal(calls.hosted.length, hostedWorkflowCount);
  assert.deepEqual(calls.requiredGate, [plainGate]);
  assert.equal(
    calls.dispatches.at(-1).workflow_id,
    'ci-required.yml',
    'the gate reruns after hosted CI is dispatched',
  );
  assert.deepEqual(calls.failed, []);
});

test('removing the last hosted-CI label dispatches a forced required-gate recheck', async () => {
  for (const label of ['ready-for-hosted-ci', 'force-full-hosted-ci']) {
    // eslint-disable-next-line no-await-in-loop
    const calls = await labelEvent({ action: 'unlabeled', label, labelsAfter: ['awaiting-resume'] });
    assert.deepEqual(calls.dispatches, [forcedGate], label);
    assert.deepEqual(calls.failed, [], label);
  }
});

test('removing one hosted-CI label while another remains leaves the gate alone', async () => {
  const calls = await labelEvent({
    action: 'unlabeled',
    label: 'force-full-hosted-ci',
    labelsAfter: ['ready-for-hosted-ci'],
  });
  assert.deepEqual(calls.dispatches, []);
  assert.deepEqual(calls.failed, []);
});

test('hosted-CI label removal on a fork dispatches nothing', async () => {
  const calls = await labelEvent({
    action: 'unlabeled',
    label: 'ready-for-hosted-ci',
    labelsAfter: [],
    fork: true,
  });
  assert.deepEqual(calls.dispatches, []);
});

test('a failed required-gate recheck after removal fails the job', async () => {
  const calls = await labelEvent({
    action: 'unlabeled',
    label: 'ready-for-hosted-ci',
    labelsAfter: [],
    failingWorkflow: 'ci-required.yml',
  });
  assert.equal(calls.failed.length, 1);
});

test('untrusted, Dependabot, and failed hosted requests never send a plain gate run', async () => {
  const untrusted = await labelEvent({
    action: 'labeled',
    label: 'ready-for-hosted-ci',
    labelsAfter: ['ready-for-hosted-ci'],
    permission: 'read',
  });
  assert.deepEqual(untrusted.dispatches, [forcedGate]);
  assert.deepEqual(untrusted.removedLabels, ['ready-for-hosted-ci']);

  const dependabot = await labelEvent({
    action: 'labeled',
    label: 'ready-for-hosted-ci',
    labelsAfter: ['ready-for-hosted-ci'],
    author: 'dependabot[bot]',
  });
  assert.deepEqual(dependabot.dispatches, [forcedGate]);

  const hostedFailure = await labelEvent({
    action: 'labeled',
    label: 'ready-for-hosted-ci',
    labelsAfter: ['ready-for-hosted-ci'],
    failingWorkflow: 'gem-tests.yml',
  });
  assert.deepEqual(hostedFailure.requiredGate, [forcedGate]);
});

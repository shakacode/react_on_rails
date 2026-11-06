// Tests the ci-required label-event filter: status-label events may skip the
// required gate only when a passing gate already covers the same head.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const { test } = require('node:test');

const AsyncFunction = Object.getPrototypeOf(async function asyncFunctionPrototype() {
  return undefined;
}).constructor;

const workflow = fs.readFileSync('.github/workflows/ci-required.yml', 'utf8');

function jobBlock(jobName) {
  const lines = workflow.split('\n');
  const start = lines.findIndex((line) => line === `  ${jobName}:`);
  assert.notEqual(start, -1, `ci-required.yml is missing the ${jobName} job`);
  const end = lines.findIndex((line, index) => index > start && /^ {2}[a-zA-Z0-9_-]+:$/.test(line));
  return lines.slice(start, end === -1 ? undefined : end).join('\n');
}

// Reads a folded `key: >-` value at the given indent, as YAML would join it.
function foldedValue(block, key, indent) {
  const lines = block.split('\n');
  const start = lines.findIndex((line) => line === `${' '.repeat(indent)}${key}: >-`);
  assert.notEqual(start, -1, `missing folded ${key}`);
  const body = [];
  for (const line of lines.slice(start + 1)) {
    if (line.trim() !== '' && line.match(/^\s*/)[0].length <= indent) break;
    body.push(line.trim());
  }
  return body.join(' ').trim();
}

const filterJob = jobBlock('label-event-filter');
const gateJob = jobBlock('required-pr-gate');
const filterIf = foldedValue(filterJob, 'if', 4);
const gateIf = foldedValue(gateJob, 'if', 4);
const concurrencyGroup = foldedValue(workflow.split('\njobs:\n')[0], 'group', 2);

const scriptMarker = '          script: |\n';
const scriptStart = filterJob.indexOf(scriptMarker);
assert.notEqual(scriptStart, -1, 'label-event-filter must embed a github-script');
const filterScript = filterJob
  .slice(scriptStart + scriptMarker.length)
  .split('\n')
  .map((line) => (line.startsWith('            ') ? line.slice(12) : line))
  .join('\n');
const runFilterScript = new AsyncFunction('github', 'context', 'core', filterScript);

function evaluate(expression, scope) {
  // Actions allows hyphens in property names; JavaScript needs bracket access.
  const javascript = expression
    .replace(/^\s*\$\{\{|\}\}\s*$/g, '')
    .replace(/needs\.label-event-filter/g, "needs['label-event-filter']");
  return vm.runInNewContext(javascript, {
    format: (template, ...values) => template.replace(/\{(\d+)\}/g, (_, index) => values[index]),
    cancelled: () => false,
    ...scope,
  });
}

function labelEvent(action, label) {
  return {
    event_name: 'pull_request',
    run_id: 7,
    ref: 'refs/pull/1/merge',
    event: { action, label: { name: label }, pull_request: { number: 1 } },
  };
}

const hostedLabels = ['ready-for-hosted-ci', 'force-full-hosted-ci'];
const statusLabels = ['awaiting-merge-approval', 'awaiting-resume', 'awaiting-answer', 'hold', 'bug'];

test('the filter runs only for labels other than the hosted-CI labels', () => {
  for (const action of ['labeled', 'unlabeled']) {
    for (const label of statusLabels) {
      assert.equal(evaluate(filterIf, { github: labelEvent(action, label) }), true, `${action} ${label}`);
    }
    for (const label of hostedLabels) {
      assert.equal(evaluate(filterIf, { github: labelEvent(action, label) }), false, `${action} ${label}`);
    }
  }
  for (const action of ['opened', 'synchronize', 'reopened', 'ready_for_review']) {
    assert.equal(evaluate(filterIf, { github: { event_name: 'pull_request', event: { action } } }), false);
  }
  for (const eventName of ['merge_group', 'workflow_dispatch']) {
    assert.equal(evaluate(filterIf, { github: { event_name: eventName, event: {} } }), false, eventName);
  }
});

test('the filter covers exactly the labels the concurrency block isolates', () => {
  for (const action of ['labeled', 'unlabeled']) {
    for (const label of [...statusLabels, ...hostedLabels]) {
      const github = labelEvent(action, label);
      const isolated = evaluate(concurrencyGroup, { github }).startsWith('ci-required-ignored-label-');
      assert.equal(evaluate(filterIf, { github }), isolated, `${action} ${label}`);
    }
  }
});

test('the gate skips only when the filter succeeded and said the gate need not run', () => {
  const cases = [
    [{ result: 'skipped', outputs: {} }, true],
    [{ result: 'failure', outputs: {} }, true],
    [{ result: 'failure', outputs: { run_gate: 'false' } }, true],
    [{ result: 'success', outputs: { run_gate: 'true' } }, true],
    [{ result: 'success', outputs: {} }, true],
    [{ result: 'success', outputs: { run_gate: 'false' } }, false],
  ];
  for (const [filter, expected] of cases) {
    assert.equal(
      evaluate(gateIf, { needs: { 'label-event-filter': filter } }),
      expected,
      JSON.stringify(filter),
    );
  }
  assert.equal(
    evaluate(gateIf, {
      needs: { 'label-event-filter': { result: 'skipped', outputs: {} } },
      cancelled: () => true,
    }),
    false,
    'a cancelled run does not start the gate',
  );
});

const pad = (id) => String(id).padStart(2, '0');

// Each gate check run belongs to a workflow run triggered one minute before the job started.
function gateRun(id, status, conclusion, overrides = {}) {
  return {
    id,
    name: 'required-pr-gate',
    status,
    conclusion,
    started_at: `2026-11-05T10:00:${pad(id)}Z`,
    check_suite: { id: 1000 + id },
    app: { slug: 'github-actions' },
    ...overrides,
  };
}

function workflowRunFor(checkRun) {
  return { check_suite_id: checkRun.check_suite?.id, created_at: `2026-11-05T09:59:${pad(checkRun.id)}Z` };
}

function prEvent(event, createdAt, label) {
  return { event, created_at: createdAt, ...(label ? { label: { name: label } } : {}) };
}

const repo = { owner: 'shakacode', repo: 'react_on_rails' };

async function decide(checkRuns, { events = [], author = 'justin808', workflowRuns } = {}) {
  const outputs = {};
  const requests = {};
  const github = {
    rest: {
      checks: { listForRef: 'checks' },
      actions: { listWorkflowRuns: 'workflowRuns' },
      issues: { listEvents: 'events' },
    },
    paginate: async (kind, params) => {
      assert.equal(requests[kind], undefined, `${kind} requested twice`);
      requests[kind] = params;
      return { checks: checkRuns, workflowRuns: workflowRuns ?? checkRuns.map(workflowRunFor), events }[kind];
    },
  };
  const context = {
    repo,
    payload: {
      label: { name: 'awaiting-merge-approval' },
      pull_request: { number: 42, user: { login: author }, head: { sha: 'head-sha' } },
    },
  };
  const core = {
    setOutput: (name, value) => {
      outputs[name] = value;
    },
    info: () => {},
  };
  await runFilterScript(github, context, core);
  const expected = {
    checks: { ...repo, ref: 'head-sha', check_name: 'required-pr-gate', filter: 'all', per_page: 100 },
    workflowRuns: { ...repo, workflow_id: 'ci-required.yml', head_sha: 'head-sha', per_page: 100 },
    events: { ...repo, issue_number: 42, per_page: 100 },
  };
  for (const [kind, params] of Object.entries(requests)) {
    assert.deepEqual(params, expected[kind], `${kind} request`);
  }
  return outputs.run_gate;
}

test('the filter skips the gate after a passing gate on the same head', async () => {
  assert.equal(await decide([gateRun(5, 'completed', 'success')]), 'false');
  assert.equal(
    await decide([gateRun(5, 'completed', 'success'), gateRun(9, 'completed', 'skipped')]),
    'false',
    'an earlier skip rests on the same passing run',
  );
  assert.equal(
    await decide([gateRun(5, 'completed', 'failure'), gateRun(7, 'completed', 'success')]),
    'false',
    'the newest result decides',
  );
  assert.equal(
    await decide([gateRun(5, 'completed', 'success')], {
      events: [
        prEvent('unlabeled', '2026-11-05T09:58:00Z', 'ready-for-hosted-ci'),
        prEvent('base_ref_changed', '2026-11-05T09:58:30Z'),
        prEvent('labeled', '2026-11-05T10:30:00Z', 'awaiting-resume'),
        prEvent('renamed', '2026-11-05T10:31:00Z'),
      ],
    }),
    'false',
    'gate-input changes before the trigger and other changes after it do not matter',
  );
  assert.equal(
    await decide([gateRun(5, 'completed', 'failure'), gateRun(7, 'completed', 'success')], {
      events: [prEvent('base_ref_changed', '2026-11-05T09:59:06Z')],
    }),
    'false',
    'the change is measured from the passing run, not an older one',
  );
});

test('the filter reruns the gate whenever the head has no settled pass', async () => {
  assert.equal(await decide([]), 'true', 'no earlier result');
  assert.equal(await decide([gateRun(5, 'completed', 'failure')]), 'true', 'a failed gate');
  assert.equal(await decide([gateRun(5, 'completed', 'cancelled')]), 'true', 'a cancelled gate');
  assert.equal(
    await decide([gateRun(5, 'completed', 'success'), gateRun(7, 'completed', 'failure')]),
    'true',
    'a newer failure beats an older pass',
  );
  assert.equal(
    await decide([gateRun(5, 'completed', 'success'), gateRun(7, 'in_progress', null)]),
    'true',
    'a gate still running',
  );
  assert.equal(
    await decide([gateRun(5, 'completed', 'success'), gateRun(7, 'queued', null)]),
    'true',
    'a gate still queued',
  );
  assert.equal(
    await decide([gateRun(5, 'in_progress', null), gateRun(7, 'completed', 'success')]),
    'true',
    'an older gate still running behind a newer pass',
  );
  assert.equal(await decide([gateRun(9, 'completed', 'skipped')]), 'true', 'a skip with no pass behind it');
  assert.equal(
    await decide([gateRun(5, 'completed', 'success', { app: { slug: 'some-other-app' } })]),
    'true',
    'a same-named check from another app does not count',
  );
  assert.equal(
    await decide([gateRun(5, 'completed', 'success')], { workflowRuns: [] }),
    'true',
    'a pass whose workflow run cannot be found',
  );
});

test('the filter reruns the gate when a gate input changed after the passing gate was triggered', async () => {
  const changes = [
    prEvent('unlabeled', '2026-11-05T09:59:05Z', 'ready-for-hosted-ci'),
    prEvent('labeled', '2026-11-05T10:20:00Z', 'ready-for-hosted-ci'),
    prEvent('unlabeled', '2026-11-05T10:20:00Z', 'force-full-hosted-ci'),
    prEvent('base_ref_changed', '2026-11-05T10:20:00Z'),
    // Between the triggering event and the job start: the run's payload still holds the old base.
    prEvent('base_ref_changed', '2026-11-05T09:59:30Z'),
  ];
  const decisions = await Promise.all(
    changes.map((change) => decide([gateRun(5, 'completed', 'success')], { events: [change] })),
  );
  changes.forEach((change, index) => {
    assert.equal(
      decisions[index],
      'true',
      `${change.event} ${change.label?.name ?? ''} at ${change.created_at}`,
    );
  });
});

test('the filter always reruns the gate on Dependabot pull requests', async () => {
  assert.equal(await decide([gateRun(5, 'completed', 'success')], { author: 'dependabot[bot]' }), 'true');
});

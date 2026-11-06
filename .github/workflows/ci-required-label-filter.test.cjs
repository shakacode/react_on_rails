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
const currentRunId = 777;
const currentSuiteId = 7770;

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
  return {
    id: checkRun.id,
    check_suite_id: checkRun.check_suite?.id,
    created_at: `2026-11-05T09:59:${pad(checkRun.id)}Z`,
  };
}

const currentWorkflowRun = {
  id: currentRunId,
  check_suite_id: currentSuiteId,
  created_at: '2026-11-05T11:00:00Z',
};
// The current run's own gate, queued while it waits on the filter.
const ownQueuedGate = gateRun(99, 'queued', null, { check_suite: { id: currentSuiteId } });

function timelineItem(typename, createdAt, label) {
  return { __typename: typename, createdAt, ...(label ? { label: { name: label } } : {}) };
}

const repo = { owner: 'shakacode', repo: 'react_on_rails' };

async function decide(checkRuns, { timeline = [], author = 'justin808', workflowRuns, pageSize = 100 } = {}) {
  const outputs = {};
  const requests = { graphql: [] };
  const runs = workflowRuns ?? [...checkRuns.map(workflowRunFor), currentWorkflowRun];
  const github = {
    rest: { checks: { listForRef: 'checks' }, actions: { listWorkflowRuns: 'workflowRuns' } },
    paginate: async (kind, params) => {
      assert.equal(requests[kind], undefined, `${kind} requested twice`);
      requests[kind] = params;
      return { checks: checkRuns, workflowRuns: runs }[kind];
    },
    graphql: async (query, variables) => {
      assert.match(query, /itemTypes: \[LABELED_EVENT, UNLABELED_EVENT, BASE_REF_CHANGED_EVENT\]/);
      requests.graphql.push(variables);
      // Like GitHub, return only items at or after `since`, a page at a time.
      const visible = timeline.filter((item) => Date.parse(item.createdAt) >= Date.parse(variables.since));
      const start = variables.after ? Number(variables.after) : 0;
      const end = start + pageSize;
      return {
        repository: {
          pullRequest: {
            timelineItems: {
              nodes: visible.slice(start, end),
              pageInfo: { hasNextPage: end < visible.length, endCursor: String(end) },
            },
          },
        },
      };
    },
  };
  const context = {
    repo,
    runId: currentRunId,
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
  if (requests.checks) {
    assert.deepEqual(requests.checks, {
      ...repo,
      ref: 'head-sha',
      check_name: 'required-pr-gate',
      filter: 'all',
      per_page: 100,
    });
    assert.deepEqual(requests.workflowRuns, {
      ...repo,
      workflow_id: 'ci-required.yml',
      head_sha: 'head-sha',
      per_page: 100,
    });
  }
  for (const variables of requests.graphql) {
    assert.equal(variables.number, 42);
    assert.equal(variables.owner, 'shakacode');
  }
  return { runGate: outputs.run_gate, graphql: requests.graphql };
}

async function runGate(checkRuns, options) {
  return (await decide(checkRuns, options)).runGate;
}

test('the filter skips the gate after a passing gate on the same head', async () => {
  assert.equal(await runGate([gateRun(5, 'completed', 'success')]), 'false');
  assert.equal(
    await runGate([gateRun(5, 'completed', 'success'), ownQueuedGate]),
    'false',
    "this run's own queued gate is not an earlier result",
  );
  assert.equal(
    await runGate([gateRun(5, 'completed', 'success'), gateRun(9, 'completed', 'skipped')]),
    'false',
    'an earlier skip rests on the same passing run',
  );
  assert.equal(
    await runGate([gateRun(5, 'completed', 'failure'), gateRun(7, 'completed', 'success')]),
    'false',
    'the newest result decides',
  );
  assert.equal(
    await runGate([gateRun(5, 'completed', 'success')], {
      timeline: [
        timelineItem('UnlabeledEvent', '2026-11-05T09:56:00Z', 'ready-for-hosted-ci'),
        timelineItem('BaseRefChangedEvent', '2026-11-05T09:56:30Z'),
        timelineItem('LabeledEvent', '2026-11-05T10:30:00Z', 'awaiting-resume'),
      ],
    }),
    'false',
    'gate-input changes well before the trigger and status-label changes after it do not matter',
  );
  assert.equal(
    await runGate([gateRun(5, 'completed', 'failure'), gateRun(7, 'completed', 'success')], {
      timeline: [timelineItem('BaseRefChangedEvent', '2026-11-05T09:56:30Z')],
    }),
    'false',
    'the change is measured from the passing run, not an older one',
  );
});

test('the filter measures history from two minutes before the passing run was created', async () => {
  const { graphql } = await decide([gateRun(5, 'completed', 'success')]);
  assert.deepEqual(
    graphql.map((variables) => variables.since),
    ['2026-11-05T09:57:05.000Z'],
  );
});

test('the filter reruns the gate whenever the head has no settled pass', async () => {
  assert.equal(await runGate([]), 'true', 'no earlier result');
  assert.equal(await runGate([ownQueuedGate]), 'true', 'only this run’s own gate');
  assert.equal(await runGate([gateRun(5, 'completed', 'failure')]), 'true', 'a failed gate');
  assert.equal(await runGate([gateRun(5, 'completed', 'cancelled')]), 'true', 'a cancelled gate');
  assert.equal(
    await runGate([gateRun(5, 'completed', 'success'), gateRun(7, 'completed', 'failure')]),
    'true',
    'a newer failure beats an older pass',
  );
  assert.equal(
    await runGate([gateRun(5, 'completed', 'success'), gateRun(7, 'in_progress', null)]),
    'true',
    'a gate still running',
  );
  assert.equal(
    await runGate([gateRun(5, 'completed', 'success'), gateRun(7, 'queued', null)]),
    'true',
    'another run’s gate still queued',
  );
  assert.equal(
    await runGate([gateRun(5, 'in_progress', null), gateRun(7, 'completed', 'success')]),
    'true',
    'an older gate still running behind a newer pass',
  );
  assert.equal(await runGate([gateRun(9, 'completed', 'skipped')]), 'true', 'a skip with no pass behind it');
  assert.equal(
    await runGate([gateRun(5, 'completed', 'success', { app: { slug: 'some-other-app' } })]),
    'true',
    'a same-named check from another app does not count',
  );
  assert.equal(
    await runGate([gateRun(5, 'completed', 'success')], { workflowRuns: [currentWorkflowRun] }),
    'true',
    'a pass whose workflow run cannot be found',
  );
  assert.equal(
    await runGate([gateRun(5, 'completed', 'success')], { workflowRuns: [workflowRunFor(gateRun(5))] }),
    'true',
    'the current run cannot be found, so its own gate cannot be told apart',
  );
});

test('the filter reruns the gate when a gate input changed around or after the passing run', async () => {
  const changes = [
    timelineItem('UnlabeledEvent', '2026-11-05T09:59:05Z', 'ready-for-hosted-ci'),
    timelineItem('LabeledEvent', '2026-11-05T10:20:00Z', 'ready-for-hosted-ci'),
    timelineItem('UnlabeledEvent', '2026-11-05T10:20:00Z', 'force-full-hosted-ci'),
    timelineItem('BaseRefChangedEvent', '2026-11-05T10:20:00Z'),
    // After the triggering event but before the workflow run was created.
    timelineItem('BaseRefChangedEvent', '2026-11-05T09:58:30Z'),
  ];
  const decisions = await Promise.all(
    changes.map((change) => runGate([gateRun(5, 'completed', 'success')], { timeline: [change] })),
  );
  changes.forEach((change, index) => {
    assert.equal(decisions[index], 'true', `change ${index}: ${JSON.stringify(change)}`);
  });
  assert.equal(
    await runGate([gateRun(5, 'completed', 'success')], {
      pageSize: 1,
      timeline: [
        timelineItem('LabeledEvent', '2026-11-05T10:10:00Z', 'awaiting-resume'),
        timelineItem('UnlabeledEvent', '2026-11-05T10:11:00Z', 'awaiting-resume'),
        timelineItem('UnlabeledEvent', '2026-11-05T10:12:00Z', 'ready-for-hosted-ci'),
      ],
    }),
    'true',
    'a hosted-label change on a later timeline page',
  );
});

test('the filter always reruns the gate on Dependabot pull requests', async () => {
  assert.equal(await runGate([gateRun(5, 'completed', 'success')], { author: 'dependabot[bot]' }), 'true');
});

import assert from 'node:assert/strict';
import test from 'node:test';
import { cleanupRun, residualProcessGroups } from './app-session.mjs';

test('finds only process groups owned by the unique benchmark session', () => {
  const processList = `
  100 100 tmux -L overmind-rspack-session-abc
  101 100 ruby app from rspack-session-abc
  200 200 tmux -L unrelated-session
  300 300 node harness rspack-session-abc
`;
  assert.deepEqual(residualProcessGroups(processList, 'rspack-session-abc', 300), [100]);
});

test('cleanup attempts browser and workspace removal after a session stop failure', async () => {
  const calls = [];
  const failure = new Error('stop failed');
  await assert.rejects(
    cleanupRun(
      {
        stop: async () => {
          calls.push('stop');
          throw failure;
        },
      },
      {
        close: async () => {
          calls.push('browser');
        },
      },
      async () => {
        calls.push('workspaces');
      },
    ),
    (error) => error === failure,
  );
  assert.deepEqual(calls, ['stop', 'browser', 'workspaces']);
});

test('cleanup preserves multiple failures after attempting every resource', async () => {
  const failure = new Error('stop failed');
  const browserFailure = new Error('browser failed');
  let removed = false;
  await assert.rejects(
    cleanupRun(
      {
        stop: async () => {
          throw failure;
        },
      },
      {
        close: async () => {
          throw browserFailure;
        },
      },
      async () => {
        removed = true;
      },
    ),
    (error) =>
      error instanceof AggregateError && error.errors[0] === failure && error.errors[1] === browserFailure,
  );
  assert.equal(removed, true);
});

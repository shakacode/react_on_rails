import assert from 'node:assert/strict';
import test from 'node:test';
import { residualProcessGroups } from './app-session.mjs';

test('finds only process groups owned by the unique benchmark session', () => {
  const processList = `
  100 100 tmux -L overmind-rspack-session-abc
  101 100 ruby app from rspack-session-abc
  200 200 tmux -L unrelated-session
  300 300 node harness rspack-session-abc
`;
  assert.deepEqual(residualProcessGroups(processList, 'rspack-session-abc', 300), [100]);
});

import React from 'react';
import { renderToString } from 'react-dom/server';
import ConsoleLogsInAsyncServer from '../components/ConsoleLogsInAsyncServer';

export default async ({ requestId }, _railsContext) => {
  console.log(`[${requestId}] Console log from Sync Server`);

  const recursiveAsyncFunction = async (level = 0) => {
    await new Promise((resolve) => setTimeout(resolve, 100));
    console.log(`[${requestId}] Console log from Recursive Async Function at level ${level}`);
    if (level < 10) {
      await recursiveAsyncFunction(level + 1);
    }
  };

  const loopCallOfAsyncFunction = async () => {
    const simpleAsyncFunction = async (iteration) => {
      await new Promise((resolve) => setTimeout(resolve, 100));
      console.log(`[${requestId}] Console log from Simple Async Function at iteration ${iteration}`);
    };

    for (let i = 0; i < 10; i++) {
      await simpleAsyncFunction(i);
    }
  };

  await recursiveAsyncFunction();
  await loopCallOfAsyncFunction();
  console.log(`[${requestId}] Console log from Async Server after calling async functions`);

  return renderToString(<ConsoleLogsInAsyncServer requestId={requestId} />);
};

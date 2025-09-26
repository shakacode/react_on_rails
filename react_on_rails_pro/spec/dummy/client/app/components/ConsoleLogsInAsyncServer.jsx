import React from 'react';

const ConsoleLogsInAsyncServer = ({ requestId }) => (
  <div>
    <h1>Console logs in async server</h1>
    <p>
      Request ID: <b>{requestId}</b>
    </p>
    <p>
      Request ID should prefix all console logs logged on the server. You shouldn&quot;t see more than one
      request ID in the console logs.
    </p>

    <br />

    <div>
      <p>
        If <code>replayServerAsyncOperationLogs</code> is set to <code>true</code> (or not set at all because
        it&quot;s the default value), you should see all logs either logged in sync or async server
        operations.
      </p>

      <p>So, you should see the following logs in the console:</p>
      <ul>
        <li>[SERVER][{requestId}] Console log from Sync Server</li>
        <li>
          [SERVER][{requestId}] Console log from Recursive Async Function at level &lt;repeated 10 times&gt;
        </li>
        <li>
          [SERVER][{requestId}] Console log from Simple Async Function at iteration &lt;repeated 10 times&gt;
        </li>
        <li>[SERVER][{requestId}] Console log from Async Server after calling async functions</li>
      </ul>
    </div>

    <br />

    <div>
      <p>
        If <code>replayServerAsyncOperationLogs</code> is set to <code>false</code>, you should see only logs
        from sync server operations.
      </p>

      <p>So, you should see the following logs in the console:</p>
      <ul>
        <li>[SERVER][{requestId}] Console log from Sync Server</li>
      </ul>
    </div>
  </div>
);

export default ConsoleLogsInAsyncServer;

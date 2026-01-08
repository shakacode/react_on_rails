// HelloServer - React Server Component
// Unlike HelloWorld (which runs in the browser), this component runs ONLY on the server.
// No JavaScript is sent to the browser for this component.
//
// To add async data fetching, make this an async function and use await directly.
// For more information, see:
// https://www.shakacode.com/react-on-rails-pro/docs/react-server-components/

import React from 'react';

function HelloServer({ name = 'World' }) {
  return (
    <div>
      <h3>Hello, {name}!</h3>
      <p>This is a React Server Component.</p>
    </div>
  );
}

export default HelloServer;

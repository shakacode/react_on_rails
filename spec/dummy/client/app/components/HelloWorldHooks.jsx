'use client';

// Super simple example of the simplest possible React component
import React, { useState } from 'react';
// TODO: CSS modules need to be configured to work properly with React Server Components (RSC)
// and client components that are used within server components.
// import css from './HelloWorld.module.scss';

function HelloWorldHooks({ helloWorldData }) {
  const [name, setName] = useState(helloWorldData.name);
  return (
    <div>
      <h3>Hello, {name}!</h3>
      <p>
        Say hello to:
        <input type="text" value={name} onChange={(e) => setName(e.target.value)} />
      </p>
    </div>
  );
}

export default HelloWorldHooks;

import React, { useState } from 'react';
import * as style from './HelloWorld.module.css';

// This component works for both client and server rendering.
//
// For cases where you need different client/server behavior (e.g., React Router,
// styled-components, or conditional hydration), create separate files:
//
// 1. Move this component to ../components/HelloWorld.jsx
// 2. Create HelloWorld.client.jsx:
//    import HelloWorld from '../components/HelloWorld';
//    // Add client-specific setup (Router, providers, etc.)
//    export default HelloWorld;
//
// 3. Create HelloWorld.server.jsx:
//    import HelloWorld from '../components/HelloWorld';
//    // Add server-specific setup (StaticRouter, etc.)
//    export default HelloWorld;
//
// React on Rails will auto-register both .client and .server versions.

const HelloWorld = (props) => {
  const [name, setName] = useState(props.name);

  return (
    <div>
      <h3>Hello, {name}!</h3>
      <hr />
      <form>
        <label className={style.bright} htmlFor="name">
          Say hello to:
          <input id="name" type="text" value={name} onChange={(e) => setName(e.target.value)} />
        </label>
      </form>
    </div>
  );
};

export default HelloWorld;

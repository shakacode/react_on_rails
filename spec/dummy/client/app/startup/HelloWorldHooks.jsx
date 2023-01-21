// Super simple example of the simplest possible React component
import React, { useState } from 'react';
import css from '../components/HelloWorld.module.scss';

// TODO: make more like the HelloWorld.jsx
function HelloWorldHooks(props) {
  const [name, setName] = useState(props.helloWorldData.name);
  return (
    <div>
      <h3 className={css.brightColor}>Hello, {name}!</h3>
      <p>
        Say hello to:
        <input type="text" value={name} onChange={(e) => setName(e.target.value)} />
      </p>
    </div>
  );
}

export default HelloWorldHooks;

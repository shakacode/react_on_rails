import React, { useState, useEffect } from 'react';
import css from '../components/HelloWorld.module.scss';

function HelloWorldHooks(props) {
  console.log(`HelloWorldProps modification target prop value: ${props.modificationTarget}`);

  const [name, setName] = useState(props.helloWorldData.name);
  // a trick to display a client-only prop value without creating a server/client conflict
  const [delayedValue, setDelayedValue] = useState(null);

  useEffect(() => {
    setDelayedValue(props.modificationTarget);
  }, []);

  return (
    <div>
      <h3 className={css.brightColor}>Hello, {name}!</h3>
      <p>
        Say hello to:
        <input type="text" value={name} onChange={(e) => setName(e.target.value)} />
      </p>
      <h4>Value of modification target prop: {delayedValue}</h4>
    </div>
  );
}

export default HelloWorldHooks;

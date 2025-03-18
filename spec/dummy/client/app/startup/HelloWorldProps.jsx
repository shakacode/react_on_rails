import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import css from '../components/HelloWorld.module.scss';

function HelloWorldProps({ helloWorldData, modificationTarget }) {
  console.log(`HelloWorldProps modification target prop value: ${modificationTarget}`);

  const [name, setName] = useState(helloWorldData.name);
  // a trick to display a client-only prop value without creating a server/client conflict
  const [delayedValue, setDelayedValue] = useState(null);

  useEffect(() => {
    setDelayedValue(modificationTarget);
  }, [modificationTarget]);

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

HelloWorldProps.propTypes = {
  helloWorldData: PropTypes.shape({
    name: PropTypes.string,
  }).isRequired,
  modificationTarget: PropTypes.string.isRequired,
};

export default HelloWorldProps;

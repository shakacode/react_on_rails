// Super simple example of the simplest possible React component
import React, { useState } from 'react';
import PropTypes from 'prop-types';
import css from '../components/HelloWorld.module.scss';

// TODO: make more like the HelloWorld.jsx
function HelloWorldHooks({ helloWorldData }) {
  const [name, setName] = useState(helloWorldData.name);
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

HelloWorldHooks.propTypes = {
  helloWorldData: PropTypes.shape({
    name: PropTypes.string.isRequired,
  }).isRequired,
};

export default HelloWorldHooks;

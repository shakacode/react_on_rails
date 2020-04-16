// Example of using hooks when taking the props and railsContext
// Note, you need the call the hooks API within the react component stateless function
import React, { useState } from 'react';
import css from './HelloWorld.scss';
import RailsContext from './RailsContext';

/**
 * NOTE: This exampe
 * @param props
 * @param railsContext
 * @returns {function(): *}
 * @constructor
 */
const HelloWorldHooksContext = (props, railsContext) => {
  // You could pass props here or use the closure
  return () => {
    const [name, setName] = useState(props.helloWorldData.name);
    return (
      <>
        <h3 className={css.brightColor}>Hello, {name}!</h3>
        <p>
          Say hello to:
          <input type="text" value={name} onChange={(e) => setName(e.target.value)} />
        </p>
        <p>Rails Context :</p>
        <RailsContext {...{ railsContext }} />
      </>
    );
  };
};

export default HelloWorldHooksContext;

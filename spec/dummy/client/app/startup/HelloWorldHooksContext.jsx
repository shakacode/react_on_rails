// Example of using hooks when taking the props and railsContext
// Note, you need the call the hooks API within the react component stateless function
import React, { useState } from 'react';
import PropTypes from 'prop-types';
import css from '../components/HelloWorld.module.scss';
import RailsContext from '../components/RailsContext';

// You could pass props here or use the closure
const HelloWorldHooksContext = (props, railsContext) => {
  const Result = () => {
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

  Result.propTypes = {
    helloWorldData: PropTypes.shape({
      name: PropTypes.string,
    }).isRequired,
  };

  return Result;
};

export default HelloWorldHooksContext;

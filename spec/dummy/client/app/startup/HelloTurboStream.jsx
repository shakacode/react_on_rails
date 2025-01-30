import PropTypes from 'prop-types';
import React, { useState, useRef } from 'react';
import RailsContext from '../components/RailsContext';

import css from '../components/HelloWorld.module.scss';

const HelloTurboStream = ({ helloTurboStreamData, railsContext }) => {
  const [name, setName] = useState(helloTurboStreamData.name);
  const nameDomRef = useRef(null);
  // eslint-disable-next-line no-unused-vars
  const handleChange = () => {
    setName(nameDomRef.current.value);
  };

  return (
    <div>
      <h3 className={css.brightColor}>Hello, {name}!</h3>
      {railsContext && <RailsContext {...{ railsContext }} />}
    </div>
  );
};

HelloTurboStream.propTypes = {
  helloTurboStreamData: PropTypes.shape({
    name: PropTypes.string,
  }).isRequired,
  railsContext: PropTypes.object,
};

export default HelloTurboStream;

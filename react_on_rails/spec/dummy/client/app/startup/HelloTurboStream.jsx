import PropTypes from 'prop-types';
import React from 'react';
import RailsContext from '../components/RailsContext';

import css from '../components/HelloWorld.module.scss';

const HelloTurboStream = ({ helloTurboStreamData, railsContext }) => (
  <div>
    <h3 className={css.brightColor}>Hello, {helloTurboStreamData.name}!</h3>
    {railsContext && <RailsContext {...{ railsContext }} />}
  </div>
);

HelloTurboStream.propTypes = {
  helloTurboStreamData: PropTypes.shape({
    name: PropTypes.string,
  }).isRequired,
  railsContext: PropTypes.object,
};

export default HelloTurboStream;

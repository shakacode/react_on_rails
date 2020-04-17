// Top level component for simple client side only rendering
import React from 'react';
import ReactHelmet from '../components/ReactHelmet';

// This works fine, React functional component:
// export default (props) => <ReactHelmet {...props} />;

export default (props, _railsContext) => <ReactHelmet {...props} />;

// Note, the server side has to be a generator function

// If you want a generatorFunction, return a ReactComponent
// export default (props, _railsContext) => () => <ReactHelmet {...props} />;

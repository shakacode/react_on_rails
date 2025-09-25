import React from 'react';
import Loadable from './LoadableApp';

const WrappedLoadable = (props, railsContext) => () => <Loadable {...props} path={railsContext.pathname} />;

export default WrappedLoadable;

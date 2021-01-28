import React from 'react';
import { StaticRouter } from 'react-router-dom';

import routes from '../routes/routes';

export default (props, railsContext) => {
  return () => (
    <StaticRouter location={railsContext.location} {...props}>
      {routes}
    </StaticRouter>
  );
};

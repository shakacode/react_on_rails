/*
  Route: Sample component
*/

import Relay from 'react-relay';
const SampleRoute = {
  queries: {
    sample: () => Relay.QL` query {
      root
    } `,
  },
  params: {
  },
  name: 'SampleRoute',
};

module.exports = SampleRoute;

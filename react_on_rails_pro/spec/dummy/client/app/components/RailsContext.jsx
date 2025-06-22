import PropTypes from 'prop-types';
import React from 'react';
import { transform } from 'lodash';

function renderContextRows(railsContext) {
  console.log('railsContext.serverSide is ', railsContext.serverSide);
  const serverSideKeys = [
    'serverSide',
    'reactClientManifestFileName',
    'reactServerClientManifestFileName',
    'serverSideRSCPayloadParameters',
  ];
  return transform(
    railsContext,
    (accum, value, key) => {
      if (!serverSideKeys.includes(key)) {
        const className = `js-${key}`;
        accum.push(
          <tr key={className}>
            <td>
              <strong>{key}:&nbsp;</strong>
            </td>
            <td className={className}>{`${value}`}</td>
          </tr>,
        );
      }
    },
    [],
  );
}

const RailsContext = ({ railsContext }) => (
  <table>
    <thead>
      <tr>
        <th>
          <i>key</i>
        </th>
        <th>
          <i>value</i>
        </th>
      </tr>
    </thead>
    <tbody>{renderContextRows(railsContext)}</tbody>
  </table>
);

RailsContext.propTypes = {
  railsContext: PropTypes.object.isRequired,
};

export default RailsContext;

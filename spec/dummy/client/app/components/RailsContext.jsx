import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';

function renderContextRows(railsContext) {
  console.log('railsContext.serverSide is ', railsContext.serverSide);
  return _.transform(
    railsContext,
    (accum, value, key) => {
      if (key !== 'serverSide') {
        const className = `js-${key}`;
        const stringifiedValue = typeof value === 'object' ? JSON.stringify(value) : value;
        accum.push(
          <tr key={className}>
            <td>
              <strong>{key}:&nbsp;</strong>
            </td>
            <td className={className}>{`${stringifiedValue}`}</td>
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

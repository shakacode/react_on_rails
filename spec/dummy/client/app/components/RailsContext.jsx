import React, { PropTypes } from 'react';
import _ from 'lodash';

function renderContextRows(railsContext) {
  // eslint-disable-next-line no-console
  console.log('railsContext.serverSide is ', railsContext.serverSide);
  return _.transform(railsContext, (accum, value, key) => {
    if (key !== 'serverSide') {
      const className = `js-${key}`;
      accum.push(
        <tr key={className}>
          <td><strong>
            {key}:&nbsp;
          </strong></td>
          <td className={className}>{`${value}`}</td>
        </tr>,
      );
    }
  }, []);
}

const RailsContext = (props) => (
  <table>
    <thead>
      <tr>
        <th><i>
        key
        </i></th>
        <th><i>
        value
        </i></th>
      </tr>
    </thead>
    <tbody>
      {renderContextRows(props.railsContext)}
    </tbody>
  </table>
);

RailsContext.propTypes = {
  railsContext: PropTypes.object.isRequired,
};

export default RailsContext;

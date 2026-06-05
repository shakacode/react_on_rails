import React from 'react';

import type { RailsContextForDisplay } from '../types/railsContext';

type RailsContextProps = {
  railsContext: RailsContextForDisplay;
};

function renderContextRows(railsContext: RailsContextForDisplay) {
  console.log('railsContext.serverSide is ', railsContext.serverSide);
  return Object.entries(railsContext).reduce<React.ReactElement[]>((accum, [key, value]) => {
    if (key !== 'serverSide' && key !== 'componentSpecificMetadata') {
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

    return accum;
  }, []);
}

const RailsContext = ({ railsContext }: RailsContextProps) => (
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

export type { RailsContextProps };
export default RailsContext;

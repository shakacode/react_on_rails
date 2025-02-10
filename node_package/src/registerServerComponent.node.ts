import React from 'react';
import ReactOnRails from './ReactOnRails';
import RSCServerRoot, { RSCServerRootProps } from './RSCServerRoot';
import { ReactComponent } from './types';

const registerServerComponent = (components: { [id: string]: ReactComponent }) => {
  const componentsWrappedInRSCServerRoot = Object.entries(components).reduce(
    (acc, [name]) => ({
      ...acc,
      [name]: (props: RSCServerRootProps) => React.createElement(RSCServerRoot, {
        ...props,
      })
    }),
    {}
  );
  ReactOnRails.register(componentsWrappedInRSCServerRoot);
};

export default registerServerComponent;

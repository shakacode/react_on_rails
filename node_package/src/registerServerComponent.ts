import * as React from 'react';
import ReactOnRails from './ReactOnRails.client';
import RSCClientRoot from './RSCClientRoot';
import { RegisterServerComponentOptions } from './types';

const registerServerComponent = (options: RegisterServerComponentOptions, ...componentNames: string[]) => {
  const componentsWrappedInRSCClientRoot = componentNames.reduce(
    (acc, name) => ({
      ...acc,
      [name]: () => React.createElement(RSCClientRoot, {
        componentName: name,
        rscRenderingUrlPath: options.rscRenderingUrlPath
      })
    }),
    {}
  );
  ReactOnRails.register(componentsWrappedInRSCClientRoot);
};

export default registerServerComponent;

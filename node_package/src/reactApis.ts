import * as React from 'react';

// eslint-disable-next-line import/prefer-default-export
export const ensureReactUseAvailable = () => {
  if (!('use' in React) || typeof React.use !== 'function') {
    throw new Error(
      'React.use is not defined. Please ensure you are using React 19 to use server components.',
    );
  }
};

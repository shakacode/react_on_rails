import * as React from 'react';
import * as ReactDOM from 'react-dom';

const reactMajorVersion = Number(ReactDOM.version?.split('.')[0]) || 16;

// TODO: once we require React 18, we can remove this and inline everything guarded by it.
// Not the default export because others may be added for future React versions.
export const supportsRootApi = reactMajorVersion >= 18;

export const ensureReactUseAvailable = () => {
  if (!('use' in React) || typeof React.use !== 'function') {
    throw new Error(
      'React.use is not defined. Please ensure you are using React 19 to use server components.',
    );
  }
};

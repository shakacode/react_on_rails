/* eslint-disable react/no-deprecated,@typescript-eslint/no-deprecated */
import * as ReactDOM from 'react-dom';

const reactMajorVersion = Number(ReactDOM.version?.split('.')[0]) || 16;

// TODO: once we require React 18, we can remove this and inline everything guarded by it.
export const supportsRootApi = reactMajorVersion >= 18;

export const canHydrate = supportsRootApi || !!ReactDOM.hydrate;

export const { unmountComponentAtNode } = ReactDOM;

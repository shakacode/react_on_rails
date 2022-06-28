import ReactDOM from 'react-dom';

const reactMajorVersion = ReactDOM.version?.split('.')[0] || 16;

// TODO: once we require React 18, we can remove this and inline everything guarded by it.
// Not the default export because others may be added for future React versions.
// eslint-disable-next-line import/prefer-default-export
export const supportsRootApi = reactMajorVersion >= 18;

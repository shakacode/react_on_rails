import ReactDOM from 'react-dom';

export const isVersionGreaterThanOrEqualTo18 = (): boolean => (
    ReactDOM.version && parseInt(ReactDOM.version.split('.')[0], 10) >= 18 ||
    false
)

export default isVersionGreaterThanOrEqualTo18();

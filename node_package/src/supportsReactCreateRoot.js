import ReactDOM from 'react-dom';

const reactMajorVersion = parseInt(ReactDOM.version.split('.')[0], 10);
export default reactMajorVersion >= 18;

import path from 'path';

const packageJsonPath = path.join(__dirname, '../../../../package.json');

// eslint-disable-next-line import/no-dynamic-require
const packageJson = require(packageJsonPath);

export default packageJson;

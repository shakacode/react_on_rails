const fs = require('fs');
const { promisify } = require('util');

const fsAccessAsync = promisify(fs.access);

const fileExistsAsync = async assetPath => {
  try {
    await fsAccessAsync(assetPath, fs.constants.R_OK);
    return true;
  } catch (error) {
    if (error.code === 'ENOENT') {
      return false;
    }
    throw error;
  }
};

module.exports = fileExistsAsync;

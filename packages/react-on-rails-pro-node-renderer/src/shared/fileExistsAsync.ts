import fs from 'fs';
import { promisify } from 'util';

const fsAccessAsync = promisify(fs.access);

const fileExistsAsync = async (assetPath: string) => {
  try {
    await fsAccessAsync(assetPath, fs.constants.R_OK);
    return true;
  } catch (error) {
    if ((error as { code?: string }).code === 'ENOENT') {
      return false;
    }
    throw error;
  }
};

export default fileExistsAsync;

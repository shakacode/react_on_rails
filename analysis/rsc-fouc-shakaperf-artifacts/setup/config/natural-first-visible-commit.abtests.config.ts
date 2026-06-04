/* eslint-disable @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access */
import baseConfig from './abtests.config';

export default {
  ...baseConfig,
  visreg: {
    ...baseConfig.visreg,
    engineOptions: {
      ...baseConfig.visreg?.engineOptions,
      gotoParameters: { waitUntil: 'commit' },
    },
    compareRetries: 0,
    compareRetryDelay: 0,
  },
};

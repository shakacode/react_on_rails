import baseConfig from './abtests.config';

export default {
  ...baseConfig,
  visreg: {
    ...baseConfig.visreg,
    engineOptions: {
      ...baseConfig.visreg?.engineOptions,
      gotoParameters: { waitUntil: 'commit' },
    },
    // No retries: this diagnostic assertion should expose the first visible
    // unstyled state immediately instead of masking it with retry timing.
    compareRetries: 0,
    compareRetryDelay: 0,
  },
};

import { defineConfig } from 'shaka-shared';
import { rscFoucShakaPerfConfig } from './abtests.config';

export default defineConfig({
  ...rscFoucShakaPerfConfig,
  visreg: {
    ...rscFoucShakaPerfConfig.visreg,
    engineOptions: {
      ...rscFoucShakaPerfConfig.visreg.engineOptions,
      gotoParameters: { waitUntil: 'commit' },
    },
    // No retries: this diagnostic assertion should expose the first visible
    // unstyled state immediately instead of masking it with retry timing.
    compareRetries: 0,
    compareRetryDelay: 0,
  },
});

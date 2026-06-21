import { defineConfig, type AbTestsConfigInput } from 'shaka-shared';
import { rscFoucShakaPerfConfig } from './abtests.config';

type BaseVisregConfig = NonNullable<AbTestsConfigInput['visreg']>;
type BaseConfigWithVisregEngine = AbTestsConfigInput & {
  visreg: BaseVisregConfig & {
    engineOptions: NonNullable<BaseVisregConfig['engineOptions']>;
  };
};

const baseConfig = rscFoucShakaPerfConfig as BaseConfigWithVisregEngine;

// Compose from the raw config object so this derived config does not assume
// defineConfig(...) returns a plain enumerable object that can be spread safely.
export default defineConfig({
  ...baseConfig,
  visreg: {
    ...baseConfig.visreg,
    engineOptions: {
      ...baseConfig.visreg.engineOptions,
      gotoParameters: { waitUntil: 'commit' },
    },
    // No retries: this diagnostic assertion should expose the first visible
    // unstyled state immediately instead of masking it with retry timing.
    compareRetries: 0,
    compareRetryDelay: 0,
  },
});

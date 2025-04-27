import type { NormalizedCacheObject } from '@apollo/client';
import type { SSRCache } from '@shakacode/use-ssr-computation.runtime/lib/ssrCache';

declare global {
  interface Window {
    __APOLLO_STATE__: NormalizedCacheObject;
    __SSR_COMPUTATION_CACHE?: SSRCache;
  }
}

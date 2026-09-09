import type { FlashData, SharedProps } from '@/types';

declare module '@inertiajs/core' {
  export interface InertiaConfig {
    sharedPageProps: SharedProps;
    flashDataType: FlashData;
    errorValueType: string[];
  }
}

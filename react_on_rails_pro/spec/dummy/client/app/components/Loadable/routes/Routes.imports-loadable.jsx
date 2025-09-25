import loadable from '@loadable/component';

export const PageA = loadable(() => import(/* webpackPrefetch: true */ '../pages/A'));
export const PageB = loadable(() => import(/* webpackPrefetch: true */ '../pages/B'));

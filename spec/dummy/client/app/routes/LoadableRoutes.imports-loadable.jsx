import loadable from '@loadable/component';

export const PageA = loadable(() => import(/* webpackPrefetch: true */ '../components/Loadable/pages/A'));
export const PageB = loadable(() => import(/* webpackPrefetch: true */ '../components/Loadable/pages/B'));

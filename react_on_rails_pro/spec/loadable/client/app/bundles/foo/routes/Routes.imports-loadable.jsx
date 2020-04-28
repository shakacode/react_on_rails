// See spec/loadable/README.md for details regarding **.imports-X.** file extension & duplicate file structure.
import loadable from '@loadable/component';

export const PageA = loadable(() => import(/* webpackPrefetch: true */ '../components/pages/A'));
export const PageB = loadable(() => import(/* webpackPrefetch: true */ '../components/pages/B'));

import React from 'react';
import loadable from '@loadable/component';

const A = loadable(() => import('./A'));
const B = loadable(() => import('./B'));
const C = loadable(() => import(/* webpackPreload: true */ './C'));
const D = loadable(() => import(/* webpackPrefetch: true */ './D'));
const E = loadable(() => import('./E?param'), { ssr: false });
const X = loadable((props) => import(`./${props.letter}`));
const Sub = loadable((props) => import(`./${props.letter}/file`));

// Load the 'G' component twice: once in SSR and once fully client-side
const GClient = loadable(() => import('./G'), {
  ssr: false,
  fallback: <span className="loading-state">ssr: false - Loading...</span>,
});

const GServer = loadable(() => import('./G'), {
  ssr: true,
  fallback: <span className="loading-state">ssr: true - Loading...</span>,
});

const Moment = loadable.lib(() => import('moment'), {
  resolveComponent: (moment) => moment.default || moment,
});

export { A, B, C, D, E, X, Sub, GClient, GServer, Moment };

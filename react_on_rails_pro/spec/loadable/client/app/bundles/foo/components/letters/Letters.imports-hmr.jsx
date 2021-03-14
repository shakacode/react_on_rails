import React from 'react';

import A from './A';
import B from './B';
import C from './C';
import D from './D';
import E from './E';
import F from './F';
import Sub from './Z/file';

const components = {
  A: A,
  B: B,
  C: C,
  D: D,
  E: E,
  F: F,
};

// Not the same functionality as loadable-components because I have to
// create a registry instead of dynamically importing a file
const X = (props) => {
  const RegisteredComponent = components[props.letter];
  return <RegisteredComponent />;
};

// The loadable-compnents equivalents of the below components also depend on dynamic importing
const GClient = () => <span className="loading-state">ssr: false - Loading...</span>;

const GServer = () => <span className="loading-state">ssr: true - Loading...</span>;

import momentLib from 'moment';
const Moment = (props) => props.children(momentLib);

export { A, B, C, D, E, X, Sub, GClient, GServer, Moment };

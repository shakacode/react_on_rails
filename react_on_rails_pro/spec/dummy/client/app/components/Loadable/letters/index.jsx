import React from 'react';
import { A, B, C, D, X, E, GClient, GServer, Sub, Moment } from './Letters.imports-loadable';
import './main.css';

const Letters = () => (
  <div>
    <h1>Check out how these letters are imported in the source code!</h1>
    <A />
    <br />
    <B />
    <br />
    <C />
    <br />
    <D />
    <br />
    <X letter="A" />
    <br />
    <X letter="F" />
    <br />
    <E />
    <br />
    <GClient prefix="ssr: false" />
    <br />
    <GServer prefix="ssr: true" />
    <br />
    <Sub letter="Z" />
    <br />
    <Moment>{(moment) => moment().format('HH:mm')}</Moment>
  </div>
);

export default Letters;

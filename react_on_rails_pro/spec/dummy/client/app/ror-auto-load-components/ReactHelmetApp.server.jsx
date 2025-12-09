'use client';

import 'cross-fetch/polyfill';

// Top level component for simple client side only rendering
import React from 'react';
import { renderToString } from 'react-dom/server';
import { HelmetProvider } from '@dr.pogodin/react-helmet';
import ReactHelmet from '../components/ReactHelmet';

/*
 *  Export a function that takes the props and returns an object with { renderedHtml }
 *  This example shows returning renderedHtml as an object itself that contains rendered
 *  component markup and additional HTML strings.
 *
 *  This is imported as "ReactHelmetApp" by "serverRegistration.jsx". Note that rendered
 *  component markup must go under "componentHtml" key.
 */
export default async (props, _railsContext) => {
  const apiRequestResponse = await fetch(`https://api.nationalize.io/?name=ReactOnRails`)
    .then((response) => {
      if (response.status >= 400) {
        throw new Error('Bad response from server');
      }
      return response.json();
    })
    .catch((error) =>
      console.error(`There was an error doing an API request during server rendering: ${error}`),
    );

  // For server-side rendering with @dr.pogodin/react-helmet, we pass a context object
  // to HelmetProvider to capture the helmet data per-request (thread-safe)
  const helmetContext = {};
  const componentHtml = renderToString(
    <HelmetProvider context={helmetContext}>
      <ReactHelmet {...props} apiRequestResponse={apiRequestResponse} />
    </HelmetProvider>,
  );
  const { helmet } = helmetContext;

  const promiseObject = {
    componentHtml,
    title: helmet?.title?.toString() || '',
  };
  return promiseObject;
};

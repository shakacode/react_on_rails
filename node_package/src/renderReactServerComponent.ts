import React from 'react';
import type { ReactElement } from 'react';
import type { ReactComponent } from './types/index';
import { renderToPipeableStream } from 'react-server-dom-webpack/server.node';

import ComponentRegistry from './ComponentRegistry';
import buildConsoleReplay from './buildConsoleReplay';
import handleError from './handleError';
import type { RenderParams, RenderResult, RenderingError } from './types/index';

import { Writable } from 'node:stream';

function renderReactServerComponentInternal(options: RenderParams): null | string | Promise<RenderResult> {
  const { name, props, throwJsErrors } = options;

  let renderResult: null | string | Promise<string> = null;
  let hasErrors = false;
  let renderingError: null | RenderingError = null;

  try {
    const componentObj = ComponentRegistry.get(name);
    const { component } = componentObj;
    const reactRenderingResult = React.createElement(component as ReactComponent, props);

    const processReactElement = () => {
      try {
        const path = require('path');
        const { readFileSync } = require('fs');
        const reactClientManifest = readFileSync(path.resolve(__dirname, 'react-client-manifest.json'), 'utf8');
        const moduleMap = JSON.parse(reactClientManifest);
        const { pipe } = renderToPipeableStream(reactRenderingResult as ReactElement, moduleMap);

        const chunks: Buffer[] = [];
        const stream = new Writable({
          write(chunk, encoding, callback) {
            chunks.push(chunk);
            callback();
          },
        });

        pipe(stream);

        return new Promise<string>((resolve, reject) => {
          stream.on('finish', () => {
            resolve(Buffer.concat(chunks).toString('utf8'));
          });
          stream.on('error', reject);
        });
      } catch (error) {
        console.error(error);
        throw error;
      }
    };

    renderResult = processReactElement();
  } catch (e: any) {
    if (throwJsErrors) {
      throw e;
    }

    hasErrors = true;
    renderResult = handleError({
      e,
      name,
      serverSide: true,
    });
    renderingError = e;
  }

  const consoleReplayScript = buildConsoleReplay();
  const addRenderingErrors = (resultObject: RenderResult, renderError: RenderingError) => {
    resultObject.renderingError = { // eslint-disable-line no-param-reassign
      message: renderError.message,
      stack: renderError.stack,
    };
  }

  const resolveRenderResult = async () => {
    let promiseResult;

    try {
      promiseResult = {
        html: await renderResult,
        consoleReplayScript,
        hasErrors,
      };
    } catch (e: any) {
      if (throwJsErrors) {
        throw e;
      }
      promiseResult = {
        html: handleError({
          e,
          name,
          serverSide: true,
        }),
        consoleReplayScript,
        hasErrors: true,
      }
      renderingError = e;
    }

    if (renderingError !== null) {
      addRenderingErrors(promiseResult, renderingError);
    }

    return promiseResult;
  };

  return resolveRenderResult();
}

const renderReactServerComponent: typeof renderReactServerComponentInternal = (options) => {
  try {
    return renderReactServerComponentInternal(options);
  } finally {
    // Reset console history after each render.
    // See `RubyEmbeddedJavaScript.console_polyfill` for initialization.
    console.history = [];
  }
};
export default renderReactServerComponent;

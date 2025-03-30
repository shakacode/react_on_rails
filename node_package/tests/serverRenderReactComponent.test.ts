/* eslint-disable @typescript-eslint/no-unused-vars */

import * as React from 'react';
import serverRenderReactComponent from '../src/serverRenderReactComponent';
import ComponentRegistry from '../src/ComponentRegistry';
import type {
  RenderParams,
  RenderResult,
  RailsContext,
  RenderFunction,
  RenderFunctionResult,
  ServerRenderResult,
} from '../src/types';

const assertIsString: (value: unknown) => asserts value is string = (value: unknown) => {
  if (typeof value !== 'string') {
    throw new Error(`Expected value to be of type 'string', but received type '${typeof value}'`);
  }
};

const assertIsPromise: <T>(value: null | string | Promise<T>) => asserts value is Promise<T> = <T>(
  value: null | string | Promise<T>,
) => {
  if (!value || typeof (value as Promise<T>).then !== 'function') {
    throw new Error(`Expected value to be of type 'Promise', but received type '${typeof value}'`);
  }
};

// This function is used to ensure type safety when matching objects in TypeScript tests
const expectMatchObject = <T extends object>(actual: T, expected: T) => {
  expect(actual).toMatchObject(expected);
};

describe('serverRenderReactComponent', () => {
  beforeEach(() => {
    ComponentRegistry.components().clear();
  });

  it('serverRenderReactComponent renders a registered component', () => {
    const X1: React.FC = () => React.createElement('div', null, 'HELLO');
    ComponentRegistry.register({ X1 });

    const renderParams: RenderParams = {
      name: 'X1',
      domNodeId: 'myDomId',
      trace: false,
      throwJsErrors: false,
      renderingReturnsPromises: false,
    };

    const renderResult = serverRenderReactComponent(renderParams);
    assertIsString(renderResult);
    const { html, hasErrors }: RenderResult = JSON.parse(renderResult) as RenderResult;

    const result = html && html.indexOf('>HELLO</div>') > 0;
    expect(result).toBeTruthy();
    expect(hasErrors).toBeFalsy();
  });

  it('serverRenderReactComponent renders errors', () => {
    const X2: React.FC = () => {
      throw new Error('XYZ');
    };

    ComponentRegistry.register({ X2 });

    const renderParams: RenderParams = {
      name: 'X2',
      domNodeId: 'myDomId',
      trace: false,
      throwJsErrors: false,
      renderingReturnsPromises: false,
    };

    const renderResult = serverRenderReactComponent(renderParams);
    assertIsString(renderResult);
    const { html, hasErrors }: RenderResult = JSON.parse(renderResult) as RenderResult;

    const result = html && html.indexOf('XYZ') > 0 && html.indexOf('Exception in rendering!') > 0;
    expect(result).toBeTruthy();
    expect(hasErrors).toBeTruthy();
  });

  it('serverRenderReactComponent renders html', () => {
    const expectedHtml = '<div>Hello</div>';
    const X3: RenderFunction = (_: unknown, __?: RailsContext): { renderedHtml: string } => ({
      renderedHtml: expectedHtml,
    });

    ComponentRegistry.register({ X3 });

    const renderParams: RenderParams = {
      name: 'X3',
      domNodeId: 'myDomId',
      trace: false,
      throwJsErrors: false,
      renderingReturnsPromises: false,
    };

    const renderResult = serverRenderReactComponent(renderParams);
    assertIsString(renderResult);
    const { html, hasErrors }: RenderResult = JSON.parse(renderResult) as RenderResult;

    expect(html).toEqual(expectedHtml);
    expect(hasErrors).toBeFalsy();
  });

  it('serverRenderReactComponent renders an error if attempting to render a renderer', () => {
    const X4: RenderFunction = (
      _props: unknown,
      _railsContext?: RailsContext,
      _domNodeId?: string,
    ): RenderFunctionResult => ({ renderedHtml: '' });

    ComponentRegistry.register({ X4 });

    const renderParams: RenderParams = {
      name: 'X4',
      domNodeId: 'myDomId',
      trace: false,
      throwJsErrors: false,
      renderingReturnsPromises: false,
    };

    const renderResult = serverRenderReactComponent(renderParams);
    assertIsString(renderResult);
    const { html, hasErrors }: RenderResult = JSON.parse(renderResult) as RenderResult;

    const result = html && html.indexOf('renderer') > 0 && html.indexOf('Exception in rendering!') > 0;
    expect(result).toBeTruthy();
    expect(hasErrors).toBeTruthy();
  });

  it('serverRenderReactComponent renders promises', async () => {
    const expectedHtml = '<div>Hello</div>';
    const X5: RenderFunction = (_props: unknown, _railsContext?: RailsContext): Promise<string> =>
      Promise.resolve(expectedHtml);

    ComponentRegistry.register({ X5 });

    const renderParams: RenderParams = {
      name: 'X5',
      domNodeId: 'myDomId',
      trace: false,
      throwJsErrors: false,
      renderingReturnsPromises: true,
    };

    const renderResult = serverRenderReactComponent(renderParams);
    assertIsPromise(renderResult);
    const html = await renderResult.then((r) => r.html);

    expect(html).toEqual(expectedHtml);
    await expect(renderResult.then((r) => r.hasErrors)).resolves.toBeFalsy();
  });

  it('serverRenderReactComponent renders promise of server side hash result', async () => {
    const expectedHtml = '<div>Hello</div>';
    const X6 = ((_props: unknown, _railsContext?: RailsContext): Promise<ServerRenderResult> =>
      Promise.resolve({ renderedHtml: expectedHtml })) as RenderFunction;

    ComponentRegistry.register({ X6 });

    const renderParams: RenderParams = {
      name: 'X6',
      domNodeId: 'myDomId',
      trace: false,
      throwJsErrors: false,
      renderingReturnsPromises: true,
    };

    const renderResult = serverRenderReactComponent(renderParams);
    assertIsPromise(renderResult);
    const html = (await renderResult.then((r) => r.html)) as ServerRenderResult;
    expectMatchObject(html, { renderedHtml: expectedHtml });
  });
});

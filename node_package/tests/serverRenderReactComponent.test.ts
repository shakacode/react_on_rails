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

  it('serverRenderReactComponent renders html renderedHtml property', () => {
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

  it("doesn't render object without renderedHtml property", () => {
    const X4 = (_props: unknown, _railsContext?: RailsContext): { foo: string } => ({
      foo: 'bar',
    });

    ComponentRegistry.register({ X4: X4 as unknown as RenderFunction });
    const renderResult = serverRenderReactComponent({
      name: 'X4',
      domNodeId: 'myDomId',
      trace: false,
      throwJsErrors: false,
      renderingReturnsPromises: false,
    });
    assertIsString(renderResult);
    const { html, hasErrors }: RenderResult = JSON.parse(renderResult) as RenderResult;

    expect(html).toContain('Exception in rendering!');
    expect(html).toContain('Element type is invalid');
    expect(hasErrors).toBeTruthy();
  });

  // If a render function returns a string, serverRenderReactComponent will interpret it as a React component type.
  // For example, if the render function returns the string 'div', it will be treated as if React.createElement('div', props)
  // was called. Thus, calling `serverRenderReactComponent({ name: 'X4', props: { foo: 'bar' } })` with a render function
  // that returns 'div' will result in the HTML `<div foo="bar"></div>`.
  // This behavior is an unintended side effect of the implementation.
  // If the render function returns a real HTML string, it will most likely throw an invalid tag React error.
  // For example, calling `serverRenderReactComponent({ name: 'X4', props: { foo: 'bar' } })` with a render function
  // that returns '<div>Hello</div>' will result in the error:
  // "Error: Invalid tag name <div>Hello</div>"
  it("doesn't render html string returned directly from render function", () => {
    const expectedHtml = '<div>Hello</div>';
    const X4: RenderFunction = (_props: unknown, _railsContext?: RailsContext): string => expectedHtml;

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

    // Instead of expecting exact strings, check that it contains key parts of the error
    expect(html).toContain('Exception in rendering!');
    expect(html).toContain('Invalid tag');
    expect(html).toContain('div&gt;Hello&lt;/div');
    expect(hasErrors).toBeTruthy();
  });

  it('serverRenderReactComponent renders promise of string html', async () => {
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

  // When an async render function returns an object, serverRenderReactComponent will return the object as it after stringifying it.
  // It does not validate properties like renderedHtml or hasErrors; it simply returns the stringified object.
  // This behavior can cause issues with the ruby_on_rails gem.
  // To avoid such issues, ensure that the returned object includes a `componentHtml` property and use the `react_component_hash` helper.
  // This is demonstrated in the "can render async render function used with react_component_hash helper" test.
  it('serverRenderReactComponent returns the object returned by the async render function', async () => {
    const resultObject = { renderedHtml: '<div>Hello</div>' };
    const X6 = ((_props: unknown, _railsContext?: RailsContext): Promise<ServerRenderResult> =>
      Promise.resolve(resultObject)) as RenderFunction;

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
    const html = await renderResult.then((r) => r.html);
    expect(html).toEqual(JSON.stringify(resultObject));
  });

  // Because the object returned by the async render function is returned as it is,
  // we can make the async render function returns an object with `componentHtml` property.
  // This is useful when we want to render a component using the `react_component_hash` helper.
  it('can render async render function used with react_component_hash helper', async () => {
    const reactComponentHashResult = { componentHtml: '<div>Hello</div>' };
    const X7 = (_props: unknown, _railsContext?: RailsContext) => Promise.resolve(reactComponentHashResult);

    ComponentRegistry.register({ X7 });

    const renderParams: RenderParams = {
      name: 'X7',
      domNodeId: 'myDomId',
      trace: false,
      throwJsErrors: false,
      renderingReturnsPromises: true,
    };

    const renderResult = serverRenderReactComponent(renderParams);
    assertIsPromise(renderResult);
    const result = await renderResult;
    expect(result.html).toEqual(JSON.stringify(reactComponentHashResult));
  });

  it('serverRenderReactComponent renders async render function that returns react component', async () => {
    const X8 = (_props: unknown, _railsContext?: RailsContext) =>
      Promise.resolve(() => React.createElement('div', null, 'Hello'));
    ComponentRegistry.register({ X8 });

    const renderResult = serverRenderReactComponent({
      name: 'X8',
      domNodeId: 'myDomId',
      trace: false,
      throwJsErrors: false,
      renderingReturnsPromises: true,
    });
    assertIsPromise(renderResult);
    const result = await renderResult;
    expect(result.html).toEqual('<div>Hello</div>');
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
});

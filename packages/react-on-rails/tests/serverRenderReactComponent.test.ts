import * as React from 'react';
import serverRenderReactComponent from '../src/serverRenderReactComponent.ts';
import ComponentRegistry from '../src/ComponentRegistry.ts';
import type {
  RenderParams,
  RenderResult,
  RailsContext,
  RenderFunction,
  RenderFunctionResult,
} from '../src/types/index.ts';

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

describe('serverRenderReactComponent', () => {
  beforeEach(() => {
    ComponentRegistry.components().clear();
    // Setup globalThis.ReactOnRails for serverRenderReactComponent
    // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/unbound-method, @typescript-eslint/no-explicit-any
    globalThis.ReactOnRails = { getComponent: ComponentRegistry.get } as any;
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

    assertIsString(html);
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

    assertIsString(html);
    const result = html && html.indexOf('XYZ') > 0 && html.indexOf('Exception in rendering!') > 0;
    expect(result).toBeTruthy();
    expect(hasErrors).toBeTruthy();
  });

  it('serverRenderReactComponent renders html renderedHtml property', () => {
    const expectedHtml = '<div>Hello</div>';
    const X3: RenderFunction = () => ({
      renderedHtml: expectedHtml,
    });
    X3.renderFunction = true;

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
    const X4 = (): { foo: string } => ({
      foo: 'bar',
    });
    X4.renderFunction = true;

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
    const X4: RenderFunction = (): string => expectedHtml;
    X4.renderFunction = true;

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
    const X5: RenderFunction = (): Promise<string> => Promise.resolve(expectedHtml);
    X5.renderFunction = true;

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

  // When an async render function returns an object, serverRenderReactComponent will return the object as it is.
  // It does not validate properties like renderedHtml or hasErrors; it simply returns the object.
  // This behavior can cause issues with the ruby_on_rails gem.
  // To avoid such issues, ensure that the returned object includes a `componentHtml` property and use the `react_component_hash` helper.
  // This is demonstrated in the "can render async render function used with react_component_hash helper" test.
  it('serverRenderReactComponent returns the object returned by the async render function', async () => {
    const resultObject = { renderedHtml: '<div>Hello</div>' };
    const X6 = (() => Promise.resolve(resultObject)) as RenderFunction;
    X6.renderFunction = true;

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
    expect(html).toMatchObject(resultObject);
  });

  // Because the object returned by the async render function is returned as it is,
  // we can make the async render function returns an object with `componentHtml` property.
  // This is useful when we want to render a component using the `react_component_hash` helper.
  it('can render async render function used with react_component_hash helper', async () => {
    const reactComponentHashResult = { componentHtml: '<div>Hello</div>' };
    const X7: RenderFunction = () => Promise.resolve(reactComponentHashResult);
    X7.renderFunction = true;

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
    expect(result.html).toMatchObject(reactComponentHashResult);
  });

  it('serverRenderReactComponent renders async render function that returns react component', async () => {
    const X8: RenderFunction = () => Promise.resolve(() => React.createElement('div', null, 'Hello'));
    X8.renderFunction = true;

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
    expect(result.html).toBe('<div>Hello</div>');
  });

  it('serverRenderReactComponent renders an error if attempting to render a renderer', () => {
    const X4: RenderFunction = (
      // eslint-disable-next-line @typescript-eslint/no-unused-vars
      _props: unknown,
      // eslint-disable-next-line @typescript-eslint/no-unused-vars
      _railsContext?: RailsContext,
      // eslint-disable-next-line @typescript-eslint/no-unused-vars
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

    assertIsString(html);
    const result = html && html.indexOf('renderer') > 0 && html.indexOf('Exception in rendering!') > 0;
    expect(result).toBeTruthy();
    expect(hasErrors).toBeTruthy();
  });
});

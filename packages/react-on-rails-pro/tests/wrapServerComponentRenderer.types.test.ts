import type { ReactComponent, RendererFunction } from 'react-on-rails/types';
import type wrapServerComponentRenderer from '../src/wrapServerComponentRenderer/client.tsx';

type WrapServerComponentRenderer = typeof wrapServerComponentRenderer;

declare const component: ReactComponent;
declare const typedPropsRenderFunction: (
  props: { id: string } | undefined,
  railsContext: unknown,
) => ReactComponent;
declare const componentRenderFunction: (
  props?: Record<string, unknown>,
  railsContext?: unknown,
  domNodeId?: string,
) => ReactComponent;
declare const rendererReturningTeardown: RendererFunction;
declare const typedWrapServerComponentRenderer: WrapServerComponentRenderer;

if (false) {
  typedWrapServerComponentRenderer(component, 'Component');
  typedWrapServerComponentRenderer(typedPropsRenderFunction, 'TypedPropsRenderFunction');
  typedWrapServerComponentRenderer(componentRenderFunction, 'ComponentRenderFunction');

  // @ts-expect-error registerServerComponent render functions must resolve to React components, not renderer teardowns.
  typedWrapServerComponentRenderer(rendererReturningTeardown, 'RendererTeardown');
}

describe('wrapServerComponentRenderer types', () => {
  it('compiles type assertions for server-component render-function inputs', () => {
    expect(true).toBe(true);
  });
});

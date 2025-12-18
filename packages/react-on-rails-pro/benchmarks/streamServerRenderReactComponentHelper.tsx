import ReactOnRails from '../src/ReactOnRails.node.ts';
import { RailsContext, ReactComponentOrRenderFunction } from 'react-on-rails/types';

const mockRailsContext = {
  reactClientManifestFileName: 'react-client-manifest.json',
  reactServerClientManifestFileName: 'react-server-client-manifest.json',
} as unknown as RailsContext;

let componentId = 0;

export default function streamComponent(
  component: ReactComponentOrRenderFunction,
  props: Record<string, unknown> = {},
) {
  const componentName = `tmpComponentForBenchmarking${componentId}`;
  componentId += 1;
  ReactOnRails.register({ [componentName]: component });
  return ReactOnRails.streamServerRenderedReactComponent({
    name: componentName,
    renderingReturnsPromises: true,
    throwJsErrors: true,
    railsContext: mockRailsContext,
    domNodeId: 'root',
    props,
  });
}

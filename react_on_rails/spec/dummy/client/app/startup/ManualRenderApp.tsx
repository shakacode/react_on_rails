import React from 'react';
import { createRoot, hydrateRoot } from 'react-dom/client';
import type { RailsContext } from 'react-on-rails/types';

import { wrapElementInStrictMode } from '../strictModeSupport';

type ManualRenderProps = Record<string, unknown> & {
  prerender?: boolean;
};

type RendererFunction = (props: ManualRenderProps, railsContext: RailsContext, domNodeId: string) => void;

const ManualRenderApp: RendererFunction = (props, _railsContext, domNodeId) => {
  const reactElement = wrapElementInStrictMode(
    <div>
      <h1 id="manual-render">Manual Render Example</h1>
      <p>If you can see this, you can register renderer functions.</p>
    </div>,
  );

  const domNode = document.getElementById(domNodeId);

  if (!domNode) {
    throw new Error(`Could not find DOM node with id '${domNodeId}' for ManualRenderApp.`);
  }
  if (props.prerender) {
    hydrateRoot(domNode, reactElement);
  } else {
    const root = createRoot(domNode);
    root.render(reactElement);
  }
};

export default ManualRenderApp;

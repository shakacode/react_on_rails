/* eslint-disable no-underscore-dangle */
import React, { useEffect } from 'react';
import { createRoot } from 'react-dom/client';

// A monotonic counter is the canary: useEffect cleanup increments it only when
// React actually unmounts the tree (via root.unmount()). If the framework discards
// the teardown returned below, navigation happens, Turbo throws away the cached
// body, and the root is leaked — useEffect cleanup never runs and the counter
// stays at its initial value. Counter (vs. boolean) so re-rendering on the same
// page can't overwrite a true value back to false.
const TrackedTree = () => {
  useEffect(
    () => () => {
      window.__rendererCleanupCount__ = (window.__rendererCleanupCount__ || 0) + 1;
    },
    [],
  );
  return <div data-testid="renderer-cleanup-tree">Renderer Cleanup Test Tree</div>;
};

const RendererCleanupTest = (_props, _railsContext, domNodeId) => {
  const mountNode = document.getElementById(domNodeId);
  if (!mountNode) {
    throw new Error(`RendererCleanupTest: DOM node #${domNodeId} not found`);
  }
  const root = createRoot(mountNode);
  root.render(<TrackedTree />);
  // Issue #3209: returning a teardown is the new contract. Today react-on-rails
  // discards this return value; once the issue is implemented the framework will
  // invoke it on `turbo:before-render` and on same-id node replacement.
  return () => root.unmount();
};

export default RendererCleanupTest;

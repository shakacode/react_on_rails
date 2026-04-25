import React, { useEffect } from 'react';
import { createRoot } from 'react-dom/client';

// useEffect cleanup is the canary: it only fires when React actually unmounts the
// tree (via root.unmount()). If the framework calls the teardown returned below,
// React unmounts and we set window.__rendererCleanupRan__ = true. If the framework
// discards the teardown (current behavior), navigation happens, the cached body is
// thrown away by Turbo, and the React root is leaked — useEffect cleanup never runs.
const TrackedTree = () => {
  useEffect(
    () => () => {
      window.__rendererCleanupRan__ = true;
    },
    [],
  );
  return <div data-testid="renderer-cleanup-tree">Renderer Cleanup Test Tree</div>;
};

const RendererCleanupTest = (_props, _railsContext, domNodeId) => {
  window.__rendererCleanupRan__ = false;
  const root = createRoot(document.getElementById(domNodeId));
  root.render(<TrackedTree />);
  // Issue #3209: returning a teardown is the new contract. Today react-on-rails
  // discards this return value; once the issue is implemented the framework will
  // invoke it on `turbo:before-render` and on same-id node replacement.
  return () => root.unmount();
};

export default RendererCleanupTest;

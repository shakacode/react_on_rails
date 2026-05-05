/* eslint-disable no-underscore-dangle */
import React, { useEffect } from 'react';
import { createRoot } from 'react-dom/client';

// The cleanup inside useEffect runs only when React unmounts the tree (via
// root.unmount()). When the framework invokes the teardown returned below,
// root.unmount() runs, React fires this cleanup, and the counter on window
// goes up. We use a counter rather than a boolean flag so that re-rendering
// on the same page can't reset a previous "did unmount" signal back to false.
const TrackedTree = () => {
  useEffect(
    () => () => {
      window.__rendererCleanupCount__ = (window.__rendererCleanupCount__ || 0) + 1;
      const storedCount = Number(window.localStorage.getItem('__rendererCleanupCount__') || 0);
      window.localStorage.setItem('__rendererCleanupCount__', String(storedCount + 1));
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
  // Returning a teardown lets the framework unmount this root on Turbo
  // navigation and when the same DOM node is replaced.
  return () => root.unmount();
};

export default RendererCleanupTest;

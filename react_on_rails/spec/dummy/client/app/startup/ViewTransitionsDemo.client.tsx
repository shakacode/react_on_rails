// View Transitions demo component (issue #3888).
//
// EXPERIMENTAL / UNSUPPORTED. Demonstrates the CSR recipe from
// docs/oss/building-features/view-transitions.md: wrapping a React state
// update in document.startViewTransition() (when available) so the browser
// animates between the before/after DOM states. Unsupported browsers apply
// the same update without animation.
//
// This demo is inert by default: its route only exists when the dummy app is
// booted with VIEW_TRANSITIONS_DEMO=true (see config/routes.rb). The page
// renders client-side only (prerender: false), so it is safe to feature-detect
// the browser API during render here; server-rendered components must only
// touch the API inside event handlers or effects.
import React, { useState } from 'react';
import { flushSync } from 'react-dom';

// document.startViewTransition may be missing from older TS DOM libs and from
// older browsers, so type and feature-detect it defensively.
type DocumentWithViewTransition = Document & {
  startViewTransition?: (updateCallback: () => void) => unknown;
};

const ViewTransitionsDemo = (): React.ReactElement => {
  const [expanded, setExpanded] = useState(false);

  const supportsViewTransitions =
    typeof (document as DocumentWithViewTransition).startViewTransition === 'function';

  const toggle = () => {
    const applyUpdate = () => {
      // flushSync forces React to commit the update synchronously inside the
      // startViewTransition callback, where the browser snapshots the "new"
      // page state.
      flushSync(() => {
        setExpanded((prev) => !prev);
      });
    };

    const doc = document as DocumentWithViewTransition;
    if (typeof doc.startViewTransition === 'function') {
      doc.startViewTransition(applyUpdate);
    } else {
      applyUpdate();
    }
  };

  return (
    <div>
      <p data-testid="vt-demo-support">
        {supportsViewTransitions
          ? 'This browser supports document.startViewTransition — toggling below animates.'
          : 'This browser lacks document.startViewTransition — toggling below updates without animation.'}
      </p>
      <button type="button" onClick={toggle}>
        Toggle panel
      </button>
      <div
        id="vt-demo-box"
        data-testid="vt-demo-box"
        style={{
          marginTop: 12,
          padding: expanded ? 24 : 8,
          width: expanded ? 320 : 160,
          background: expanded ? '#2563eb' : '#9ca3af',
          color: '#fff',
          borderRadius: 8,
        }}
      >
        {expanded ? 'Expanded' : 'Collapsed'}
      </div>
    </div>
  );
};

export default ViewTransitionsDemo;

// View Transitions demo component (issue #3888).
//
// EXPERIMENTAL / UNSUPPORTED. Demonstrates the CSR recipe from
// docs/oss/building-features/view-transitions.md: wrapping a React state
// update in document.startViewTransition() (when available) so the browser
// animates between the before/after DOM states. Unsupported browsers apply
// the same update without animation.
//
// This demo is inert by default: its route only exists when the dummy app is
// booted with VIEW_TRANSITIONS_DEMO=true (see config/routes.rb). Feature
// detection happens in a useEffect after mount, so the pattern is also safe to
// copy into SSR-hydrated components (document does not exist during server
// render).
import React, { useEffect, useState } from 'react';
import { flushSync } from 'react-dom';

// document.startViewTransition may be missing from older TS DOM libs and from
// older browsers, so type and feature-detect it defensively.
type DocumentWithViewTransition = Document & {
  startViewTransition?: (updateCallback: () => void) => unknown;
};

const ViewTransitionsDemo = (): React.ReactElement => {
  const [expanded, setExpanded] = useState(false);
  const [supportsViewTransitions, setSupportsViewTransitions] = useState(false);

  // Detect after mount so this pattern is safe to copy for SSR-hydrated
  // components too. The handler below only runs post-mount, so branching on
  // the state value is reliable; the initial false value is harmless.
  useEffect(() => {
    setSupportsViewTransitions(
      typeof (document as DocumentWithViewTransition).startViewTransition === 'function',
    );
  }, []);

  const toggle = () => {
    const applyUpdate = () => {
      // flushSync forces React to commit the update synchronously inside the
      // startViewTransition callback, where the browser snapshots the "new"
      // page state.
      flushSync(() => {
        setExpanded((prev) => !prev);
      });
    };

    // Inline detection (the doc's withViewTransition pattern): the fallback
    // always fires, so the toggle never silently no-ops. The state above is
    // only for the display text.
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
      <button type="button" onClick={toggle} aria-expanded={expanded} aria-controls="vt-demo-box">
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

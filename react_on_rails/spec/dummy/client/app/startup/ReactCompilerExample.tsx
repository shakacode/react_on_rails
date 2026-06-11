// React Compiler example component (issue #3866).
//
// This component is the scoped target for the React Compiler in this dummy app.
// The Babel React Compiler plugin is enabled ONLY for this file via the
// `sources` filter in `babel.config.js`, so the rest of the dummy build is
// unaffected. See docs/oss/building-features/react-compiler.md.
//
// It is deliberately written WITHOUT manual `useMemo` / `useCallback` /
// `React.memo`. When the compiler runs, it auto-memoizes the derived list and
// the click handler; when it is off (e.g. the default SWC build, or any build
// where the `sources` filter excludes this file) the component still renders
// and SSRs correctly — just without the automatic memoization.
import React, { useState } from 'react';

export type ReactCompilerExampleProps = {
  // Starting count for the demo list. Defaults to a small value so the
  // component renders cleanly under SSR with no props.
  initialCount?: number;
  greeting?: string;
};

function expensiveLabel(n: number): string {
  // Stand-in for derived work the compiler will memoize across re-renders.
  return `item #${n} (square ${n * n})`;
}

const ReactCompilerExample = ({
  initialCount = 3,
  greeting = 'React Compiler is on for this component',
}: ReactCompilerExampleProps) => {
  const [count, setCount] = useState(initialCount);

  // Derived data: no manual useMemo. With the compiler enabled this is
  // memoized automatically and only recomputed when `count` changes.
  const items = Array.from({ length: count }, (_, i) => expensiveLabel(i + 1));

  // Inline handler: no manual useCallback. The compiler stabilizes it.
  const increment = () => setCount((current) => current + 1);

  return (
    <div className="react-compiler-example">
      <h3>{greeting}</h3>
      <p>
        This component uses no manual <code>useMemo</code>/<code>useCallback</code>; the React Compiler adds
        memoization at build time.
      </p>
      <button type="button" onClick={increment}>
        Add item (count: {count})
      </button>
      <ul>
        {items.map((label) => (
          <li key={label}>{label}</li>
        ))}
      </ul>
    </div>
  );
};

export default ReactCompilerExample;

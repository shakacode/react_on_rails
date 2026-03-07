'use client';

import React from 'react';

/**
 * Demonstrates React 19's native document metadata with synchronous SSR.
 *
 * React 19 supports rendering <title>, <meta>, and <link> anywhere in the component
 * tree. During client-side hydration, React automatically hoists them to <head>.
 *
 * This component has NO Suspense boundaries, so it works with react_component
 * (which uses renderToString under the hood).
 *
 * Migration from react-helmet:
 *   Before: <Helmet><title>My Title</title></Helmet>
 *   After:  <title>My Title</title>
 *
 * No HelmetProvider, no renderToString wrapper, no render function returning a hash.
 * Just render the tags directly and React 19 handles the rest.
 */
const NativeMetadataSyncApp = ({ helloWorldData }) => {
  const { name } = helloWorldData;

  return (
    <div>
      {/* React 19: these tags are rendered in <body> during SSR, */}
      {/* then hoisted to <head> by React during client hydration */}
      <title>{`${name}'s Profile | React on Rails`}</title>
      <meta name="description" content={`Profile page for ${name} - rendered with React 19 native metadata`} />
      <meta property="og:title" content={`${name}'s Profile | React on Rails`} />
      <meta property="og:site_name" content="React on Rails Demo" />
      <link rel="canonical" href="https://example.com/profile" />

      <h1>React 19 Native Metadata (Sync SSR)</h1>
      <p>
        This component renders <code>&lt;title&gt;</code>, <code>&lt;meta&gt;</code>, and{' '}
        <code>&lt;link&gt;</code> tags directly — no react-helmet needed.
      </p>
      <p>
        <strong>Server-rendered HTML:</strong> The metadata tags appear inside the component&apos;s{' '}
        <code>&lt;div&gt;</code> in <code>&lt;body&gt;</code>.
      </p>
      <p>
        <strong>After hydration:</strong> React 19 automatically hoists them to{' '}
        <code>&lt;head&gt;</code>. Check the page title — it says &quot;{name}&apos;s Profile | React
        on Rails&quot;.
      </p>

      <hr />

      <h3>Profile: {name}</h3>
      <p>This content renders synchronously, suitable for use with <code>react_component</code>.</p>
    </div>
  );
};

export default NativeMetadataSyncApp;

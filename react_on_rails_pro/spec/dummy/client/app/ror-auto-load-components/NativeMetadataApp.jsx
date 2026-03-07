'use client';

import React, { Suspense } from 'react';

/**
 * Async component that simulates data fetching and sets metadata upon completion.
 *
 * When used with streaming (stream_react_component), this component triggers a
 * Suspense boundary: the shell renders first with the initial <title>, then this
 * content streams later and React 19 updates the document <title> on the client.
 *
 * When used with sync SSR (react_component), React renders everything at once
 * and the final <title> wins.
 */
const AsyncProfileContent = async ({ name }) => {
  // Simulate async data fetching (e.g., database query, API call)
  if (typeof window === 'undefined') {
    await new Promise((resolve) => {
      setTimeout(resolve, 1000);
    });
  }

  return (
    <>
      {/* React 19: this <title> is automatically hoisted to <head> */}
      <title>{`${name}'s Profile | React on Rails`}</title>
      <meta name="description" content={`Profile page for ${name} - loaded via streaming`} />

      <div>
        <h2>Profile: {name}</h2>
        <p>This content was loaded asynchronously on the server via React Suspense streaming.</p>
        <p>
          When this Suspense boundary resolved, React 19 updated the document title to &quot;
          {name}&apos;s Profile | React on Rails&quot; using native &lt;title&gt; hoisting.
        </p>
      </div>
    </>
  );
};

/**
 * Demonstrates React 19's native document metadata hoisting.
 *
 * React 19 supports rendering <title>, <meta>, and <link> anywhere in the component
 * tree and automatically hoists them to the document <head>. This eliminates the need
 * for react-helmet in many cases.
 *
 * This component works with both:
 * - react_component (sync SSR): all metadata renders at once
 * - stream_react_component (streaming): initial metadata in the shell, updated after Suspense resolves
 *
 * Migration from react-helmet:
 * - Before: <Helmet><title>My Title</title></Helmet>
 * - After:  <title>My Title</title>
 */
const NativeMetadataApp = ({ helloWorldData }) => {
  const { name } = helloWorldData;

  return (
    <div>
      {/* Initial metadata - rendered in the shell (first streaming chunk) */}
      <title>Loading... | React on Rails</title>
      <meta name="og:site_name" content="React on Rails Demo" />

      <h1>React 19 Native Document Metadata</h1>
      <p>
        This component uses React 19&apos;s built-in &lt;title&gt; and &lt;meta&gt; tags instead of
        react-helmet. React automatically hoists them to the document &lt;head&gt;.
      </p>
      <p>
        <strong>How it works:</strong> The initial title is &quot;Loading... | React on Rails&quot;.
        Once the async content below loads, the title updates to &quot;{name}&apos;s Profile | React
        on Rails&quot;.
      </p>

      <hr />

      <h3>Async Content (loaded via Suspense):</h3>
      <Suspense fallback={<div>Loading profile for {name}...</div>}>
        <AsyncProfileContent name={name} />
      </Suspense>
    </div>
  );
};

export default NativeMetadataApp;

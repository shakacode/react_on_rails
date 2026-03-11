import React, { Suspense } from 'react';

/**
 * Async server component that fetches data and renders metadata.
 *
 * This runs ONLY on the server (no 'use client' directive). It demonstrates
 * React 19's native <title>, <meta>, and <link> inside a React Server Component.
 *
 * During HTML streaming (renderToPipeableStream), React hoists these tags
 * directly into the <head> section of the streamed HTML response.
 * During RSC payload generation, the Flight protocol serializes them and
 * the client-side React runtime hoists them into <head> during hydration.
 */
const AsyncProfileContent = async ({ name }) => {
  // Simulate async data fetching (e.g., database query, API call)
  await new Promise((resolve) => {
    setTimeout(resolve, 1000);
  });

  return (
    <>
      {/* React 19: these tags are hoisted to <head> by renderToPipeableStream */}
      <title>{`${name}'s Profile | React on Rails`}</title>
      <meta name="description" content={`Profile page for ${name} - rendered via RSC streaming`} />

      <div>
        <h2>Profile: {name}</h2>
        <p>
          This content was fetched asynchronously inside a <strong>React Server Component</strong>.
        </p>
        <p>
          The <code>&lt;title&gt;</code> and <code>&lt;meta&gt;</code> tags above were rendered on the server
          and hoisted to <code>&lt;head&gt;</code> by React 19.
        </p>
      </div>
    </>
  );
};

/**
 * RSC entry point demonstrating React 19's native document metadata.
 *
 * This component is auto-loaded (registered via `registerServerComponent` by the
 * pack generator because it has no 'use client' directive). In hand-crafted bundle
 * files, you would call `registerServerComponent({ NativeMetadataRSCApp })` explicitly.
 *
 * As a React Server Component (no 'use client' directive), it:
 * - Runs exclusively on the server (Node renderer)
 * - Can perform async operations (data fetching, file I/O, etc.)
 * - Can render <title>, <meta>, <link> which React 19 hoists to <head>
 */
const NativeMetadataRSCApp = ({ helloWorldData }) => {
  const { name } = helloWorldData;

  return (
    <div>
      {/* Initial metadata — rendered in the shell (first streaming chunk) */}
      <title>Loading... | React on Rails</title>
      <meta property="og:site_name" content="React on Rails Demo" />
      <link rel="canonical" href="https://example.com/profile" />
      {/* placeholder — use the real page URL in production */}
      <h1>React 19 Native Metadata in RSC</h1>
      <p>
        This page is rendered by a <strong>React Server Component</strong> (no &apos;use client&apos;
        directive). The <code>&lt;title&gt;</code>, <code>&lt;meta&gt;</code>, and <code>&lt;link&gt;</code>{' '}
        tags are rendered on the server and hoisted to <code>&lt;head&gt;</code> by React 19.
      </p>
      <p>
        <strong>How it works:</strong> The initial title is &quot;Loading... | React on Rails&quot;. When the
        async content below loads (~1s), the title updates to &quot;{name}&apos;s Profile | React on
        Rails&quot;.
      </p>
      <hr />
      <h3>Async Server Content (loaded via Suspense):</h3>
      <Suspense fallback={<div>Loading profile for {name}...</div>}>
        <AsyncProfileContent name={name} />
      </Suspense>
    </div>
  );
};

export default NativeMetadataRSCApp;

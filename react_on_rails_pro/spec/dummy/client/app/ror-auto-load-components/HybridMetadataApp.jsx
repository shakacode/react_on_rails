'use client';

import React, { Suspense } from 'react';

/**
 * Delayed client component that demonstrates streamed body content while Rails
 * owns the page metadata.
 */
const HybridMetadataProfileContent = ({ name }) => {
  return (
    <div>
      <h2>Profile: {name}</h2>
      <p>This content resolved through a delayed lazy import inside a Suspense boundary.</p>
      <p>
        The page title and meta description are set by the <strong>Rails controller</strong>, not by this
        React component. They appear in the initial HTML &lt;head&gt; before any JavaScript executes, making
        this approach ideal for SEO-critical streaming pages.
      </p>
    </div>
  );
};

const AsyncProfileContent = React.lazy(
  () =>
    new Promise((resolve) => {
      setTimeout(() => {
        resolve({ default: HybridMetadataProfileContent });
      }, 1000);
    }),
);

/**
 * Demonstrates the hybrid approach: Rails-side metadata + streaming React body.
 *
 * This is the recommended pattern for SEO-critical pages that need streaming:
 * - The Rails controller sets @page_title and @page_description
 * - The layout places them in <head> via content_for (sent in the first byte)
 * - This React component only renders the page body, streamed progressively
 *
 * Advantages over React 19 native metadata for SEO:
 * - Title/meta are in <head> from the very first HTTP response byte
 * - Works with crawlers that don't execute JavaScript
 * - No flash of "Loading..." in the document title
 */
const HybridMetadataApp = ({ helloWorldData }) => {
  const { name } = helloWorldData;

  return (
    <div>
      <h1>Hybrid: Rails Metadata + Streaming Body</h1>
      <p>
        This page sets its title and meta tags from the <strong>Rails controller</strong>, so they appear in
        &lt;head&gt; from the very first byte of the HTTP response.
      </p>
      <p>
        The React component body below streams progressively via Suspense, but the metadata is already in
        place for SEO crawlers.
      </p>

      <hr />

      <h3>Streamed Content:</h3>
      <Suspense fallback={<div>Loading profile for {name}...</div>}>
        <AsyncProfileContent name={name} />
      </Suspense>
    </div>
  );
};

export default HybridMetadataApp;

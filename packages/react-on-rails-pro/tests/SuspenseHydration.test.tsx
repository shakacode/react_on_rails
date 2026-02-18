import * as React from 'react';
import { Suspense } from 'react';
import { renderToReadableStream } from 'react-dom/server';
import { hydrateRoot } from 'react-dom/client';
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore - TypeScript error can be ignored because:
// 1. This test file is only executed when Node version >= 18
// 2. The package is guaranteed to be available at runtime in Node 18+ environments
import { screen, act, waitFor } from '@testing-library/react';
import '@testing-library/jest-dom';
import { getNodeVersion } from './testUtils.js';

/**
 * Tests React's Suspense hydration behavior for async components
 *
 * This test verifies that async components are only hydrated on the client side after:
 * 1. The component is rendered on the server
 * 2. The rendered HTML is streamed to the client
 *
 * This behavior is critical for RSCRoute components, as they require their server-side
 * RSC payload to be present in the page before client-side hydration can occur.
 * And because the RSCRoute is rendered on the server because it's being hydrated on the client,
 * we can sure that the RSC payload is present in the page before the RSCRoute is hydrated on the client.
 * That's because `getRSCPayloadStream` function embeds the RSC payload immediately to the HTML stream even before the RSCRoute is rendered on the server.
 * Without this guarantee, hydration would fail or produce incorrect results.
 */

const AsyncComponent = async ({
  promise,
  onRendered,
}: {
  promise: Promise<string>;
  onRendered: () => void;
}) => {
  const result = await promise;
  onRendered();
  return <div>{result}</div>;
};

const AsyncComponentContainer = ({
  onContainerRendered,
  onAsyncComponentRendered,
}: {
  onContainerRendered: () => void;
  onAsyncComponentRendered: () => void;
}) => {
  onContainerRendered();
  const promise = new Promise<string>((resolve) => {
    setTimeout(() => resolve('Hello World'), 0);
  });
  return (
    <Suspense fallback={<div>Loading...</div>}>
      <AsyncComponent promise={promise} onRendered={onAsyncComponentRendered} />
    </Suspense>
  );
};

// Function: appendHTMLWithScripts
// ------------------------------
// In a Jest/jsdom environment, scripts injected via innerHTML remain inert (they do not execute).
// Even with runScripts: 'dangerously', jsdom will not auto-execute <script> tags inserted as strings.
// This function addresses that by:
//  1. Parsing the HTML string into a DocumentFragment via a <template> element.
//  2. Locating each <script> node in the fragment (both inline and external).
//  3. Re-creating a fresh <script> element for each found script, copying over all attributes
//     (e.g., src, type, async, data-*, etc.) and inline code content.
//  4. Replacing the inert original <script> with the new element, which the browser/jsdom will execute.
//  5. Appending the entire fragment to the document in one operation, ensuring all non-script nodes
//     and newly created scripts are inserted correctly.
//
// Use this helper whenever you need to dynamically inject HTML containing scripts in tests and
// want to ensure those scripts run as they would in a real browser environment.
function appendHTMLWithScripts(htmlString: string) {
  const template = document.createElement('template');
  template.innerHTML = htmlString;
  const frag = template.content;

  // re-create each <script> so it executes
  frag.querySelectorAll('script').forEach((oldScript) => {
    const newScript = document.createElement('script');
    // copy attributes
    for (const { name, value } of oldScript.attributes) {
      newScript.setAttribute(name, value);
    }
    // copy inline code
    newScript.textContent = oldScript.textContent;

    // replace the inert one with the real one
    oldScript.replaceWith(newScript);
  });

  // finally append everything in one go
  document.body.appendChild(frag);
}

async function renderAndHydrate() {
  // create container div element
  const container = document.createElement('div');
  container.id = 'container';
  document.body.appendChild(container);

  const onContainerRendered = jest.fn();
  const onAsyncComponentRendered = jest.fn();
  const stream = await renderToReadableStream(
    <AsyncComponentContainer
      onContainerRendered={onContainerRendered}
      onAsyncComponentRendered={onAsyncComponentRendered}
    />,
  );

  const onContainerHydrated = jest.fn();
  const onAsyncComponentHydrated = jest.fn();
  const hydrate = () =>
    hydrateRoot(
      container,
      <AsyncComponentContainer
        onContainerRendered={onContainerHydrated}
        onAsyncComponentRendered={onAsyncComponentHydrated}
      />,
    );

  const reader = stream.getReader();
  const writeFirstChunk = async () => {
    const result = await reader.read();
    const decoded = new TextDecoder().decode(result.value as Buffer);
    container.innerHTML = decoded;
    return decoded;
  };

  const writeSecondChunk = async () => {
    let { done, value } = await reader.read();
    let decoded = '';
    while (!done) {
      decoded += new TextDecoder().decode(value as Buffer);
      // eslint-disable-next-line no-await-in-loop
      ({ done, value } = await reader.read());
    }

    appendHTMLWithScripts(decoded);
    return decoded;
  };

  return {
    onContainerRendered,
    onAsyncComponentRendered,
    onContainerHydrated,
    onAsyncComponentHydrated,
    writeFirstChunk,
    writeSecondChunk,
    hydrate,
  };
}

// React Server Components tests require React 19 and only run with Node version 18 (`newest` in our CI matrix)
(getNodeVersion() >= 18 ? describe : describe.skip)('RSCClientRoot', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    document.body.innerHTML = '';
  });

  it('hydrates the container when its content is written to the document', async () => {
    const { onContainerHydrated, onAsyncComponentHydrated, writeFirstChunk, hydrate } =
      await renderAndHydrate();

    await act(async () => {
      hydrate();
      await writeFirstChunk();
    });
    expect(await screen.findByText('Loading...')).toBeInTheDocument();
    expect(onContainerHydrated).toHaveBeenCalled();

    // The async component is not hydrated until the second chunk is written to the document
    await new Promise((resolve) => {
      setTimeout(resolve, 1000);
    });
    expect(onAsyncComponentHydrated).not.toHaveBeenCalled();
    expect(screen.getByText('Loading...')).toBeInTheDocument();
    expect(screen.queryByText('Hello World')).not.toBeInTheDocument();
  });

  it('hydrates the child async component when its content is written to the document', async () => {
    const { writeFirstChunk, writeSecondChunk, onAsyncComponentHydrated, onContainerHydrated, hydrate } =
      await renderAndHydrate();

    await act(async () => {
      hydrate();
      await writeFirstChunk();
    });
    expect(await screen.findByText('Loading...')).toBeInTheDocument();

    await act(async () => {
      const secondChunk = await writeSecondChunk();
      expect(secondChunk).toContain('script');
    });
    await waitFor(() => {
      expect(screen.queryByText('Loading...')).not.toBeInTheDocument();
    });
    expect(screen.getByText('Hello World')).toBeInTheDocument();

    expect(onContainerHydrated).toHaveBeenCalled();
    expect(onAsyncComponentHydrated).toHaveBeenCalled();
  });
});

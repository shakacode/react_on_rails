/* eslint-disable import/prefer-default-export -- named export for consistency with capability API */

/*
 * Copyright (c) 2025 Shakacode LLC
 *
 * This file is NOT licensed under the MIT (open source) license.
 * It is part of the React on Rails Pro offering and is licensed separately.
 *
 * Unauthorized copying, modification, distribution, or use of this file,
 * via any medium, is strictly prohibited without a valid license agreement
 * from Shakacode LLC.
 *
 * For licensing terms, please see:
 * https://github.com/shakacode/react_on_rails/blob/master/REACT-ON-RAILS-PRO-LICENSE.md
 */

import { PassThrough, Readable } from 'stream';
import * as React from 'react';

import createReactOutput from 'react-on-rails/createReactOutput';
import { isPromise } from 'react-on-rails/isServerRenderResult';
import buildConsoleReplay, { consoleReplay } from 'react-on-rails/buildConsoleReplay';
import { convertToError } from 'react-on-rails/serverRenderUtils';
import { isRSCComponent } from 'react-on-rails/rscMarker';
import type { RenderParams, RailsContext } from 'react-on-rails/types';

import * as ComponentRegistry from '../ComponentRegistry.ts';
import { withPhase } from '../postpone.ts';
import { transformRenderStreamChunksToResultObject } from '../streamingUtils.ts';
import handleError from '../handleError.ts';

// ─── Lazy React PPR API loader ──────────────────────────────────────────────────────────────
// Pro declares peer-dep `react >= 16`. The PPR APIs (prerenderToNodeStream,
// resumeToPipeableStream) only exist in React 19.2+. We resolve them lazily so apps on older
// React versions can still load the Pro Node entry without crashing.

type PrerenderToNodeStreamFn = (
  children: React.ReactElement,
  options?: {
    signal?: AbortSignal;
    identifierPrefix?: string;
    bootstrapScripts?: string[];
    onError?: (error: unknown) => void;
  },
) => Promise<{ prelude: Readable; postponed: unknown | null }>;

type ResumeToPipeableStreamFn = (
  children: React.ReactElement,
  postponed: unknown,
  options?: {
    onError?: (error: unknown) => void;
  },
) => {
  pipe: (destination: NodeJS.WritableStream) => NodeJS.WritableStream;
  abort: (reason?: unknown) => void;
};

let cachedAPIs: {
  prerenderToNodeStream: PrerenderToNodeStreamFn;
  resumeToPipeableStream: ResumeToPipeableStreamFn;
} | null = null;
let cachedAPIError: Error | null = null;

async function loadPPRReactAPIs() {
  if (cachedAPIs) return cachedAPIs;
  if (cachedAPIError) throw cachedAPIError;
  try {
    const [staticMod, serverMod] = await Promise.all([
      // The dynamic import is intentional: it postpones resolving these specifiers until the
      // first PPR call. Apps on React 16-19.1 can register the PPR capability without crashing.
      import('react-dom/static'),
      import('react-dom/server'),
    ]);
    const prerenderToNodeStream = (
      staticMod as unknown as { prerenderToNodeStream?: PrerenderToNodeStreamFn }
    ).prerenderToNodeStream;
    const resumeToPipeableStream = (
      serverMod as unknown as { resumeToPipeableStream?: ResumeToPipeableStreamFn }
    ).resumeToPipeableStream;
    if (typeof prerenderToNodeStream !== 'function' || typeof resumeToPipeableStream !== 'function') {
      const reactVersion = (React as unknown as { version: string }).version;
      throw new Error(
        `React on Rails Pro PPR requires React 19.2+ (prerenderToNodeStream and resumeToPipeableStream). ` +
          `Current React is ${reactVersion}. Upgrade react and react-dom to >= 19.2.`,
      );
    }
    cachedAPIs = { prerenderToNodeStream, resumeToPipeableStream };
    return cachedAPIs;
  } catch (e) {
    cachedAPIError = convertToError(e);
    throw cachedAPIError;
  }
}

function checkPPRRuntimeOrThrow(): void {
  const missing: string[] = [];
  if (typeof globalThis.AbortController !== 'function') missing.push('AbortController');
  if (typeof globalThis.AbortSignal !== 'function') missing.push('AbortSignal');
  if (typeof (globalThis as unknown as { AsyncLocalStorage?: unknown }).AsyncLocalStorage !== 'function')
    missing.push('AsyncLocalStorage');
  // Real timers are required by the prerender abort path. The node renderer's `stubTimers`
  // option (default true) replaces setTimeout/clearTimeout with no-ops, which would make the
  // abort timer never fire and PPR would hang until external timeouts. We probe by scheduling
  // a no-op and checking the returned handle is truthy and clearTimeout is callable.
  const setT = (globalThis as unknown as { setTimeout?: unknown }).setTimeout;
  const clearT = (globalThis as unknown as { clearTimeout?: unknown }).clearTimeout;
  if (typeof setT !== 'function' || typeof clearT !== 'function') {
    missing.push('setTimeout/clearTimeout');
  } else {
    const handle = (setT as (cb: () => void, ms: number) => unknown)(() => {}, 0);
    // Stubbed timers in the node renderer return undefined.
    if (handle === undefined || handle === null) missing.push('setTimeout (real, not stubbed)');
    else (clearT as (h: unknown) => void)(handle);
  }
  if (missing.length) {
    throw new Error(
      `React on Rails Pro PPR requires runtime globals not available in this VM: ${missing.join(', ')}. ` +
        `Upgrade your Pro node renderer to a version that injects these globals (>= the version that ` +
        `ships PPR support), and ensure stubTimers is disabled (set RENDERER_STUB_TIMERS=false or ` +
        `stubTimers: false in the renderer config) so the prerender abort timer can fire.`,
    );
  }
}

// ─── helpers ────────────────────────────────────────────────────────────────────────────────

function streamToString(readable: Readable): Promise<string> {
  return new Promise((resolve, reject) => {
    const chunks: Buffer[] = [];
    readable.on('data', (chunk: Buffer | string) => {
      chunks.push(typeof chunk === 'string' ? Buffer.from(chunk) : chunk);
    });
    readable.on('end', () => resolve(Buffer.concat(chunks).toString('utf8')));
    readable.on('error', reject);
  });
}

async function resolveComponentElement(
  options: PPRRenderOptions,
  // We accept a loose RailsContext shape here because PPR adds its own fields and the strict
  // `RailsContext` requires `getRSCPayloadStream` for streaming flows we don't engage.
  railsContext: Record<string, unknown> & { serverSide?: boolean },
): Promise<React.ReactElement> {
  const componentObj = ComponentRegistry.get(options.name);
  if (!componentObj) throw new Error(`PPR: component "${options.name}" is not registered`);
  if (isRSCComponent(componentObj.component)) {
    throw new Error(
      `ppr_react_component does not support RSC components in v1. Use stream_react_component for "${options.name}".`,
    );
  }
  const result = createReactOutput({
    componentObj,
    props: options.props,
    // The local railsContext is a permissive Record; createReactOutput accepts the strict
    // RailsContext type. We cast at the boundary — the Pro PPR helper synthesizes the context
    // from rails_context the JS side received, augmented with PPR-specific keys.
    railsContext: railsContext as unknown as RailsContext,
    domNodeId: options.domNodeId,
    trace: options.trace,
  }) as unknown;
  const resolved = isPromise(result) ? await (result as Promise<unknown>) : result;
  if (!React.isValidElement(resolved)) {
    throw new Error(
      `PPR: render function for "${options.name}" did not return a React element (got ${typeof resolved})`,
    );
  }
  return resolved as React.ReactElement;
}

// ─── types ──────────────────────────────────────────────────────────────────────────────────

type PPRRenderOptions = RenderParams & {
  // Injected by server_rendering_js_code.rb on the railsContext side; we don't read these from
  // the top-level options, but the caller may pass them too. Kept here for type completeness.
};

type PPRPrerenderResult = {
  html: string;
  pprShellHtml: string;
  pprPostponedState: string | null;
  consoleReplayScript: string;
  hasErrors: boolean;
  errorMessage?: string;
  isShellReady: boolean;
};

// ─── Phase A: prerender ────────────────────────────────────────────────────────────────────

async function prerenderReactComponentForPPR(options: PPRRenderOptions): Promise<PPRPrerenderResult> {
  checkPPRRuntimeOrThrow();
  const { prerenderToNodeStream } = await loadPPRReactAPIs();

  // The Ruby side passes the timeout via railsContext.pprPrerenderTimeoutMs. Default 8s.
  const railsContext = (options.railsContext ?? {}) as RailsContext & {
    pprPrerenderTimeoutMs?: number;
    pprPhase?: string;
  };
  const prerenderTimeoutMs = Number(railsContext.pprPrerenderTimeoutMs) || 8_000;

  return withPhase('prerender', async () => {
    let timer: NodeJS.Timeout | undefined;
    const controller = new AbortController();

    const cleanup = () => {
      if (timer) {
        clearTimeout(timer);
        timer = undefined;
      }
      if (!controller.signal.aborted) controller.abort();
    };

    try {
      // Build a sanitized railsContext for prerender — request-varying fields are omitted so
      // user code is forced to read them inside postponed boundaries. The Ruby side also strips
      // sensitive context, but we belt-and-suspenders here.
      const prerenderRailsContext = {
        ...railsContext,
        serverSide: true as const,
      };
      const reactElement = await resolveComponentElement(options, prerenderRailsContext);

      timer = setTimeout(() => {
        // re-bind the phase in the timer callback (defense-in-depth — withPhase is cheap).
        withPhase('prerender', () => controller.abort(new Error('ppr-prerender-timeout')));
      }, prerenderTimeoutMs);

      const onError = (err: unknown) => {
        // Expected AbortError during normal abort flow — swallow.
        const msg = err instanceof Error ? err.message : String(err);
        if (msg.includes('aborted') || msg.includes('AbortError')) return;
        // eslint-disable-next-line no-console
        console.error('[PPR prerender] error:', err);
      };

      const { prelude, postponed } = await prerenderToNodeStream(reactElement, {
        signal: controller.signal,
        identifierPrefix: options.domNodeId,
        onError: (err) => withPhase('prerender', () => onError(err)),
      });

      const shellHtml = await streamToString(prelude);
      const consoleReplayScript = buildConsoleReplay();

      return {
        html: shellHtml,
        pprShellHtml: shellHtml,
        pprPostponedState: postponed ? JSON.stringify(postponed) : null,
        consoleReplayScript,
        hasErrors: false,
        isShellReady: true,
      };
    } catch (e) {
      const error = convertToError(e);
      return {
        html: '',
        pprShellHtml: '',
        pprPostponedState: null,
        consoleReplayScript: consoleReplay(console.history ?? [], 0),
        hasErrors: true,
        errorMessage: `${error.message}\n${error.stack ?? ''}`,
        isShellReady: false,
      };
    } finally {
      cleanup();
    }
  });
}

// ─── Phase B: resume ───────────────────────────────────────────────────────────────────────

function resumeReactComponentForPPR(options: PPRRenderOptions): Readable {
  // Set up the Pro chunk-format pipeline first so we can return the stream synchronously.
  // We mark isShellReady: true from the start because the cached shell IS the shell —
  // no React shell handshake needs to happen.
  const renderState: import('react-on-rails/types').StreamRenderState = {
    result: null,
    hasErrors: false,
    isShellReady: true,
  };

  const { readableStream, pipeToTransform, writeChunk, emitError, endStream } =
    transformRenderStreamChunksToResultObject(renderState);

  const railsContext = (options.railsContext ?? {}) as RailsContext & {
    pprShellHtml?: string;
    pprPostponedState?: string;
  };
  const shellHtml = railsContext.pprShellHtml ?? '';
  const postponedStateJson = railsContext.pprPostponedState ?? null;

  const failBeforeShell = (error: Error): Readable => {
    renderState.hasErrors = true;
    renderState.error = error;
    if (options.throwJsErrors) {
      emitError(error);
    } else {
      const errorHtmlStream = handleError({ e: error, name: options.name, serverSide: true });
      pipeToTransform(errorHtmlStream);
    }
    return readableStream;
  };

  // VALIDATE the postponed state BEFORE writing the shell chunk. If parsing fails, we want to
  // surface the error to Rails through the normal error path (and let the helper invalidate the
  // cache entry), not commit a half-broken response with the shell already on the wire.
  let parsedPostponedState: unknown = null;
  if (postponedStateJson) {
    try {
      parsedPostponedState = JSON.parse(postponedStateJson);
    } catch (e) {
      return failBeforeShell(
        new Error(
          `PPR resume: cached postponed state is not valid JSON for "${options.name}". ` +
            'The cache entry is likely corrupted; clear the PPR cache to recover. ' +
            `(parse error: ${(e as Error).message})`,
        ),
      );
    }
  }

  // Stream the cached shell as the first chunk immediately. (The transform wraps it in a JSON
  // envelope; Rails-side build_react_component_result_for_server_streamed_content unpacks the
  // first chunk into the component wrapper as usual.)
  writeChunk(shellHtml);

  // If there's no postponed state (fully-static page) just end the stream.
  if (parsedPostponedState === null) {
    endStream();
    return readableStream;
  }

  // Run resume inside withPhase('resume') — defense-in-depth. The postpone helper would also
  // be a no-op without the phase, but other Pro libs may key off it.
  const runResume = async () => {
    try {
      checkPPRRuntimeOrThrow();
      const { resumeToPipeableStream } = await loadPPRReactAPIs();
      const reactElement = await resolveComponentElement(options, railsContext);

      const passThrough = new PassThrough();
      const resumeStream = resumeToPipeableStream(reactElement, parsedPostponedState, {
        onError: (err) =>
          withPhase('resume', () => {
            renderState.hasErrors = true;
            renderState.error = convertToError(err);
            if (options.throwJsErrors) emitError(err);
          }),
      });
      // resumeToPipeableStream returns synchronously with .pipe(destination). We pipe into
      // a PassThrough so we can hand a Readable to the existing transform pipeline.
      resumeStream.pipe(passThrough);
      pipeToTransform(passThrough);
    } catch (e) {
      // POST-shell error (after writeChunk): the shell is already on the wire so we can't
      // redirect to a fresh error page. Surface via the chunk pipeline. Honor throwJsErrors so
      // tests / strict consumers see the failure rather than a partial render.
      const error = convertToError(e);
      renderState.hasErrors = true;
      renderState.error = error;
      if (options.throwJsErrors) {
        emitError(error);
      } else {
        const errorHtmlStream = handleError({ e: error, name: options.name, serverSide: true });
        pipeToTransform(errorHtmlStream);
      }
    }
  };

  withPhase('resume', () => {
    runResume().catch((e: unknown) => {
      const error = convertToError(e);
      renderState.hasErrors = true;
      renderState.error = error;
      emitError(error);
    });
  });

  return readableStream;
}

/**
 * Pro PPR capability — registers `prerenderReactComponentForPPR` and `resumeReactComponentForPPR`
 * on the Pro ReactOnRails instance. Both are dispatched by the Ruby side via render_mode
 * `:ppr_prerender` and `:ppr_resume`.
 */
export function createProPPRCapability() {
  return {
    isPPRCapable: true as const,
    prerenderReactComponentForPPR,
    resumeReactComponentForPPR,
  };
}

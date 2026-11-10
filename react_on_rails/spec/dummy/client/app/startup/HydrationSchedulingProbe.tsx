import React, { useEffect, useState } from 'react';
import { excludeFromStrictMode } from '../strictModeSupport';

type HydrationSchedulingEvent = {
  event: 'hydrated' | 'unmounted';
  mode: string;
  testId: string;
};

declare global {
  interface Window {
    __HYDRATION_SCHEDULING_EVENTS__?: HydrationSchedulingEvent[];
  }
}

type HydrationSchedulingProbeProps = {
  label: string;
  mode: string;
  testId: string;
};

const hydrationSchedulingEventsKey = '__HYDRATION_SCHEDULING_EVENTS__';

const recordHydrationSchedulingEvent = (event: HydrationSchedulingEvent) => {
  window[hydrationSchedulingEventsKey] ||= [];
  window[hydrationSchedulingEventsKey].push(event);
};

function HydrationSchedulingProbe({ label, mode, testId }: HydrationSchedulingProbeProps) {
  const [hydrated, setHydrated] = useState(false);

  useEffect(() => {
    setHydrated(true);
    recordHydrationSchedulingEvent({ event: 'hydrated', mode, testId });

    return () => {
      recordHydrationSchedulingEvent({ event: 'unmounted', mode, testId });
    };
  }, [mode, testId]);

  return (
    <section data-testid={testId} data-hydrated={hydrated ? 'true' : 'false'}>
      <h2>{label}</h2>
      <p>{hydrated ? `${mode} hydrated` : `${mode} server rendered`}</p>
      <button type="button" disabled={!hydrated}>
        {hydrated ? 'Hydrated button' : 'Waiting for hydration'}
      </button>
    </section>
  );
}

// Specs count this probe's events, so they must match real mounts and unmounts. React 18 replays
// effects (mount, unmount, mount) under the dummy's StrictMode register wrapper, which would log a
// simulated unmount at page load. React 19 skips that replay because the wrapper component itself
// is not strict. Leaving the probe unwrapped keeps its counts the same on both. Refs #5266.
export default excludeFromStrictMode(HydrationSchedulingProbe);

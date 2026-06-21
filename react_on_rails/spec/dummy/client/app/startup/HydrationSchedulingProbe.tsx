import React, { useEffect, useState } from 'react';

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

export default function HydrationSchedulingProbe({ label, mode, testId }: HydrationSchedulingProbeProps) {
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

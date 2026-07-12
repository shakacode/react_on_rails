import React, { useEffect, useState, useCallback, memo } from 'react';

type HydrationEvent = {
  component: string;
  timestamp: number;
};

declare global {
  interface Window {
    __STREAMING_HYDRATION_EVENTS__?: HydrationEvent[];
  }
}

const recordHydrationEvent = (component: string) => {
  /* eslint-disable no-underscore-dangle -- double-underscore marks the test-only window global */
  window.__STREAMING_HYDRATION_EVENTS__ ||= [];
  window.__STREAMING_HYDRATION_EVENTS__.push({
    component,
    timestamp: Date.now(),
  });
  /* eslint-enable no-underscore-dangle */
};

type SectionProps = {
  name: string;
  testId: string;
  description: string;
  color: string;
};

const Section = memo(function Section({ name, testId, description, color }: SectionProps) {
  const [hydrated, setHydrated] = useState(false);
  const [clickCount, setClickCount] = useState(0);

  useEffect(() => {
    setHydrated(true);
    recordHydrationEvent(name);
  }, [name]);

  const handleClick = useCallback(() => {
    setClickCount((c) => c + 1);
  }, []);

  return (
    <section
      data-testid={testId}
      data-hydrated={hydrated ? 'true' : 'false'}
      style={{
        padding: '20px',
        margin: '10px 0',
        border: `2px solid ${color}`,
        borderRadius: '8px',
        backgroundColor: hydrated ? `${color}22` : '#f0f0f0',
      }}
    >
      <h2 style={{ color }}>{name}</h2>
      <p>{description}</p>
      <p>
        <strong>Status: </strong>
        <span data-testid={`${testId}-status`}>{hydrated ? 'Hydrated' : 'Server Rendered (waiting)'}</span>
      </p>
      <button type="button" onClick={handleClick} disabled={!hydrated} data-testid={`${testId}-button`}>
        {hydrated ? `Clicked ${clickCount} times` : 'Waiting for hydration...'}
      </button>
    </section>
  );
});

type StreamingHydrationDemoProps = {
  section: 'header' | 'hero' | 'main' | 'sidebar' | 'footer';
};

const sectionConfig: Record<string, Omit<SectionProps, 'testId'>> = {
  header: {
    name: 'Header Section',
    description: 'Navigation and branding. First to hydrate.',
    color: '#e91e63',
  },
  hero: {
    name: 'Hero Section',
    description: 'Above-the-fold content with call-to-action.',
    color: '#2196f3',
  },
  main: {
    name: 'Main Content',
    description: 'Primary page content. Core user experience.',
    color: '#4caf50',
  },
  sidebar: {
    name: 'Sidebar',
    description: 'Secondary navigation and widgets.',
    color: '#ff9800',
  },
  footer: {
    name: 'Footer Section',
    description: 'Links, copyright, and auxiliary information.',
    color: '#9c27b0',
  },
};

export default function StreamingHydrationDemo({ section }: StreamingHydrationDemoProps) {
  const config = sectionConfig[section];

  if (!config) {
    return <div>Unknown section: {section}</div>;
  }

  return <Section testId={`streaming-${section}`} {...config} />;
}

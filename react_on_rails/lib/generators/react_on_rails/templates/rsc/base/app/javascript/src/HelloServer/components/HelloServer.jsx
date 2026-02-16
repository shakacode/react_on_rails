// HelloServer - React Server Component demo
// This component demonstrates:
// 1) Async server-side data loading with Promise.all
// 2) Streaming HTML output
// 3) Client-side interactivity via a nested client component

import React from 'react';
import LikeButton from './LikeButton.client';

const wait = (milliseconds) => new Promise((resolve) => {
  setTimeout(resolve, milliseconds);
});

const loadHighlights = async () => {
  await wait(120);

  return [
    'Streams HTML from the server immediately',
    'Loads data directly in the component with async/await',
    'Composes with client components for interactivity',
  ];
};

const loadStats = async () => {
  await wait(80);

  return {
    celebrations: 7,
    renderedAt: new Date().toISOString(),
  };
};

const HelloServer = async ({ name = 'World', mission = 'Build fast pages with less client JavaScript' }) => {
  const [highlights, stats] = await Promise.all([loadHighlights(), loadStats()]);

  return (
    <div>
      <h3>Hello, {name}!</h3>
      <p>{mission}</p>

      <ul>
        {highlights.map((highlight) => (
          <li key={highlight}>{highlight}</li>
        ))}
      </ul>

      <p>
        Server rendered at:
        <strong> {stats.renderedAt}</strong>
      </p>

      <LikeButton initialCount={stats.celebrations} />
    </div>
  );
};

export default HelloServer;

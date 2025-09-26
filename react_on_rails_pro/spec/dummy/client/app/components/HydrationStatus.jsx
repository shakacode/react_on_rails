'use client';

import React, { useState, useEffect } from 'react';

const STATUS = {
  streamingServerRender: 'streamingServerRender',
  hydrated: 'hydrated',
  pageLoaded: 'pageLoaded',
};

const STATUS_MESSAGES = {
  [STATUS.streamingServerRender]: 'Streaming server render',
  [STATUS.hydrated]: 'Hydrated',
  [STATUS.pageLoaded]: 'Page loaded',
};

export default function HydrationStatus() {
  const [hydrationStatus, setHydrationStatus] = useState(STATUS.streamingServerRender);

  useEffect(() => {
    console.log("Hydrated (This message is logged on client only as useEffect isn't called on server)");
    setHydrationStatus(STATUS.hydrated);
    window.addEventListener('load', () => {
      console.log('Page loaded');
      setHydrationStatus(STATUS.pageLoaded);
    });
  }, []);

  return <div>HydrationStatus: {STATUS_MESSAGES[hydrationStatus]}</div>;
}

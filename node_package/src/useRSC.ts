// @ts-ignore
import React, { use, useEffect, useState } from 'react';
import { createFromFetch } from 'react-server-dom-webpack/client.browser';

export default function useRSC(componentName: string, props?: Record<string, unknown>): string | null {
  const [content, setContent] = useState(null);

  useEffect(() => {
    setContent(createFromFetch(fetch(
      '/rsc/' + encodeURIComponent(componentName) + '?props=' + encodeURIComponent(JSON.stringify(props))
    )));
  }, []);

  return content && use(content);
}

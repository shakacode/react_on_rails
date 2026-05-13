'use client';

import React from 'react';
import { hydrateRoot } from 'react-dom/client';
import LeakRepro from '../components/LeakRepro';

export default (props, _railsContext, domNodeId) => {
  const el = document.getElementById(domNodeId);
  hydrateRoot(el, <LeakRepro {...props} />);
};

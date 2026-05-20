'use client';

import React from 'react';
import wrapServerComponentRenderer from 'react-on-rails-pro/wrapServerComponentRenderer/client';

function CacheDemoPage() {
  return React.createElement('div');
}

export default wrapServerComponentRenderer(CacheDemoPage);

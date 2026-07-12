import React from 'react';
import { createRoot } from 'react-dom/client';
import marker from './message';

const root = createRoot(document.getElementById('root'));

function render(value) {
  root.render(React.createElement('p', { 'data-testid': 'marker' }, value));
}

render(marker);

if (import.meta.hot) {
  import.meta.hot.accept('./message', (next) => render(next.default));
}

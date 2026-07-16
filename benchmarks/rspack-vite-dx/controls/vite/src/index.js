// eslint-disable-next-line import/extensions
import marker from './message.js';

function render(value) {
  document.getElementById('root').textContent = value;
}

render(marker);

if (import.meta.hot) {
  import.meta.hot.accept('./message.js', (next) => render(next.default));
}

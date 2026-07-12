// eslint-disable-next-line import/extensions
import marker from './message.js';

function render(value) {
  document.getElementById('root').textContent = value;
}

render(marker);

if (module.hot) {
  module.hot.accept('./message.js', () => {
    // eslint-disable-next-line import/extensions
    import('./message.js').then((next) => render(next.default));
  });
}

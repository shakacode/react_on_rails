import marker from './message';

function render(value) {
  document.getElementById('root').textContent = value;
}

render(marker);

if (import.meta.hot) {
  import.meta.hot.accept('./message', (next) => render(next.default));
}

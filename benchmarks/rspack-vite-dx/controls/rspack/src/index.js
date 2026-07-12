import marker from './message';

function render(value) {
  document.getElementById('root').textContent = value;
}

render(marker);

if (module.hot) {
  module.hot.accept('./message', () => {
    import('./message').then((next) => render(next.default));
  });
}

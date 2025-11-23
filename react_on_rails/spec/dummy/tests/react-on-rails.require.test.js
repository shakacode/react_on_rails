const ReactOnRails = require('react-on-rails').default;

test('ReactOnRails', () => {
  expect(() => {
    ReactOnRails.register({});
  }).not.toThrow();
});

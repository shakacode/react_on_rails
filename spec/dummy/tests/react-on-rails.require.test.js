const { register } = require('react-on-rails');

test('ReactOnRails', () => {
  expect(() => {
    register({});
  }).not.toThrow();
});

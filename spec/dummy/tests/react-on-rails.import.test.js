import * as ReactOnRails from 'react-on-rails';

test('ReactOnRails', () => {
  expect(() => {
    ReactOnRails.register({});
  }).not.toThrow();
});
